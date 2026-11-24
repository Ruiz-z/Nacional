extends RefCounted

const Resumen = preload("res://escenas/resumen.gd")
const Bus = preload("res://escenas/bus.tscn")
const Motor = preload("res://logica/simulador/motor.gd")
const Taller = preload("res://tests/acciones_taller.gd")
const Clic = preload("res://tests/test_zonas_flujo.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	if not comprobar_formatos():
		printerr("Falló el formato o la agrupación del resumen")
		return false
	var tamano := arbol.root.size
	for prueba in [[Vector2i(1280, 720), "clic"], [Vector2i(1920, 1080), "clic"],
			[Vector2i(1280, 720), "teclado"], [Vector2i(1280, 720), "control"]]:
		arbol.root.size = prueba[0]
		var bus := Bus.instantiate()
		arbol.root.add_child(bus)
		var correcto := await comprobar(bus, arbol, prueba[1])
		bus.free()
		if not correcto:
			printerr("Falló el resumen con ", prueba[1], " a ", prueba[0])
			arbol.root.size = tamano
			return false
	arbol.root.size = tamano
	return true


static func comprobar_formatos() -> bool:
	if [Resumen.plural_errores(0), Resumen.plural_errores(1), Resumen.plural_errores(2)] \
			!= ["0 errores", "1 error", "2 errores"]:
		return false
	if [Resumen.formato_tiempo(999), Resumen.formato_tiempo(1000), Resumen.formato_tiempo(60000),
			Resumen.formato_tiempo(251595)] != ["menos de 1 s", "1 s", "1 min 0 s", "4 min 11 s"]:
		return false
	var inspeccion := {"accion": "inspeccionar", "aplicada": true, "criticidad": "normal", "tipo_error": ""}
	var confirmar := inspeccion.merged({"accion": "confirmar"}, true)
	var temprano := confirmar.merged({"aplicada": false, "tipo_error": "orden-incorrecto"}, true)
	var grupos := Resumen.agrupar_pasos([inspeccion, inspeccion, temprano, confirmar, inspeccion, temprano,
		inspeccion, confirmar])
	return grupos.size() == 6 and grupos[0].decisiones == [inspeccion, inspeccion] \
		and grupos[0].resultados == ["acierto", "acierto"] and grupos[1].decisiones == [temprano, confirmar] \
		and grupos[1].resultados == ["error", "corregido"] and grupos[5].resultados == ["corregido"]


static func comprobar(bus: Node3D, arbol: SceneTree, modo: String) -> bool:
	var primer_paso: String = bus.datos.ruta_ideal[0]
	if not Taller.equipar(bus, primer_paso):
		return false
	bus.ejecutar(primer_paso, "virtual")
	if not Taller.equipar(bus, primer_paso):
		return false
	bus.ejecutar(primer_paso, "virtual")
	var ultimo_paso: String = bus.datos.ruta_ideal[-1]
	for id in bus.datos.ruta_ideal.slice(1):
		if id == ultimo_paso:
			if not Taller.equipar(bus, id):
				return false
			bus.motor.registrar_herramienta_equivocada(id, "virtual", 0, "Elige la herramienta de la orden.")
		if not Taller.equipar(bus, id):
			return false
		bus.ejecutar(id, "virtual")
	if not Taller.cerrar_orden(bus) or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return false
	await arbol.process_frame
	await arbol.process_frame
	var resumen: Control = bus.resumen
	var marca: Label = resumen.get_node("%Marca")
	var detalle := textos_visibles(resumen)
	if not marca.visible or marca.text != "Ejemplo didáctico" or detalle.count(marca.text) != 1:
		return false
	if not detalle.contains("Paso a paso") or not detalle.contains("Tiempo") \
			or not detalle.contains("Inspeccionar ×2") or not detalle.contains("Corregido") \
			or not detalle.contains("Elige la herramienta de la orden.") \
			or not texto_limpio(detalle):
		return false
	var reflexion: LineEdit = resumen.get_node("%Reflexion")
	if resumen.get_node("%Estado").text != "Orden resuelta" or arbol.root.gui_get_focus_owner() != reflexion:
		return false
	for nombre in ["Guardar", "Omitir", "Reintentar", "Volver"]:
		var boton: Button = resumen.get_node("%" + nombre)
		if not boton.is_visible_in_tree() or not arbol.root.get_visible_rect().encloses(boton.get_global_rect()):
			return false

	if modo == "clic" and not await comprobar_desplazamiento(arbol, resumen):
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
	var ruta: String = resumen.get_node("%Ruta").text
	return salidas.size() == 1 and ruta.begins_with("1. ") \
		and "Ruta ideal" in textos_visibles(resumen) and texto_limpio(textos_visibles(resumen))


static func textos_visibles(nodo: Control) -> String:
	if not nodo.visible:
		return ""
	var lineas := PackedStringArray()
	if nodo is Label or nodo is Button:
		lineas.append(nodo.text)
	for hijo in nodo.get_children():
		if hijo is Control:
			lineas.append(textos_visibles(hijo))
	return "\n".join(lineas)


static func texto_limpio(texto: String) -> bool:
	return " ·\n" not in texto and " ms" not in texto and "[MUESTRA]" not in texto and "[DEMO]" not in texto


static func comprobar_desplazamiento(arbol: SceneTree, resumen: Control) -> bool:
	var area: ScrollContainer = resumen.get_node("%Desplazamiento")
	var acciones: Control = resumen.get_node("%Acciones")
	var posicion := acciones.get_global_rect()
	# La reflexión larga representa una tarjeta desplazable incluso en pantallas altas.
	var pregunta: Label = resumen.get_node("%Pregunta")
	var anterior := pregunta.text
	pregunta.text += "\nAntes de confirmar, revisaría cada paso de la orden.".repeat(60)
	await arbol.process_frame
	await arbol.process_frame
	tecla(arbol.root, KEY_PAGEDOWN)
	var correcto := area.scroll_vertical > 0 and acciones.get_global_rect() == posicion
	pregunta.text = anterior
	tecla(arbol.root, KEY_PAGEUP)
	await arbol.process_frame
	await arbol.process_frame
	return correcto and area.scroll_vertical == 0


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
