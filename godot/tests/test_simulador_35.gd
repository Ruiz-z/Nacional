extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("recuperaciones_disponibles"):
		return false
	if sesion.ejecutar("reponer", "teclado", 10).aplicada:
		return false
	sesion.ejecutar("preparar", "teclado", 10)
	var rotura := sesion.ejecutar("romper", "teclado", 10)
	var opciones: Dictionary = sesion.recuperaciones_disponibles()
	if rotura.eventos != ["rotura"] or not opciones.has("reponer"):
		return false
	for campo in ["costo", "tiempo", "riesgo"]:
		if opciones.reponer.get(campo, "").is_empty():
			return false
	return sesion.ejecutar("reponer", "teclado", 10).aplicada \
		and not sesion.estado().tornillo_roto and sesion.recuperaciones_disponibles().is_empty()
