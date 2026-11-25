extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")
const MapaRuta = preload("res://logica/aprendizaje/mapa_ruta.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")
const Evidencia = preload("res://logica/tablero/evidencia.gd")
const Recomendacion = preload("res://logica/tablero/recomendacion.gd")

const TEMAS := ["Seguridad", "Eléctrico y batería", "Diagnóstico", "Electrónica"]
const ESTADOS := ["Con falta crítica", "Con alertas", "Sin alertas", "Sin completar"]
const MINIMO := 70


static func tecnico(perfil: Dictionary) -> Dictionary:
	var competencias: Dictionary = perfil.get("competencias", {})
	var dominio := []
	var comparacion := []
	var totales := {"dominio": [], "ganancia": [], "retencion": []}
	var lectura := "La línea marca el mínimo de 70 %."
	var peor := float(MINIMO)
	var retencion_no_calculable := false
	var ids: Array = Banco.COMPETENCIAS.keys()
	for i in ids.size():
		var dato: Dictionary = competencias.get(ids[i], {})
		for clave in totales:
			if numero(dato.get(clave)):
				totales[clave].append(dato[clave])
		var valor: Variant = porcentaje(dato.get("dominio"))
		if valor != null and valor < peor:
			peor = valor
			lectura = "%s está por debajo del mínimo de %d %%." % [TEMAS[i], MINIMO]
		dominio.append(fila(TEMAS[i], [valor], str(dato.get("nivel", "Sin evaluar")).capitalize().replace("Pendiente", "Sin evaluar")))
		var retencion_competencia: Variant = dato.get("retencion")
		retencion_no_calculable = retencion_no_calculable \
			or (retencion_competencia is String and retencion_competencia == "no calculable")
		var evaluaciones: Dictionary = dato.get("dominios_evaluaciones", {})
		comparacion.append(fila(TEMAS[i], [porcentaje(evaluaciones.get("pre")),
			porcentaje(evaluaciones.get("post")), porcentaje(evaluaciones.get("retest"))]))

	var serie := evolucion(perfil.get("intentos", []))
	var sesiones: bool = perfil.get("estado", "sin_sesiones") == "con_sesiones"
	var faltas: Dictionary = perfil.get("faltas_criticas", {})
	var retencion := promedio(totales.retencion, " %")
	if totales.retencion.is_empty() and retencion_no_calculable:
		retencion = "No calculable"
	return {"fichas": [
		["Dominio global", promedio(totales.dominio, " %")],
		["Ganancia indicativa", promedio(totales.ganancia, " pts")],
		["Retención simulada", retencion],
		["Faltas críticas", str(faltas.get("conteo", 0)) if sesiones else "Pendiente"]],
		"graficas": [
			grafica("barras", "Dominio por competencia", lectura, "Completa el diagnóstico para ver tu dominio.",
				["Dominio"], con_valores(dominio), {"unidad": " %", "maximo": 100, "minimo": MINIMO}),
			grafica("agrupada", "Dominio por evaluación", "Compara las evaluaciones de cada competencia.",
				"Completa el diagnóstico para iniciar la comparación.",
				["Pre", "Post", "Retest simulado"], con_valores(comparacion), {"unidad": " %", "maximo": 100}),
			grafica("linea", "Dominio por sesión", "Sigue los resultados de cada competencia en orden de sesión.",
				"Completa una sesión para ver tu historial.", serie.columnas, serie.filas, {"unidad": " %"}),
			errores([perfil], "Errores por tipo", "Completa una actividad para registrar tus resultados.")]}


static func evolucion(intentos: Array) -> Dictionary:
	var ids: Array = Banco.COMPETENCIAS.keys().slice(0, 4)
	var sesiones := {}
	for intento in intentos:
		if intento.get("formato") == "detalle-escenario" or not ids.has(intento.get("competencia")):
			continue
		var id: String = intento.get("sesion_id", "")
		var clave: Variant = id if not id.is_empty() else [intento.reloj_sim, intento.momento]
		sesiones.get_or_add(clave, []).append(intento)
	var filas := []
	for grupo in sesiones.values():
		var valores := [null, null, null, null]
		var fecha := ""
		var momento: String = grupo[0].momento
		for punto in Vistas.sesiones(grupo):
			valores[ids.find(punto.competencia)] = porcentaje(punto.dominio)
			if fecha.is_empty() or punto.fecha < fecha:
				fecha = punto.fecha
		filas.append(fila(fecha, valores,
			"%s · %s" % [fecha.replace("T", " ").trim_suffix("Z"),
				{"pre": "Pre", "post": "Post", "retest": "Retest simulado", "practica": "Práctica"}.get(momento, momento)]))
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.nombre < b.nombre)
	for i in filas.size():
		filas[i].nombre = "Sesión %d" % (i + 1)
	return {"columnas": TEMAS, "filas": filas}


