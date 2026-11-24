extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")

static func ejecutar() -> bool:
	var Motor := load("res://logica/simulador/motor.gd") as GDScript
	if Motor == null:
		return false
	var sesion: RefCounted = Motor.new(Prueba.datos())
	var rechazo: Dictionary = sesion.ejecutar("reparar", "teclado", 30)
	if rechazo.aplicada or "listo" not in rechazo.motivo or sesion.estado().resuelto:
		return false
	return sesion.ejecutar("preparar", "teclado", 50).aplicada \
		and sesion.ejecutar("reparar", "teclado", 60).aplicada and sesion.estado().resuelto
