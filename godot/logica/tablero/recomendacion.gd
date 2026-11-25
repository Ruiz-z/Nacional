extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Evidencia = preload("res://logica/tablero/evidencia.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")
const PIE := "Es una recomendación. La decisión de avance es del jefe directo."
const ESTADOS := ["Con falta crítica", "Con alertas", "Sin completar", "Sin alertas"]


static func calcular(perfil: Dictionary) -> Dictionary:
	var intentos: Array = perfil.get("intentos", []).filter(Evidencia.es_oportunidad)
	var faltas := faltas_registradas(perfil)
	var pendientes := Ruta.pendientes_criticas(intentos)
	var recientes := criticas_recientes(intentos, faltas)
	var seguridad: Array[String] = []
	var retomar: Array[String] = []
	var explicadas := {}
	for falta in faltas:
		var id: String = falta.competencia
		if explicadas.has(id):
			continue
		var pendiente: bool = pendientes.has(id)
		if not falta.en_intento:
			pendiente = not intentos.any(func(intento: Dictionary) -> bool:
				return intento.competencia == id and intento.reloj_sim > falta.fecha \
					and (intento.get("resultado") == "correcto" or intento.get("valor") == 100))
		if pendiente:
			explicadas[id] = true
			var nombre: String = Banco.COMPETENCIAS.get(id, "Seguridad")
			seguridad.append("%s · Falta crítica del %s. El historial no registra un acierto posterior." % [nombre, falta.fecha])
	for id in recientes:
		retomar.append("%s · Falta crítica en las últimas tres sesiones." % Banco.COMPETENCIAS.get(id, "Seguridad"))
	if not seguridad.is_empty():
		return salida(0, "Revisar seguridad antes de asignar trabajo sin supervisión", seguridad, faltas)

	var competencias: Dictionary = perfil.get("competencias", {})
	var evaluadas: Array[String] = []
	var sin_datos: Array[String] = []
	var refuerzos: Array[String] = []
	for id in Banco.COMPETENCIAS:
		var datos: Dictionary = competencias.get(id, {})
		var dominio: Variant = datos.get("dominio")
		var nombre: String = Banco.COMPETENCIAS[id]
		if not dominio is float and not dominio is int:
			sin_datos.append(nombre)
			continue
		var resumen := "%s · %s (%.1f %%)" % [nombre, datos.nivel, dominio]
		evaluadas.append(resumen)
		if not Ruta.aprobada(dominio, false):
			var errores: Dictionary = datos.get("errores_recurrentes", {})
			if errores.is_empty():
				retomar.append(resumen + ". Se requiere un mínimo de 70 %.")
				continue
			var tipos: Array = errores.keys()
			tipos.sort()
			var tipo: String = tipos.reduce(func(a: String, b: String) -> String:
				return a if errores[a] >= errores[b] else b)
			refuerzos.append("Reforzar %s: %s" % [nombre, nombre_error(tipo)])
			retomar.append("%s · %s (%d veces)" % [resumen, nombre_error(tipo).capitalize(), errores[tipo]])

	if not sin_datos.is_empty():
		var mensaje := "Completa las competencias pendientes" if refuerzos.is_empty() else refuerzos[0]
		retomar.append("Sin resultados de dominio · %s" % ", ".join(sin_datos))
		return salida(2 if refuerzos.is_empty() and retomar.size() == 1 else 1, mensaje, retomar, faltas)
	if not retomar.is_empty():
		return salida(1, "Revisa las competencias pendientes" if refuerzos.is_empty() else refuerzos[0], retomar, faltas)
	evaluadas.append("Sin faltas críticas pendientes ni en las últimas tres sesiones.")
	return salida(3, "Sin alertas: puede avanzar a práctica supervisada", evaluadas, faltas)


static func salida(prioridad: int, mensaje: String, evidencias: Array[String], faltas: Array) -> Dictionary:
	return {"prioridad": prioridad, "estado": ESTADOS[prioridad], "mensaje": mensaje, "pie": PIE,
		"evidencias": evidencias, "faltas": faltas}


static func criticas_recientes(intentos: Array, faltas: Array) -> Dictionary:
	var sesiones := {}
	var recientes := {}
	var desde := ""
	for i in range(intentos.size() - 1, -1, -1):
		var intento: Dictionary = intentos[i]
		var sesion: String = intento.get("sesion_id", "")
		var clave: Variant = sesion if not sesion.is_empty() else [intento.reloj_sim, intento.get("momento", "")]
		if not sesiones.has(clave) and sesiones.size() == 3:
			continue
		sesiones[clave] = true
		if desde.is_empty() or intento.reloj_sim < desde:
			desde = intento.reloj_sim
		if intento.get("tipo_error") == "falta-critica":
			recientes[intento.competencia] = true
	for falta in faltas:
		if not falta.en_intento and (sesiones.size() < 3 or falta.fecha >= desde):
			recientes[falta.competencia] = true
	return recientes


static func faltas_registradas(perfil: Dictionary) -> Array[Dictionary]:
	var faltas: Array[Dictionary] = []
	var de_evento := {}
	var competencias_por_accion: Dictionary = perfil.get("competencias_por_accion", {})
	for evento in perfil.get("eventos", []):
		if evento.get("criticidad") != "critica":
			continue
		var acciones: Dictionary = competencias_por_accion.get(evento.escenario, {})
		var registro := {"competencia": acciones.get(evento.accion, ""), "fecha": evento.reloj_sim,
			"en_intento": false}
		faltas.append(registro)
		de_evento.get_or_add([evento.escenario, evento.reloj_sim], []).append(registro)
	for intento in perfil.get("intentos", []):
		if intento.get("tipo_error") != "falta-critica":
			continue
		var coinciden: Array = de_evento.get([Evidencia.caso(intento), intento.reloj_sim], [])
		var emparejada := false
		for evento in coinciden:
			if not evento.en_intento and evento.competencia in ["", intento.competencia]:
				emparejada = true
				evento.merge({"competencia": intento.competencia, "en_intento": true}, true)
				break
		if not emparejada:
			faltas.append({"competencia": intento.competencia, "fecha": intento.reloj_sim, "en_intento": true})
	faltas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.fecha > b.fecha)
	return faltas


static func nombre_error(tipo: String) -> String:
	return Ruta.NOMBRES_ERROR.get(tipo, tipo.replace("-", " "))
