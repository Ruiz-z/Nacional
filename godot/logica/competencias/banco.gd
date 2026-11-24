extends RefCounted

const RutasContenido = preload("../rutas_contenido.gd")

const COMPETENCIAS := {
	"seguridad-alto-voltaje": "Seguridad de alto voltaje",
	"sistema-electrico-bateria": "Sistema eléctrico y batería",
	"diagnostico-fallas": "Diagnóstico de fallas",
	"electronica-conectividad": "Electrónica y conectividad",
}
const FORMATOS := ["opcion-multiple", "caso-diagnostico", "accion-panel"]
const DIFICULTADES := ["facil", "media", "dificil"]
const CRITICIDADES := ["normal", "leve", "critica"]
const TIPOS_ERROR := [
	"causa-equivocada", "paso-omitido", "orden-incorrecto", "accion-insegura",
	"paso-innecesario", "valor-fuera-de-rango",
	"punto-de-medicion-incorrecto", "lectura-mal-interpretada",
]
const FUENTE_MUESTRA := "[MUESTRA] valor de ejemplo, sin fuente oficial"
const FUENTE_OFICIAL := "material-oficial"
const FUENTES_PERMITIDAS := [
	"Volvo Buses", "NFPA 70E", "NOM-029-STPS", "NOM-001-SEDE", "ISO 6469", FUENTE_OFICIAL,
]


static func cargar(ruta: String = "banco.json") -> Dictionary:
	ruta = RutasContenido.resolver(ruta)
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return {"items": [], "avisos": [], "errores": ["%s: no se pudo abrir el banco." % ruta]}
	return validar_texto(archivo.get_as_text(), ruta)


static func validar_texto(texto: String, ruta: String) -> Dictionary:
	var resultado := {"items": [], "avisos": [], "errores": []}
	var json := JSON.new()
	if json.parse(texto) != OK:
		resultado.errores.append("%s: JSON inválido en línea %d: %s" %
			[ruta, json.get_error_line() + 1, json.get_error_message()])
		return resultado

	var datos: Variant = json.data
	if not datos is Dictionary or not datos.get("items") is Array:
		resultado.errores.append("%s: se esperaba un banco con un arreglo items." % ruta)
		return resultado

	var cantidades := {}
	for item in datos.items:
		if item is Dictionary and texto_presente(item.get("id")):
			cantidades[item.id] = cantidades.get(item.id, 0) + 1

	var duplicados_reportados := {}
	var preguntas_por_competencia := {}
	for indice in range(datos.items.size()):
		var item: Variant = datos.items[indice]
		var etiqueta := "items[%d]" % indice
		if not item is Dictionary or not texto_presente(item.get("id")):
			resultado.errores.append("%s: %s: falta un id válido." % [ruta, etiqueta])
			continue
		if cantidades[item.id] > 1:
			if not duplicados_reportados.has(item.id):
				resultado.errores.append("%s: %s: id duplicado." % [ruta, item.id])
				duplicados_reportados[item.id] = true
			continue

		var motivo := validar_item(item)
		if motivo.is_empty():
			resultado.items.append(item)
			if item.formato == "opcion-multiple":
				preguntas_por_competencia[item.competencia] = preguntas_por_competencia.get(
					item.competencia, 0) + 1
		else:
			resultado.errores.append("%s: %s: %s" % [ruta, item.id, motivo])
	for competencia in COMPETENCIAS:
		var cantidad: int = preguntas_por_competencia.get(competencia, 0)
		if cantidad < 8:
			resultado.avisos.append("%s: %s tiene %d de las 8 preguntas requeridas." %
				[ruta, competencia, cantidad])
	return resultado


