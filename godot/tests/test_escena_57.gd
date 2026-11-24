extends RefCounted

const Escena = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Escena.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.abrir_menu(bus.get_node("Sector").piezas.compuerta)
	bus.recibir_accion({"accion": "elegir-accion", "valor": 1})
	var correcto: bool = bus.motor != null and bus.motor.estado().inspeccionado
	bus.free()
	return correcto
