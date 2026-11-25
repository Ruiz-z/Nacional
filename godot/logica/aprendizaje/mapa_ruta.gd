extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")
const OTROS_ERRORES := {
	"falta-critica": "Falta crítica",
	"diagnostico-vs-accion": "Aplicación incorrecta del diagnóstico",
	"accion-insegura": "Acción insegura",
	"respuesta-incorrecta": "Respuesta incorrecta",
}


static func armar(motivos: Array, instantanea: Dictionary, historial: Array,
		ordenes_catalogo: Array, ordenes_ia: Dictionary, hoy: Dictionary) -> Array:
	var criticas := Ruta.pendientes_criticas(historial)
	var sesion := 0
	var conteos := {}
	for intento in historial:
		sesion = maxi(sesion, intento.get("sesion", 0))
		var registrado: Variant = intento.get("tipo_error")
		var tipo: String = registrado if registrado is String else ""
		if tipo.is_empty() and intento.get("resultado") == "incorrecto":
			tipo = "respuesta-incorrecta"
		if not tipo.is_empty():
			var propios: Dictionary = conteos.get_or_add(intento.competencia, {})
			propios[tipo] = propios.get(tipo, 0) + 1

	var catalogo := {}
	for orden in ordenes_catalogo:
		catalogo[orden.id] = orden

	var primeros := []
	var resto := []
	for tema in motivos:
		var competencia: String = tema.competencia
		var dominio: float = instantanea.get(competencia, {}).get("dominio", 0.0)
		var nombre: String = Banco.COMPETENCIAS.get(competencia, competencia)
		var estado := "Hoy" if hoy.has(competencia) else "Después"
		var critica := criticas.has(competencia)
		if critica:
			estado = "Primero"
		elif Ruta.aprobada(dominio, Ruta.critica_reciente(historial, competencia, sesion)):
			estado = "Hecho"

		var detalle: Dictionary = ordenes_ia.get(competencia, {})
		var propios: Dictionary = conteos.get(competencia, {})
		var destino := primeros if critica else resto
		destino.append({
			"competencia": competencia, "nombre": nombre, "dominio": roundi(dominio),
			"estado": estado, "errores": errores(propios),
			"ordenes": ordenes(catalogo, detalle.get("ordenes", []), nombre),
			"refuerzo": refuerzo(tema.get("refuerzo", ""), propios),
		})
	return primeros + resto


static func errores(conteo: Dictionary) -> Array:
	if conteo.is_empty():
		return [{"nombre": "Sin errores", "conteo": 0}]
	var ramas := []
	for tipo in conteo:
		var nombre: String = Ruta.NOMBRES_ERROR.get(tipo, OTROS_ERRORES.get(tipo, "Otro error registrado"))
		nombre = nombre.left(1).to_upper() + nombre.substr(1)
		ramas.append({"nombre": nombre, "conteo": conteo[tipo]})
	return ramas


static func refuerzo(texto: String, conteo: Dictionary) -> String:
	if not texto.is_empty():
		return texto
	var frecuencia := 0
	for tipo in conteo:
		if Ruta.REFUERZOS.has(tipo) and conteo[tipo] > frecuencia:
			frecuencia = conteo[tipo]
			texto = Ruta.REFUERZOS[tipo]
	return texto


static func ordenes(catalogo: Dictionary, sugeridas: Array, competencia: String) -> Array:
	var seleccion := []
	for id in sugeridas:
		if catalogo.has(id) and catalogo[id] not in seleccion:
			seleccion.append(catalogo[id])
			if seleccion.size() == 3:
				break
	if seleccion.is_empty():
		for orden in catalogo.values():
			if orden.get("competencia") == competencia:
				seleccion.append(orden)
				if seleccion.size() == 3:
					break
	return seleccion
