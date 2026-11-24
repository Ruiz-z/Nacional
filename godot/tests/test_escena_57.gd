extends RefCounted

const Escena = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Escena.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.get_node("Interfaz/Lateral/Inspeccionar").pressed.emit()
	var correcto: bool = bus.motor != null and bus.motor.estado().inspeccionado
	bus.free()
	return correcto
