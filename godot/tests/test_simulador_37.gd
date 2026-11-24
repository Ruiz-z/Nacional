extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if sesion.puntaje() != 100:
		return false
	sesion.ejecutar("reparar", "teclado", 2)
	if sesion.puntaje() != 92:
		return false
	sesion.ejecutar("preparar", "teclado", 2)
	sesion.ejecutar("romper", "teclado", 2)
	if sesion.puntaje() != 82:
		return false
	sesion.ejecutar("reponer", "teclado", 2)
	if sesion.puntaje() != 87:
		return false
	sesion.ejecutar("reponer", "teclado", 2)
	if sesion.puntaje() != 87:
		return false
	var datos := Prueba.datos()
	datos.terminacion.limite_intentos = 30
	sesion = Motor.new(datos)
	for i in range(20):
		sesion.ejecutar("reparar", "teclado", 2)
	return sesion.puntaje() == 0
