extends RefCounted

# Controles de las pantallas de cuenta sobre la tipografía del tema del taller.
const FONDO := Color("#0E1A22")
const BORDE := Color("#667E89")


static func caja(color: Color, borde := BORDE, grosor := 1) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(3)
	return estilo


static func boton(texto: String, primario := false) -> Button:
	var control := Button.new()
	control.text = texto
	estilizar_boton(control, primario)
	return control


static func estilizar_boton(control: BaseButton, primario := false) -> void:
	control.custom_minimum_size.y = 44
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for estado in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var color: Color = {
			"normal": Color("#1AA7A6") if primario else Color("#1A2327"),
			"hover": Color("#21A4AA") if primario else Color("#27404D"),
			"pressed": Color("#129B9A") if primario else Color("#11507D"),
			"hover_pressed": Color("#129B9A") if primario else Color("#11507D"),
			"disabled": Color("#1A2327"),
		}[estado]
		var estilo := caja(color)
		estilo.content_margin_left = 14
		estilo.content_margin_right = 14
		estilo.content_margin_top = 8
		estilo.content_margin_bottom = 8
		control.add_theme_stylebox_override(estado, estilo)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(estado, FONDO if primario else Color.WHITE)
	control.add_theme_color_override("font_disabled_color", Color("#A5B8BE"))
	control.add_theme_constant_override("outline_size", 0)
	control.add_theme_stylebox_override("focus", caja(Color.TRANSPARENT, Color.WHITE, 3))


static func etiqueta(texto: String, variacion: StringName = &"") -> Label:
	var control := Label.new()
	control.text = texto
	control.theme_type_variation = variacion
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return control


static func campo(padre: Control, nombre: String, secreto := false) -> LineEdit:
	var rotulo := etiqueta(nombre, &"Secundario")
	rotulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	padre.add_child(rotulo)
	var control := LineEdit.new()
	control.accessibility_name = nombre
	control.secret = secreto
	control.custom_minimum_size.y = 46
	for estado in ["normal", "read_only"]:
		var estilo := caja(Color("#1A2327"))
		estilo.content_margin_left = 12
		estilo.content_margin_right = 12
		control.add_theme_stylebox_override(estado, estilo)
	control.add_theme_stylebox_override("focus", caja(Color.TRANSPARENT, Color.WHITE, 3))
	var normal := control.get_theme_stylebox("normal") as StyleBoxFlat
	var resaltado := normal.duplicate() as StyleBoxFlat
	resaltado.bg_color = Color("#27404D")
	control.mouse_entered.connect(func():
		if control.editable and control.get_theme_stylebox("normal") == normal:
			control.add_theme_stylebox_override("normal", resaltado))
	control.mouse_exited.connect(func():
		if control.get_theme_stylebox("normal") == resaltado:
			control.add_theme_stylebox_override("normal", normal))
	control.text_changed.connect(func(_texto: String):
		control.add_theme_stylebox_override("normal", normal))
	padre.add_child(control)
	return control


static func marcar_error(control: LineEdit) -> void:
	var estilo := control.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	estilo.border_color = Color("#F28B84")
	control.add_theme_stylebox_override("normal", estilo)


static func texto_modal(bloque: VBoxContainer, texto: String, variacion: StringName = &"") -> void:
	# Un diálogo calcula su tamaño antes de ordenar sus hijos.
	# Ajusta los saltos a su ancho de lectura antes de mostrarlo.
	var rotulo := etiqueta("", variacion)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	bloque.add_child(rotulo)
	var fuente := rotulo.get_theme_font("font")
	var tamano := rotulo.get_theme_font_size("font_size")
	var lineas := PackedStringArray()
	var linea := ""
	for palabra in texto.split(" ", false):
		var siguiente := palabra if linea.is_empty() else linea + " " + palabra
		if not linea.is_empty() and fuente.get_string_size(siguiente, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x > 366:
			lineas.append(linea)
			linea = palabra
		else:
			linea = siguiente
	lineas.append(linea)
	rotulo.text = "\n".join(lineas)


class TarjetaModal extends AcceptDialog:
	func _input(evento: InputEvent) -> void:
		if visible and evento.is_action_pressed("ui_cancel"):
			set_input_as_handled()
			hide()
			canceled.emit()


static func modal(padre: Control) -> AcceptDialog:
	var dialogo := TarjetaModal.new()
	dialogo.borderless = true
	dialogo.transient = true
	dialogo.exclusive = true
	dialogo.unresizable = true
	dialogo.min_size = Vector2i(420, 0)
	var tarjeta := caja(Color("#1A2327"))
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		tarjeta.set_content_margin(lado, 24)
	dialogo.add_theme_stylebox_override("panel", tarjeta)
	dialogo.ok_button_text = "Aceptar"
	dialogo.dialog_close_on_escape = false
	padre.add_child(dialogo)
	estilizar_boton(dialogo.get_ok_button(), true)
	return dialogo


static func aviso(padre: Control, mensaje: String, recuperar: Control = null) -> AcceptDialog:
	var dialogo := modal(padre)
	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 12)
	dialogo.add_child(bloque)
	texto_modal(bloque, "Revisa los datos", &"Seccion")
	texto_modal(bloque, mensaje)
	var cerrar := func():
		dialogo.hide()
		dialogo.queue_free()
		if is_instance_valid(recuperar):
			recuperar.grab_focus.call_deferred()
	dialogo.confirmed.connect(cerrar)
	dialogo.canceled.connect(cerrar)
	dialogo.popup_centered(Vector2i(420, 0))
	return dialogo
