extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Menu = preload("res://escenas/menu.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var control := InputEventJoypadButton.new()
	control.button_index = JOY_BUTTON_A
	var correcto: bool = InputMap.event_is_action(control, "ui_accept")
	correcto = correcto and menu.botones.diagnostico.disabled and menu.botones.ruta.disabled
	menu.inicio.get_node("Alias").text = "T-73"
	menu.inicio.get_node("Alta").pressed.emit()
	correcto = correcto and not menu.botones.diagnostico.disabled and menu.botones.ruta.disabled
	correcto = correcto and menu.inicio.get_node("Siguiente").text.contains("Diagnóstico")
	menu._process(0.0)
	correcto = correcto and menu.inicio.get_node("Entrada").text == "Panel virtual"
	menu.conexion.iniciar_panel(Time.get_ticks_msec() - 3000)
	menu._process(0.0)
	correcto = correcto and menu.inicio.get_node("Entrada").text.contains("Panel desconectado")
	menu.inicio.get_node("Demo").pressed.emit()
	correcto = correcto and menu.pantalla != null and not menu.inicio.visible
	menu.pantalla.get_node("Tablero").pressed.emit()
	correcto = correcto and menu.pantalla.alias_actual.begins_with("[DEMO]")
	menu.get_node("Marco/Volver").pressed.emit()
	correcto = correcto and menu.inicio.visible and menu.perfil.alias == "T-73"
	menu.free()
	return correcto
