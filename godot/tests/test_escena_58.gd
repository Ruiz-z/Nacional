extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Bus = preload("res://escenas/bus.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var bus := Bus.instantiate()
	bus.tecnico = Alias.alta(base, "T-58").merged({"base": base})
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.abrir_menu(bus.get_node("Sector").piezas.compuerta)
	bus.menu_pieza.botones[0].pressed.emit()
	bus.abrir_menu(bus.get_node("Sector").piezas.monitor)
	bus.menu_pieza.causa.select(2)
	bus.menu_pieza.causa.item_selected.emit(2)
	bus.menu_pieza.botones[0].pressed.emit()
	bus.abrir_menu(bus.get_node("Sector").piezas.bateria)
	bus.menu_pieza.botones[0].pressed.emit()
	bus.panel.get_node("Confirmar").pressed.emit()
	var correcto: bool = bus.motor.estado().indicio_confirmado and bus.motor.brechas().size() == 1
	correcto = correcto and bus.resultados_guardados
	var brechas: Variant = Base.consultar(base, "SELECT causa_marcada FROM brecha;")
	var intentos: Variant = Base.consultar(base, "SELECT tipo_error FROM intento WHERE tipo_error = 'diagnostico-vs-accion';")
	correcto = correcto and brechas == [{"causa_marcada": "aviso-inconsistente"}] \
		and intentos == [{"tipo_error": "diagnostico-vs-accion"}]
	bus.free()
	return correcto
