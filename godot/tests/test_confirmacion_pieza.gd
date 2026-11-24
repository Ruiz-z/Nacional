extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	var raiz := (Engine.get_main_loop() as SceneTree).root
	raiz.add_child(bus)
	var sector := bus.get_node("Sector")
	var equipado := Taller.equipar(bus, "inspeccionar")
	bus.abrir_menu(sector.piezas.compuerta)
	var correcto: bool = equipado and not bus.menu_pieza.diagnostico.visible
	tecla(raiz, KEY_H)
	correcto = correcto and not bus.get_node("Interfaz").visible
	tecla(raiz, KEY_H)
	correcto = correcto and bus.get_node("Interfaz").visible
	tecla(raiz, KEY_1)
	correcto = correcto and sector.abierta and not bus.menu_pieza.visible \
		and bus.resultado.text == "Compuerta abierta. Ahora abre el monitor y elige Evaluar el indicio." \
		and not bus.duracion_aviso.is_stopped()
	correcto = correcto and Taller.equipar(bus, "evaluar_indicio")
	bus.abrir_menu(sector.piezas.monitor)
	correcto = correcto and bus.menu_pieza.diagnostico.visible
	tecla(raiz, KEY_UP)
	correcto = correcto and raiz.gui_get_focus_owner() == bus.menu_pieza.causas[1]
	control(raiz, JOY_BUTTON_A)
	correcto = correcto and bus.causa_marcada == "aviso-inconsistente" \
		and bus.menu_pieza.causas[1].text.begins_with("[x]")
	control(raiz, JOY_BUTTON_DPAD_UP)
	control(raiz, JOY_BUTTON_A)
	bus.menu_pieza.botones[0].pressed.emit()
	correcto = correcto and Taller.equipar(bus, "confirmar_solucion")
	bus.abrir_menu(sector.piezas.bateria)
	control(raiz, JOY_BUTTON_DPAD_DOWN)
	correcto = correcto and raiz.gui_get_focus_owner() == bus.menu_pieza.botones[1]
	control(raiz, JOY_BUTTON_DPAD_UP)
	control(raiz, JOY_BUTTON_A)
	correcto = correcto and bus.accion_pendiente == "confirmar_solucion" and bus.motor.fin().is_empty()
	var aviso: Label = bus.menu_pieza.contenido.get_node("Pendiente")
	correcto = correcto and aviso.is_visible_in_tree() and aviso.text.contains("Acción lista")
	tecla(raiz, KEY_ESCAPE)
	tecla(raiz, KEY_ENTER)
	correcto = correcto and not bus.menu_pieza.visible and bus.motor.fin().is_empty()
	bus.abrir_menu(sector.piezas.bateria)
	tecla(raiz, KEY_1)
	correcto = correcto and bus.accion_pendiente == "confirmar_solucion" and bus.motor.fin().is_empty()
	bus.panel.get_node("Confirmar").pressed.emit()
	correcto = correcto and bus.motor.fin() == "resuelto" and Taller.cerrar_orden(bus)
	var salidas: Array[bool] = []
	bus.salida_solicitada.connect(func(): salidas.append(true))
	tecla(raiz, KEY_ESCAPE)
	correcto = correcto and salidas.is_empty() and bus.resultado.text == "Esc de nuevo para salir"
	tecla(raiz, KEY_ESCAPE)
	correcto = correcto and salidas.size() == 1
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