static func consultar(banco_validado: Dictionary, competencia: String, dificultad: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in banco_validado.items:
		if item.competencia == competencia and item.dificultad == dificultad:
			items.append(item.duplicate(true))
	return items


static func validar_item(item: Dictionary) -> String:
	if not COMPETENCIAS.has(item.get("competencia")):
		return "competencia inválida."
	if item.get("formato") not in FORMATOS:
		return "formato inválido."
	if item.get("dificultad") not in DIFICULTADES:
		return "dificultad inválida."
	if item.get("criticidad") not in CRITICIDADES:
		return "criticidad inválida."
	if not item.get("muestra") is bool:
		return "muestra debe ser un booleano."
	if not texto_presente(item.get("version")):
		return "falta una versión válida en version."
	var error_fuente := validar_fuente(item)
	if not error_fuente.is_empty():
		return error_fuente
	match item.formato:
		"opcion-multiple":
			return validar_pregunta(item)
		"caso-diagnostico":
			return validar_caso(item)
		"accion-panel":
			return validar_panel(item)
	return ""


static func validar_fuente(item: Dictionary) -> String:
	var fuente: Variant = item.get("fuente")
	if fuente is String and fuente == FUENTE_MUESTRA:
		if not item.muestra or item.competencia == "seguridad-alto-voltaje":
			return "la fuente [MUESTRA] exige muestra=true y se excluye de seguridad."
		return ""
	if not fuente is Dictionary or fuente.get("origen") not in FUENTES_PERMITIDAS:
		return "fuente ausente o fuera de la lista permitida."
	if not texto_presente(fuente.get("titulo")):
		return "la fuente debe indicar su título."
	if not texto_presente(fuente.get("seccion")) and not texto_presente(fuente.get("pagina")):
		return "la fuente debe indicar su sección o página."
	if not texto_presente(fuente.get("url")) and not texto_presente(fuente.get("referencia")):
		return "la fuente debe indicar su URL o referencia."
	if fuente.origen != FUENTE_OFICIAL and not item.muestra:
		return "la fuente no es material oficial y exige muestra=true."
	return ""


static func texto_presente(valor: Variant) -> bool:
	return valor is String and not valor.strip_edges().is_empty()


static func validar_pregunta(item: Dictionary) -> String:
	if not texto_presente(item.get("pregunta")):
		return "falta la pregunta."
	var opciones: Variant = item.get("opciones")
	if not opciones is Array or opciones.size() < 2:
		return "se requieren al menos dos opciones."
	for opcion in opciones:
		if not texto_presente(opcion):
			return "cada opción debe tener texto."
	var correcta: Variant = item.get("correcta")
	if not (correcta is float or correcta is int) or not is_finite(correcta) \
			or floor(correcta) != correcta or correcta < 0 or correcta >= opciones.size():
		return "correcta debe ser el índice de una opción."
	return ""


static func validar_caso(item: Dictionary) -> String:
	if item.competencia != "diagnostico-fallas":
		return "caso-diagnostico requiere la competencia diagnostico-fallas."
	for campo in ["codigo_falla", "causa_correcta"]:
		if not texto_presente(item.get(campo)):
			return "falta %s." % campo
	var sintomas: Variant = item.get("sintomas")
	if not sintomas is Array or sintomas.is_empty():
		return "faltan síntomas."
	for sintoma in sintomas:
		if not texto_presente(sintoma):
			return "cada síntoma debe tener texto."

	var pasos: Variant = item.get("pasos")
	if not pasos is Array or pasos.is_empty():
		return "faltan pasos."
	var ids := {}
	for paso in pasos:
		if not paso is Dictionary or not texto_presente(paso.get("id")) or ids.has(paso.id):
			return "cada paso debe tener un id único."
		if not texto_presente(paso.get("accion")) or not texto_presente(paso.get("resultado")):
			return "el paso %s debe indicar acción y resultado." % paso.id
		if paso.get("tipo_error") not in TIPOS_ERROR:
			return "tipo_error inválido en el paso %s." % paso.id
		ids[paso.id] = true

	var ruta_ideal: Variant = item.get("ruta_ideal")
	if not ruta_ideal is Array or ruta_ideal.is_empty():
		return "falta la ruta_ideal."
	for id in ruta_ideal:
		if not ids.has(id):
			return "la ruta_ideal contiene un paso desconocido: %s." % str(id)
	return ""


static func validar_panel(item: Dictionary) -> String:
	if item.competencia != "seguridad-alto-voltaje":
		return "accion-panel requiere la competencia seguridad-alto-voltaje."
	if not texto_presente(item.get("instruccion")):
		return "falta la instrucción de panel."
	var secuencia: Variant = item.get("secuencia_esperada")
	if not secuencia is Array or secuencia.is_empty():
		return "falta la secuencia_esperada."
	for evento in secuencia:
		if not evento is Dictionary or not texto_presente(evento.get("ctrl")):
			return "cada evento esperado debe indicar ctrl."
		var valor: Variant = evento.get("valor")
		if not (valor is int or valor is float) or not is_finite(valor):
			return "cada evento esperado debe indicar un valor numérico."
	return ""
