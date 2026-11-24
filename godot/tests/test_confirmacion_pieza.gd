extends RefCounted

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	var raiz := (Engine.get_main_loop() as SceneTree).root
	raiz.add_child(bus)
	var sector := bus.get_node("Sector")
	bus.abrir_menu(sector.piezas.compuerta)
	var correcto: bool = not bus.menu_pieza.causa.visible
	tecla(raiz, KEY_1)
	correcto = correcto and sector.abierta and not bus.menu_pieza.visible \
		and bus.resultado.text == "Compuerta abierta" and not bus.duracion_aviso.is_stopped()
	bus.abrir_menu(sector.piezas.monitor)
	correcto = correcto and bus.menu_pieza.causa.visible
	bus.menu_pieza.botones[0].pressed.emit()
	bus.abrir_menu(sector.piezas.bateria)
	control(raiz, JOY_BUTTON_DPAD_DOWN)
	correcto = correcto and raiz.gui_get_focus_owner() == bus.menu_pieza.botones[1]
	control(raiz, JOY_BUTTON_DPAD_UP)
	control(raiz, JOY_BUTTON_A)
	correcto = correcto and bus.accion_pendiente == "confirmar_solucion" and bus.motor.fin().is_empty()
	tecla(raiz, KEY_ESCAPE)
	tecla(raiz, KEY_ENTER)
	correcto = correcto and not bus.menu_pieza.visible and bus.motor.fin().is_empty()
	bus.abrir_menu(sector.piezas.bateria)
	tecla(raiz, KEY_1)
	correcto = correcto and bus.accion_pendiente == "confirmar_solucion" and bus.motor.fin().is_empty()
	bus.panel.get_node("Confirmar").pressed.emit()
	correcto = correcto and bus.motor.fin() == "resuelto"
	bus.free()
	return correcto


static func tecla(raiz: Window, codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	raiz.push_input(evento)


static func control(raiz: Window, boton: JoyButton) -> void:
	var evento := InputEventJoypadButton.new()
	evento.button_index = boton
	evento.pressed = true
	raiz.push_input(evento)
