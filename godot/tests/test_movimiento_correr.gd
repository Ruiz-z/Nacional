extends RefCounted

const Movimiento = preload("res://logica/simulador/movimiento.gd")
const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	if Movimiento.factor(false, false) != 1.0 or Movimiento.factor(true, false) != Movimiento.FACTOR_CORRER \
			or Movimiento.factor(true, true) != Movimiento.FACTOR_AGACHADO \
			or Movimiento.factor(false, true) != Movimiento.FACTOR_AGACHADO:
		return false
	var normal := Movimiento.velocidad(Vector2(0, -1), 0.0)
	var rapido := Movimiento.velocidad(Vector2(0, -1), 0.0, Movimiento.FACTOR_CORRER)
	if not is_equal_approx(rapido.length(), normal.length() * Movimiento.FACTOR_CORRER):
		return false
	# El salto debe alcanzar una altura razonable y volver al suelo.
	var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var altura := Movimiento.SALTO * Movimiento.SALTO / (2.0 * gravedad)
	if altura < 0.3 or altura > 1.0:
		printerr("Altura de salto: ", altura)
		return false
	# Con las teclas sin pulsar el jugador no corre, ni se agacha ni salta.
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/faros.json"
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	var quieto: bool = not bus.jugador.corriendo and not bus.jugador.agachado
	bus.free()
	return quieto
