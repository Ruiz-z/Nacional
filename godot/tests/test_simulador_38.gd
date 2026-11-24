extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var recibidas := []
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("marcar_causa"):
		return false
	sesion.enviar_brecha = func(brecha: Dictionary) -> void: recibidas.append(brecha)
	if sesion.marcar_causa("desconocida") or not sesion.marcar_causa("otra"):
		return false
	sesion.ejecutar("reparar", "virtual", 10)
	sesion.ejecutar("preparar", "virtual", 10)
	sesion.ejecutar("reparar", "virtual", 10)
	if recibidas.size() != 1:
		return false
	var brecha: Dictionary = recibidas[0]
	return brecha.tipo_error == "diagnostico-vs-accion" and brecha.fuente_entrada == "virtual" \
		and brecha.causa_marcada == "otra" and brecha.accion_ejecutada == "reparar" \
		and sesion.brechas() == recibidas
