extends RefCounted

const Banco = preload("res://logica/simulador/banco_arnes.gd")
const PUNTOS := ["tp1", "tp2"]
const AVISO_NEGRA := "La punta negra va en TP0."
const INDICIOS := ["tp1_medido", "tp2_medido", "tp1_reportado", "tp2_reportado"]
# La clave "5" significa "nivel alto" y conserva su id aunque el banco sea de 3.3 V.
const CLAVES_OPCION := ["0", "5", "otra"]
const ERRORES_MEDICION := ["punto-de-medicion-incorrecto", "valor-fuera-de-rango", "paso-omitido"]
const INTERPRETACION := "lectura-mal-interpretada"
const MOTIVOS := {
	"punto-de-medicion-incorrecto": "Mediste en otro punto. Revisa TP1 y TP2 con la punta negra en TP0.",
	"valor-fuera-de-rango": "La lectura que anotaste no coincide. Compárala con el multímetro.",
	"paso-omitido": "Mide TP1 y TP2 y guarda ambas lecturas antes de reparar.",
	INTERPRETACION: "La causa elegida no coincide con tus lecturas. Compáralas antes de elegir otra causa.",
}

# El lector recibe el estado de la práctica y devuelve tp1, tp2 y aviso.
# Otra fuente puede devolver una instantánea de los nodos del banco.
var fuente: String
var leer: Callable
var medidas := {}
var reportadas := {}
var punta_negra := ""
var punta_roja := ""
var pantalla := "—"
var aviso_puntas := ""


func _init(lector: Callable = leer_variante, nombre_fuente := "virtual") -> void:
	leer = lector
	fuente = nombre_fuente


static func opciones() -> Dictionary:
	return {"0": "≈0 V", "5": Banco.etiqueta_alto(), "otra": "Otra"}


# Tensión que representa una opción de lectura ("0" o "5").
static func valor_opcion(opcion: String) -> float:
	return Banco.nominal_alto if opcion == "5" else 0.0


static func leer_variante(estado: Dictionary) -> Dictionary:
	return Banco.calcular(estado.s1_abierto, estado.s2_abierto)


static func indicio_de_accion(id: String) -> String:
	var campos := id.split("_")
	match campos[0]:
		"medir", "reportar":
			if campos.size() >= 2 and campos[1] in PUNTOS:
				return campos[1] + ("_medido" if campos[0] == "medir" else "_reportado")
	return ""


func indicios() -> Dictionary:
	var evidencia := reportadas if fuente == "banco" else medidas
	return {"tp1_medido": evidencia.has("tp1"), "tp2_medido": evidencia.has("tp2"),
		"tp1_reportado": reportadas.has("tp1"), "tp2_reportado": reportadas.has("tp2")}


func puntas() -> Array[String]:
	return [punta_negra, punta_roja]


func reiniciar_puntas() -> void:
	punta_negra = ""
	punta_roja = ""
	pantalla = "—"
	aviso_puntas = ""


static func texto_apuntado(negra: String, roja: String, punto: String) -> String:
	if roja == "tp0":
		return AVISO_NEGRA
	var borne := punto.to_upper()
	if negra.is_empty():
		return "Poner la punta negra aquí (TP0)" if punto == "tp0" else AVISO_NEGRA
	if punto == "tp0":
		return "La punta negra ya está aquí (TP0)"
	if punto == roja:
		return "La punta roja ya está aquí (%s)" % borne
	if roja.is_empty():
		return "Poner la punta roja aquí (%s)" % borne
	return "Mover la punta roja aquí (%s)" % borne


func tocar(punto: String) -> String:
	if punto.is_empty():
		reiniciar_puntas()
		return ""
	aviso_puntas = ""
	if punta_roja == "tp0":
		reiniciar_puntas()
		aviso_puntas = AVISO_NEGRA
	elif punta_negra.is_empty():
		if punto == "tp0":
			punta_negra = punto
		else:
			aviso_puntas = AVISO_NEGRA
	elif punto in PUNTOS and punto != punta_roja:
		punta_roja = punto
		return "medir_" + punto
	return ""


func aplicar(id: String, estado: Dictionary, lectura_previa: Dictionary = {}) -> Dictionary:
	var campos := id.split("_")
	match campos[0]:
		"medir":
			if campos.size() != 2 or campos[1] not in PUNTOS:
				return {}
			var punto := campos[1]
			var lectura := snappedf(leer.call(estado)[punto], 0.1)
			medidas[punto] = lectura
			pantalla = "%.1f V" % lectura
			return {"punto_medido": punto, "lectura_mostrada": lectura}
		"reportar":
			if campos.size() != 3 or campos[1] not in PUNTOS or campos[2] not in CLAVES_OPCION:
				return {}
			reportadas[campos[1]] = campos[2]
			return {"punto_reportado": campos[1], "lectura-reportada": opciones()[campos[2]]}
		"reconectar":
			return {"tipo_error": evaluar(estado, lectura_previa)}
	return {}


static func causa_de_lectura(tensiones: Dictionary) -> String:
	return "alimentacion" if Banco.coincide(tensiones.tp1, 0.0) else "senal"


func evaluar(estado: Dictionary, lectura_previa: Dictionary = {}) -> String:
	var evidencia := reportadas if fuente == "banco" else medidas
	if not evidencia.has_all(PUNTOS) or not reportadas.has_all(PUNTOS):
		return "paso-omitido"
	var tensiones: Dictionary = leer.call(estado) if lectura_previa.is_empty() else lectura_previa
	for punto in PUNTOS:
		var opcion: String = reportadas[punto]
		if opcion not in ["0", "5"] \
				or (fuente != "banco" and not Banco.coincide(valor_opcion(opcion), medidas[punto])) \
				or not Banco.coincide(valor_opcion(opcion), tensiones[punto]):
			return "valor-fuera-de-rango"
	return ""


static func contar_errores(registros: Array) -> Dictionary:
	var conteo := {"medicion": 0, "interpretacion": 0}
	for registro in registros:
		var tipo: Variant = registro.get("tipo_error")
		if tipo in ERRORES_MEDICION:
			conteo.medicion += 1
		elif tipo == INTERPRETACION:
			conteo.interpretacion += 1
	return conteo
