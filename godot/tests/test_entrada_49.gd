extends RefCounted

const Protocolo = preload("res://logica/entrada/protocolo.gd")
const Evaluacion = preload("res://logica/entrada/evaluacion_panel.gd")

static func ejecutar() -> bool:
	var protocolo := Protocolo.new()
	for valor in [-1, 101, "42"]:
		if not protocolo.recibir(linea(valor, 0, 0)).is_empty():
			return false
	if protocolo.recibir(linea(0, 0, 0)).get("valor") != 0 \
			or protocolo.recibir(linea(100, 1, 50)).get("valor") != 100:
		return false
	return Evaluacion.evaluar_torque(40, 40, 60).is_empty() \
		and Evaluacion.evaluar_torque(60, 40, 60).is_empty() \
		and Evaluacion.evaluar_torque(39, 40, 60).tipo_error == "valor-fuera-de-rango" \
		and Evaluacion.evaluar_torque(61, 40, 60).tipo_error == "valor-fuera-de-rango"

static func linea(valor: Variant, n: int, t: int) -> String:
	return JSON.stringify({"v": 1, "ctrl": "torque", "valor": valor, "n": n, "t": t})
