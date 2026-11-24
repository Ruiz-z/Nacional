extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Bus = preload("res://escenas/bus.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var bus := Bus.instantiate()
	bus.tecnico = Alias.alta(base, "T-58").merged({"base": base})
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.flashcard.confirmar()
	if not Taller.equipar(bus, "inspeccionar"):
		bus.free()
		return false
	bus.abrir_menu(bus.get_node("Sector").piezas.compuerta)
	bus.menu_pieza.botones[0].pressed.emit()
	if not Taller.equipar(bus, "evaluar_indicio"):
		bus.free()
		return false
	bus.abrir_menu(bus.get_node("Sector").piezas.monitor)
	var opciones: Array = bus.menu_pieza.causas
	opciones[0].button_pressed = true
	opciones[0].pressed.emit()
	opciones[1].button_pressed = true
	opciones[1].pressed.emit()
	var marca_correcta: bool = not opciones[0].button_pressed and opciones[1].text.begins_with("[x]")
	bus.menu_pieza.botones[0].pressed.emit()
	if not Taller.equipar(bus, "confirmar_solucion"):
		bus.free()
		return false
	bus.abrir_menu(bus.get_node("Sector").piezas.bateria)
	bus.menu_pieza.botones[0].pressed.emit()
	bus.panel.get_node("Confirmar").pressed.emit()
	var correcto: bool = marca_correcta and bus.motor.estado().indicio_confirmado and bus.motor.brechas().size() == 1
	correcto = correcto and Taller.cerrar_orden(bus, 2) and bus.resultados_guardados
	var brechas: Variant = Base.consultar(base, "SELECT causa_marcada FROM brecha;")
	var intentos: Variant = Base.consultar(base, "SELECT tipo_error FROM intento WHERE tipo_error = 'diagnostico-vs-accion';")
	correcto = correcto and brechas == [{"causa_marcada": "aviso-inconsistente"}] \
		and intentos == [{"tipo_error": "diagnostico-vs-accion"}]
	bus.free()
	return correcto
