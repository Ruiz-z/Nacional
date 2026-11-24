extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const RegistroSimulador = preload("res://logica/tablero/registro_simulador.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Indicadores = preload("res://logica/aprendizaje/indicadores.gd")

static func tecnico(base: String, alias: String, consultar: Callable = Acceso.consultar) -> Dictionary:
	var perfil: Variant = consultar.call(base, """
		SELECT tecnico.*, progreso.ruta, coalesce(progreso.microlecciones_hechas, 0) AS microlecciones_hechas
		FROM tecnico LEFT JOIN progreso ON progreso.tecnico = tecnico.id WHERE alias = ?;
	""", [alias])
	if perfil == null or perfil.is_empty():
		return {}
	var id := int(perfil[0].id)
	var intentos: Variant = Registro.leer(base, alias, consultar)
	var eventos: Variant = consultar.call(base, "SELECT * FROM evento WHERE tecnico = ? ORDER BY id;", [id])
	var brechas: Variant = consultar.call(base, "SELECT * FROM brecha WHERE tecnico = ? ORDER BY id;", [id])
	if intentos == null or eventos == null or brechas == null:
		return {}

	var competencias := Indicadores.calcular(intentos)
	var con_intentos := {}
	for intento in intentos:
		con_intentos[intento.competencia] = true
	for competencia in competencias:
		var datos: Dictionary = competencias[competencia]
		if not con_intentos.has(competencia):
			datos.dominio = "pendiente"
			datos.nivel = "pendiente"
			datos.confianza = "pendiente"
		var detalle := []
		var momentos := {"pre": 0, "post": 0, "retest": 0, "sin_momento": 0}
		for brecha in brechas:
			if brecha.competencia == competencia:
				detalle.append(brecha)
				var momento := momento_brecha(brecha, intentos)
				momentos[momento] += 1
		if not detalle.is_empty():
			datos.brechas = detalle.size()
		datos.brechas_por_momento = momentos
		datos.detalle_brechas = detalle

	var faltas := {"conteo": 0, "ultima": null}
	var tiempos := {}
	for evento in eventos:
		if evento.criticidad == "critica":
			sumar_falta(faltas, evento.reloj_sim)
		RegistroSimulador.leer_metadatos(evento)
		var tiempo: Variant = evento.get("tiempo_ms")
		if (tiempo is int or tiempo is float) and tiempo >= 0:
			var acciones: Dictionary = tiempos.get_or_add(evento.escenario, {})
			var medicion: Array = acciones.get_or_add(evento.accion, [0.0, 0])
			medicion[0] += tiempo
			medicion[1] += 1
	for acciones in tiempos.values():
		for accion in acciones:
			acciones[accion] = acciones[accion][0] / acciones[accion][1]
	if faltas.conteo == 0:
		for intento in intentos:
			if intento.tipo_error == "falta-critica":
				sumar_falta(faltas, intento.reloj_sim)
	var ruta: Variant = JSON.parse_string(perfil[0].ruta) if perfil[0].ruta != null else []
	return {"alias": alias, "demo": bool(perfil[0].demo), "competencias": competencias,
		"intentos": intentos, "eventos": eventos, "brechas": brechas, "faltas_criticas": faltas,
		"estado": "sin_sesiones" if intentos.is_empty() and eventos.is_empty() and brechas.is_empty() else "con_sesiones",
		"tiempos_por_escenario": tiempos, "retencion_simulada": true,
		"ruta": ruta if ruta is Array else [],
		"avance_ruta": {"completadas": int(perfil[0].microlecciones_hechas),
			"pendientes": ruta.size() if ruta is Array else 0}}


static func momento_brecha(brecha: Dictionary, intentos: Array) -> String:
	# El esquema solo permite asociar la brecha por competencia y fecha.
	var momentos := {}
	for intento in intentos:
		if intento.competencia == brecha.competencia and intento.reloj_sim == brecha.reloj_sim:
			if intento.momento != "practica":
				momentos[intento.momento] = true
	return momentos.keys()[0] if momentos.size() == 1 else "sin_momento"


static func sumar_falta(faltas: Dictionary, fecha: String) -> void:
	faltas.conteo += 1
	if faltas.ultima == null or fecha > faltas.ultima:
		faltas.ultima = fecha
