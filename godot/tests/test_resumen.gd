extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Motor = preload("res://logica/simulador/motor.gd")
const Taller = preload("res://tests/acciones_taller.gd")
const Clic = preload("res://tests/test_zonas_flujo.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var tamano := arbol.root.size
	arbol.root.size = Vector2i(1280, 720)
	for modo in ["clic", "teclado", "control"]:
		var bus := Bus.instantiate()
		arbol.root.add_child(bus)
		var correcto := await comprobar(bus, arbol, modo)
		bus.free()
		if not correcto:
			printerr("Falló el resumen con ", modo)
			arbol.root.size = tamano
			return false
	arbol.root.size = tamano
	return true


static func comprobar(bus: Node3D, arbol: SceneTree, modo: String) -> bool:
	for id in bus.datos.ruta_ideal:
		if not Taller.equipar(bus, id):
			return false
		bus.ejecutar(id, "virtual")
	if not Taller.cerrar_orden(bus) or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return false
	await arbol.process_frame
	await arbol.process_frame
	var resumen: Control = bus.resumen
	var reflexion: LineEdit = resumen.get_node("%Reflexion")
	if resumen.get_node("%Estado").text != "Orden resuelta" or arbol.root.gui_get_focus_owner() != reflexion:
		return false
	for nombre in ["Guardar", "Omitir", "Reintentar", "Volver"]:
		var boton: Button = resumen.get_node("%" + nombre)
		if not boton.is_visible_in_tree() or not arbol.root.get_visible_rect().encloses(boton.get_global_rect()):
			return false

	var salidas: Array[bool] = []
	bus.salida_solicitada.connect(func(): salidas.append(true))
	match modo:
		"clic":
			pulsar(arbol.root, resumen.get_node("%Guardar"))
			if not resumen.get_node("%Validacion").visible or not reflexion.has_focus():
				return false
			tecla(arbol.root, KEY_R, "R".unicode_at(0))
			pulsar(arbol.root, resumen.get_node("%Guardar"))
			if bus.motor.resumen().reflexion != "R" or not resumen.get_node("%Ruta").visible:
				return false
			await arbol.process_frame
			pulsar(arbol.root, resumen.get_node("%Reintentar"))
			if resumen.visible or not bus.motor.fin().is_empty() or not bus.jugador.activo:
				return false
			if not agotar_intentos(bus):
				return false
			await arbol.process_frame
			pulsar(arbol.root, resumen.get_node("%Omitir"))
			if not bus.motor.resumen().reflexion_omitida or not resumen.get_node("%Ruta").visible:
				return false
			await arbol.process_frame
			pulsar(arbol.root, resumen.get_node("%Volver"))
		"teclado":
			tecla(arbol.root, KEY_TAB)
			tecla(arbol.root, KEY_ENTER)
			if not resumen.get_node("%Validacion").visible or not reflexion.has_focus():
				return false
			tecla(arbol.root, KEY_T, "T".unicode_at(0))
			tecla(arbol.root, KEY_TAB)
			tecla(arbol.root, KEY_ENTER)
			if bus.motor.resumen().reflexion != "T" or not resumen.get_node("%Ruta").visible:
				return false
			tecla(arbol.root, KEY_ENTER)
			if resumen.visible or not bus.motor.fin().is_empty() or not agotar_intentos(bus):
				return false
			tecla(arbol.root, KEY_TAB)
			tecla(arbol.root, KEY_TAB)
			tecla(arbol.root, KEY_ENTER)
			if not bus.motor.resumen().reflexion_omitida or not resumen.get_node("%Ruta").visible:
				return false
			tecla(arbol.root, KEY_ESCAPE)
		"control":
			control(arbol.root, JOY_BUTTON_A)
			if not resumen.get_node("%Validacion").visible:
				return false
			control(arbol.root, JOY_BUTTON_DPAD_RIGHT)
			control(arbol.root, JOY_BUTTON_DPAD_RIGHT)
			control(arbol.root, JOY_BUTTON_A)
			if not bus.motor.resumen().reflexion_omitida or not resumen.get_node("%Ruta").visible:
				return false
			control(arbol.root, JOY_BUTTON_B)
	return salidas.size() == 1


static func agotar_intentos(bus: Node3D) -> bool:
	var orden: Dictionary = bus.datos.duplicate(true)
	orden.terminacion.limite_intentos = 1
	bus.motor = Motor.new(orden)
	if not Taller.equipar(bus, "inspeccionar"):
		return false
	bus.ejecutar("inspeccionar", "teclado")
	Taller.cerrar_exitos(bus)
	return bus.resumen.visible and bus.resumen.get_node("%Estado").text == "Límite de intentos" \
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE


static func pulsar(raiz: Window, boton: Button) -> void:
	var centro := boton.get_global_rect().get_center()
	var movimiento := InputEventMouseMotion.new()
	movimiento.position = centro
	movimiento.global_position = centro
	raiz.push_input(movimiento, true)
	Clic.clic(raiz, centro)


static func tecla(raiz: Window, codigo: Key, unicode := 0) -> void:
	for presionada in [true, false]:
		var evento := InputEventKey.new()
		evento.keycode = codigo
		evento.unicode = unicode
		evento.pressed = presionada
		raiz.push_input(evento, true)


static func control(raiz: Window, boton: JoyButton) -> void:
	for presionado in [true, false]:
		var evento := InputEventJoypadButton.new()
		evento.button_index = boton
		evento.pressed = presionado
		raiz.push_input(evento, true)
