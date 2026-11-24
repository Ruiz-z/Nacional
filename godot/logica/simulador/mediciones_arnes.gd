extends RefCounted

const Banco = preload("res://logica/simulador/banco_arnes.gd")
const PUNTOS := ["tp1", "tp2"]
const OPCIONES := {"0": "≈0 V", "5": "≈5 V", "otra": "Otra"}
const ERRORES_MEDICION := ["punto-de-medicion-incorrecto", "valor-fuera-de-rango", "paso-omitido"]
const INTERPRETACION := "lectura-mal-interpretada"
const MOTIVOS := {
	"punto-de-medicion-incorrecto": "Mide el punto que distingue la falla.",
	"valor-fuera-de-rango": "Revisa las lecturas reportadas y compáralas con el multímetro.",
	"paso-omitido": "Se omitió una medición antes de reparar.",
	INTERPRETACION: "Las lecturas reportadas no respaldan la causa elegida.",
}

# El lector recibe el estado de la práctica y devuelve tp1, tp2 y aviso.
# Otra fuente puede devolver una instantánea de los nodos del banco.
var fuente: String
var leer: Callable
var medidas := {}
var reportadas := {}
var diagnostico := ""
var error_diagnostico := ""
var punta_negra := ""
var pantalla := "—"
var aviso_puntas := ""


func _init(lector: Callable = leer_variante, nombre_fuente := "virtual") -> void:
	leer = lector
	fuente = nombre_fuente


static func leer_variante(estado: Dictionary) -> Dictionary:
	return Banco.calcular(estado.s1_abierto, estado.s2_abierto)


func tocar(punto: String) -> String:
	pantalla = "—"
	aviso_puntas = ""
	if punta_negra.is_empty():
		punta_negra = punto
		aviso_puntas = "Coloca la punta roja." if punto == "tp0" else "La punta negra va en TP0."
		return ""
	var negra := punta_negra
	punta_negra = ""
	if negra == "tp0":
		if punto == "tp0":
			pantalla = "0.0 V"
			return ""
		if punto in PUNTOS:
			return "medir_" + punto
	aviso_puntas = "Polaridad invertida. Empieza en TP0." if punto == "tp0" else "Empieza en TP0."
	return ""


func aplicar(id: String, estado: Dictionary, causa: String, lectura_previa: Dictionary = {}) -> Dictionary:
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
			if campos.size() != 3 or campos[1] not in PUNTOS or not OPCIONES.has(campos[2]):
				return {}
			reportadas[campos[1]] = campos[2]
			return {"punto_reportado": campos[1], "lectura-reportada": OPCIONES[campos[2]]}
		"diagnosticar":
			diagnostico = causa
			error_diagnostico = evaluar(estado)
			return {"causa_elegida": causa, "tipo_error": error_diagnostico}
		"reconectar":
			var error := evaluar(estado, lectura_previa)
			if medidas.is_empty() and (fuente != "banco" or reportadas.is_empty()):
				error = "paso-omitido"
			elif diagnostico.is_empty() and error.is_empty():
				error = "paso-omitido"
				return {"tipo_error": error, "motivo": "Se omitió el diagnóstico antes de reparar."}
			return {"tipo_error": "" if error == error_diagnostico else error}
	return {}


func evaluar(estado: Dictionary, lectura_previa: Dictionary = {}) -> String:
	var tensiones: Dictionary = leer.call(estado) if lectura_previa.is_empty() else lectura_previa
	var evidencia := reportadas if fuente == "banco" else medidas
	var alimentacion := Banco.coincide(tensiones.tp1, 0.0)
	var punto_falla := "tp1" if alimentacion else "tp2"
	if not evidencia.has(punto_falla):
		return "punto-de-medicion-incorrecto"
	for punto in PUNTOS:
		var opcion: String = reportadas.get(punto, "")
		if opcion not in ["0", "5"] or not evidencia.has(punto) \
				or (fuente != "banco" and not Banco.coincide(opcion.to_float(), medidas[punto])) \
				or not Banco.coincide(opcion.to_float(), tensiones[punto]):
			return "valor-fuera-de-rango"
	if not diagnostico.is_empty() and diagnostico != ("alimentacion" if alimentacion else "senal"):
		return INTERPRETACION
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
