extends RefCounted

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	var jugador := bus.get_node("Jugador") as CharacterBody3D
	var camara := jugador.get_node("Camara") as Camera3D
	var correcto := camara.current and is_equal_approx(camara.position.y, 1.7) \
		and jugador.get_node("Cuerpo").shape is CapsuleShape3D \
		and bus.get_node("Colisiones").get_child_count() == 6
	bus.free()
	return correcto
