extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("faltas") or not sesion.has_method("puntaje"):
		return false
	sesion.ejecutar("preparar", "control", 10)
	var leve := sesion.ejecutar("romper", "control", 20)
	if leve.motivo.is_empty() or sesion.puntaje() >= 100 or not sesion.fin().is_empty():
		return false
	var critica := sesion.ejecutar("insegura", "panel", 30)
	return critica.fuente == Prueba.FUENTE and not critica.motivo.is_empty() \
		and sesion.fin() == "falta-critica" and sesion.faltas().size() == 1 \
		and sesion.faltas()[0].accion == "insegura" and sesion.puntaje() == 0 \
		and not sesion.ejecutar("reponer", "teclado", 10).aplicada
