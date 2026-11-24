extends RefCounted

static func ejecutar() -> bool:
	var entrada := load("res://logica/entrada/entrada.gd").new() as RefCounted
	var teclado: Dictionary = entrada.traducir("teclado", "E", 1)
	var control: Dictionary = entrada.traducir("control", "L", 1)
	var panel: Dictionary = entrada.traducir("panel", "bloqueo", 0)
	if teclado.accion != "bloqueo" or control.accion != teclado.accion:
		return false
	if teclado.valor != 1 or control.valor != 0 or panel.valor != 0:
		return false
	if entrada.traducir("panel", "torque", 100).valor != 100:
		return false
	return entrada.traducir("control", "ZL", 1).valor == 99 \
		and entrada.traducir("teclado", "rueda-abajo", 1).valor == 98 \
		and entrada.traducir("teclado", "desconocido", 1).is_empty() \
		and entrada.traducir("panel", "confirmar", 0).is_empty() \
		and entrada.traducir("virtual", "cancelar", 1).accion == "cancelar"
