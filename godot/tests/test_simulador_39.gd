extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("reintentar") or sesion.reintentar() != null:
		return false
	sesion.ejecutar("preparar", "teclado", 2)
	sesion.ejecutar("romper", "teclado", 2)
	sesion.ejecutar("insegura", "panel", 2)
	var intento: RefCounted = sesion.reintentar()
	if intento == null or intento.estado().lugar != "B" or not intento.estado().listo \
			or intento.estado().tornillo_roto or intento.puntaje() != 100 or not intento.faltas().is_empty():
		return false
	return intento.ejecutar("reparar", "teclado", 2).aplicada and intento.fin() == "resuelto"
