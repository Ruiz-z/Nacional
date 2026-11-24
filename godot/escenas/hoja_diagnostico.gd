extends CanvasLayer

signal guardada(acciones: Array, fuente: String)
signal cancelada

const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const MenuVisual = preload("res://escenas/menu_pieza.gd")

var bloques: Array[ButtonGroup] = []
var opciones: Array[Button] = []
var guardar: Button
var cerrar: Button
var aviso: Label


func _ready() -> void:
	layer = 18
	hide()
	var fondo := ColorRect.new()
	fondo.color = Color(0.024, 0.051, 0.071, 0.76)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tarjeta := PanelContainer.new()
	centro.add_child(tarjeta)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 10)
	tarjeta.add_child(contenido)
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.text = "Hoja de diagnóstico"
	contenido.add_child(titulo)
	for punto: String in Mediciones.PUNTOS:
		agregar_bloque(contenido, "Lectura de " + punto.to_upper(), "reportar_" + punto + "_", Mediciones.OPCIONES)
	var causas := {}
	for causa in ["alimentacion", "senal", "modulo"]:
		causas[causa] = MenuVisual.nombre_causa(causa)
	agregar_bloque(contenido, "Causa de la falla", "diagnosticar_", causas)
	aviso = Label.new()
	aviso.add_theme_color_override("font_color", Color("#ffe1a1"))
	contenido.add_child(aviso)
	var pie := HBoxContainer.new()
	contenido.add_child(pie)
	cerrar = Button.new()
	cerrar.text = "Cancelar"
	cerrar.custom_minimum_size.y = 48
	pie.add_child(cerrar)
	cerrar.pressed.connect(func(): cancelada.emit())
	guardar = Button.new()
	guardar.text = "Guardar hoja"
	guardar.theme_type_variation = &"Primario"
	guardar.custom_minimum_size.y = 48
	guardar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(guardar)
	guardar.pressed.connect(enviar.bind("teclado"))


func agregar_bloque(contenido: VBoxContainer, titulo: String, prefijo: String, valores: Dictionary) -> void:
	var etiqueta := Label.new()
	etiqueta.text = titulo
	contenido.add_child(etiqueta)
	var fila := HBoxContainer.new()
	contenido.add_child(fila)
	var grupo := ButtonGroup.new()
	bloques.append(grupo)
	for valor in valores:
		var opcion := CheckBox.new()
		opcion.text = "%d · %s" % [opciones.size() + 1, valores[valor]]
		opcion.accessibility_name = "%s · %s" % [titulo, valores[valor]]
		opcion.button_group = grupo
		opcion.set_meta("accion", prefijo + valor)
		opcion.custom_minimum_size.y = 48
		opcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(opcion)
		opciones.append(opcion)


func abrir(reportadas: Dictionary, causa: String) -> void:
	var previas := ["reportar_tp1_" + reportadas.get("tp1", ""),
		"reportar_tp2_" + reportadas.get("tp2", ""), "diagnosticar_" + causa]
	for opcion in opciones:
		opcion.set_pressed_no_signal(opcion.get_meta("accion") in previas)
	aviso.text = ""
	show()
	opciones[0].grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func enviar(fuente: String) -> void:
	var acciones := []
	for grupo in bloques:
		var opcion := grupo.get_pressed_button()
		if opcion == null:
			var indice := acciones.size()
			aviso.text = ["Elige la lectura de TP1.", "Elige la lectura de TP2.", "Elige la causa de la falla."][indice]
			opciones[indice * 3].grab_focus()
			return
		acciones.append(opcion.get_meta("accion"))
	guardada.emit(acciones, fuente)


func _input(evento: InputEvent) -> void:
	if not visible or not evento.is_pressed() or evento.is_echo():
		return
	var controles := opciones + [guardar, cerrar]
	var foco := controles.find(get_viewport().gui_get_focus_owner())
	var paso := 0
	if evento is InputEventKey:
		if evento.keycode >= KEY_1 and evento.keycode <= KEY_9:
			var opcion := opciones[evento.keycode - KEY_1]
			opcion.button_pressed = true
			opcion.grab_focus()
		elif evento.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			enviar("teclado")
		elif evento.keycode == KEY_ESCAPE:
			cancelada.emit()
		elif evento.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			paso = {KEY_UP: -3, KEY_DOWN: 3, KEY_LEFT: -1, KEY_RIGHT: 1}[evento.keycode]
		else:
			return
	elif evento is InputEventJoypadButton:
		match evento.button_index:
			JOY_BUTTON_A:
				if foco == opciones.size():
					enviar("control")
				elif foco == opciones.size() + 1:
					cancelada.emit()
				elif foco >= 0:
					opciones[foco].button_pressed = true
			JOY_BUTTON_B: cancelada.emit()
			JOY_BUTTON_DPAD_UP: paso = -3
			JOY_BUTTON_DPAD_DOWN: paso = 3
			JOY_BUTTON_DPAD_LEFT: paso = -1
			JOY_BUTTON_DPAD_RIGHT: paso = 1
			_: return
	else:
		return
	if paso != 0:
		var destino := posmod(foco + paso, controles.size())
		if paso == 3 and foco >= 6:
			destino = opciones.size()
		elif paso == -3 and foco >= opciones.size():
			destino = 6
		controles[destino].grab_focus()
	get_viewport().set_input_as_handled()
