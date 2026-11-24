extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")

static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.flashcard.confirmar()
	if not Taller.equipar(bus, "inspeccionar"):
		bus.free()
		return false
	bus.panel.conexion.iniciar_panel(0)
	bus.actualizar_panel(3000)
	bus.ejecutar("inspeccionar", "teclado")
	var correcto: bool = not bus.motor.estado().inspeccionado and bus.panel.conexion.pausado()
	bus.get_node("Interfaz/Lateral/Continuar").pressed.emit()
	bus.ejecutar("inspeccionar", "teclado")
	correcto = correcto and bus.motor.estado().inspeccionado
	bus.free()
	return correcto
