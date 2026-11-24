extends RefCounted

const VERSION := 1
const REBOTE_MS := 50
const CONTROLES := ["bloqueo", "etiquetado", "torque", "confirmar", "cancelar"]

var _secuencias := {"panel": {}, "virtual": {}}
var _tiempos := {"panel": {}, "virtual": {}}
var _errores: Array[Dictionary] = []


func recibir(linea: String, fuente: String = "panel") -> Dictionary:
	var json := JSON.new()
	if not _secuencias.has(fuente):
		return rechazar("Fuente desconocida", linea, fuente)
	if json.parse(linea) != OK or not json.data is Dictionary:
		return rechazar("JSON inválido", linea, fuente)
	var datos: Dictionary = json.data
	if not entero(datos.get("v")) or datos.v != VERSION:
		return rechazar("Versión desconocida", linea, fuente)
	if datos.get("ctrl") == "hb":
		return {"ctrl": "hb", "fuente_entrada": fuente}
	if datos.get("ctrl") not in CONTROLES:
		return rechazar("Control desconocido", linea, fuente)
	if not entero(datos.get("n")) or not entero(datos.get("t")):
		return rechazar("Secuencia o tiempo inválido", linea, fuente)
	var valor: Variant = datos.get("valor")
	if not numero(valor) or (datos.ctrl != "torque" and valor != 0 and valor != 1):
		return rechazar("Valor inválido", linea, fuente)
	if datos.ctrl == "torque" and (valor < 0 or valor > 100):
		return rechazar("Torque fuera de 0–100", linea, fuente)
	var secuencia := int(datos.n)
	if _secuencias[fuente].has(secuencia):
		return rechazar("Secuencia repetida", linea, fuente)
	_secuencias[fuente][secuencia] = true
	var tiempos: Dictionary = _tiempos[fuente]
	var tiempo := int(datos.t)
	if tiempos.has(datos.ctrl) and tiempo - tiempos[datos.ctrl] < REBOTE_MS:
		return {}
	tiempos[datos.ctrl] = tiempo
	return {"ctrl": datos.ctrl, "valor": valor, "n": secuencia, "t": tiempo,
		"fuente_entrada": fuente}


func reiniciar_panel() -> void:
	reiniciar_fuente("panel")


func reiniciar_fuente(fuente: String) -> void:
	_secuencias[fuente].clear()
	_tiempos[fuente].clear()


func errores() -> Array[Dictionary]:
	return _errores.duplicate(true)


func rechazar(motivo: String, linea: String, fuente: String) -> Dictionary:
	_errores.append({"motivo": motivo, "linea": linea, "fuente_entrada": fuente})
	return {}


static func numero(valor: Variant) -> bool:
	return (valor is int or valor is float) and is_finite(valor)


static func entero(valor: Variant) -> bool:
	# JSON usa números de doble precisión.
	return numero(valor) and valor >= 0 and valor <= 9007199254740991 and floor(valor) == valor