static func equipo(perfiles: Array) -> Dictionary:
	var ordenados := perfiles.duplicate()
	ordenados.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.recomendacion.prioridad != b.recomendacion.prioridad:
			return a.recomendacion.prioridad < b.recomendacion.prioridad
		return a.alias.naturalnocasecmp_to(b.alias) < 0)
	var filas := []
	var conteos := [0, 0, 0, 0]
	for perfil in ordenados:
		var valores := []
		var competencias: Dictionary = perfil.get("competencias", {})
		for id in Banco.COMPETENCIAS:
			valores.append(porcentaje(competencias.get(id, {}).get("dominio")))
		var estado: String = perfil.recomendacion.estado
		conteos[ESTADOS.find(estado)] += 1
		filas.append(fila(perfil.alias, valores, estado))
	var vacio := "Agrega técnicos para consultar el equipo."
	var con_dominio := not con_valores(filas).is_empty()
	return {"fichas": [["Técnicos", str(perfiles.size())], ["Con falta crítica", str(conteos[0])],
		["Con alertas", str(conteos[1])], ["Sin completar", str(conteos[3])]],
		"graficas": [
			grafica("mapa", "Dominio del equipo por competencia", "Los técnicos que requieren atención aparecen primero.",
				vacio if filas.is_empty() else "El equipo necesita completar el diagnóstico para mostrar su dominio.",
				TEMAS, filas if con_dominio else [], {"unidad": " %"}),
			grafica("apilada", "Estados del equipo", "Cada técnico cuenta una vez según su recomendación actual.",
				vacio, ESTADOS, [fila("Equipo", conteos)] if not filas.is_empty() else [],
				{"colores": ["#d03b3b", "#fab219", "#0ca30c", "#62767b"]}),
			errores(perfiles, "Errores del equipo por tipo", "Los errores aparecen cuando el equipo registra actividad.")]}


static func admin(resumen: Dictionary) -> Dictionary:
	var actividad: Array = resumen.tecnicos.duplicate()
	actividad.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.intentos != b.intentos:
			return a.intentos > b.intentos
		return a.alias.naturalnocasecmp_to(b.alias) < 0)
	var filas := []
	for tecnico in actividad:
		var fecha: String = tecnico.ultima
		filas.append(fila(tecnico.alias, [tecnico.intentos],
			"Sin actividad" if fecha.is_empty() else fecha.replace("T", " ").trim_suffix("Z")))
	var cuentas: Dictionary = resumen.cuentas
	var total: int = maxi(0, resumen.preguntas)
	var pendientes: int = clampi(resumen.pendientes_revision, 0, total)
	const VACIO := "Crea cuentas en Administración para consultar la actividad."
	return {"fichas": [
		["Respaldo", "Guardado · " + resumen.respaldo.fecha if resumen.respaldo.existe else "Sin respaldo"],
		["Servicio de IA", "Configurado" if resumen.foundry else "Sin configurar"]],
		"graficas": [
			grafica("barras", "Intentos por técnico", "Consulta cuántos intentos registró cada técnico y cuándo fue el último.",
				VACIO, ["Intentos"], filas, {"detalle": "Última actividad"}),
			grafica("apilada", "Cuentas por rol", "La barra muestra cómo se reparten las cuentas del taller.",
				VACIO, ["Técnicos", "Jefes directos", "Administradores"],
				[fila("Cuentas", [cuentas.tecnico, cuentas.jefe, cuentas.admin])] if cuentas.tecnico + cuentas.jefe + cuentas.admin > 0 else []),
			grafica("medidor", "Revisión de preguntas", "%d de %d preguntas revisadas por Volvo." % [total - pendientes, total],
				"Carga preguntas en el banco para consultar su revisión.", ["Revisadas", "Pendientes"],
				[fila("Preguntas", [total - pendientes, pendientes])] if total > 0 else [])]}


# «falta-critica» -> «Falta crítica»: con las tildes de las listas del proyecto y solo la primera letra en mayúscula.
static func nombre_error(tipo: String) -> String:
	var texto: String = Ruta.NOMBRES_ERROR.get(tipo, MapaRuta.OTROS_ERRORES.get(tipo, tipo.replace("-", " ")))
	return texto.left(1).to_upper() + texto.substr(1)


static func errores(perfiles: Array, titulo: String, vacio: String) -> Dictionary:
	var conteos := {}
	var hay_intentos := false
	for perfil in perfiles:
		for intento in perfil.get("intentos", []):
			var tipo: Variant = intento.get("tipo_error")
			var oportunidad := Evidencia.es_oportunidad(intento)
			hay_intentos = hay_intentos or oportunidad
			var nombre := ""
			if tipo is String and not tipo.is_empty():
				nombre = nombre_error(tipo)
			elif oportunidad and intento.get("resultado") == "incorrecto":
				nombre = "Sin clasificar"
			if not nombre.is_empty():
				conteos[nombre] = conteos.get(nombre, 0) + 1
	var filas := []
	for tipo in conteos:
		filas.append(fila(tipo, [conteos[tipo]]))
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.valores[0] != b.valores[0]:
			return a.valores[0] > b.valores[0]
		return a.nombre.naturalnocasecmp_to(b.nombre) < 0)
	var lectura := "" if filas.is_empty() else "%s es el error más registrado." % filas[0].nombre
	return grafica("barras", titulo, lectura, "No hay errores registrados." if hay_intentos else vacio,
		["Errores"], filas)


static func fila(nombre: String, valores: Array, detalle: String = "") -> Dictionary:
	return {"nombre": nombre, "valores": valores, "detalle": detalle}


static func grafica(tipo: String, titulo: String, lectura: String, vacio: String,
		columnas: Array, filas: Array, opciones: Dictionary = {}) -> Dictionary:
	return {"tipo": tipo, "titulo": titulo, "lectura": lectura, "vacio": vacio,
		"columnas": columnas, "filas": filas}.merged(opciones)


static func con_valores(filas: Array) -> Array:
	return filas if filas.any(func(dato: Dictionary) -> bool:
		return dato.valores.any(func(valor: Variant) -> bool: return valor != null)) else []


static func numero(valor: Variant) -> bool:
	return (valor is float or valor is int) and is_finite(float(valor))


static func porcentaje(valor: Variant) -> Variant:
	return clampf(float(valor), 0, 100) if numero(valor) else null


static func promedio(valores: Array, unidad: String) -> String:
	if valores.is_empty():
		return "Pendiente"
	var total := 0.0
	for valor in valores:
		total += float(valor)
	return "%.1f%s" % [total / valores.size(), unidad]
