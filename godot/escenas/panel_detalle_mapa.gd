extends PanelContainer

signal practicar(accion: Dictionary)

const MapaRuta = preload("res://escenas/mapa_ruta.gd")

const ANCHO := 420

var contenido := VBoxContainer.new()
var cerrar_boton := Button.new()
var titulo := Label.new()
var estado_visible := Label.new()
var scroll := ScrollContainer.new()
var origen: Button


func _ready() -> void:
	hide()
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	get_viewport().size_changed.connect(ajustar_ancho)
	ajustar_ancho()

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#1A2327")
	estilo.border_color = Color("#5B7480")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		estilo.set_content_margin(lado, 22)
	add_theme_stylebox_override("panel", estilo)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	add_child(caja)
	cerrar_boton.text = "Cerrar"
	cerrar_boton.custom_minimum_size.y = 40
	cerrar_boton.size_flags_horizontal = Control.SIZE_SHRINK_END
	MapaRuta.estilizar_boton(cerrar_boton, MapaRuta.FONDO, MapaRuta.NEUTRO)
	cerrar_boton.pressed.connect(cerrar)
	caja.add_child(cerrar_boton)

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	caja.add_child(scroll)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 14)
	scroll.add_child(contenido)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.theme_type_variation = &"Seccion"
	titulo.add_theme_font_size_override("font_size", 22)
	contenido.add_child(titulo)
	contenido.add_child(estado_visible)


func ajustar_ancho() -> void:
	offset_left = -minf(ANCHO, get_viewport_rect().size.x)
	offset_right = 0
	offset_top = 0
	offset_bottom = 0


func abrir(datos: Dictionary, boton: Button, estado: String) -> void:
	origen = boton
	estado_visible.text = estado
	estado_visible.add_theme_color_override("font_color", MapaRuta.ESTADOS[estado])
	for hijo in contenido.get_children():
		if hijo != titulo and hijo != estado_visible:
			contenido.remove_child(hijo)
			hijo.queue_free()
	titulo.text = datos.titulo
	for parrafo in datos.parrafos:
		agregar_texto(contenido, parrafo)
	if not datos.preguntas.is_empty():
		agregar_texto(contenido, "Intentos registrados", &"Seccion")
	for pregunta in datos.preguntas:
		var bloque := VBoxContainer.new()
		bloque.add_theme_constant_override("separation", 4)
		contenido.add_child(bloque)
		if pregunta.has("enunciado"):
			agregar_texto(bloque, pregunta.enunciado)
		if pregunta.has("respuesta"):
			agregar_texto(bloque, "Tu respuesta: %s" % pregunta.respuesta, &"Secundario")
		if pregunta.has("correcta"):
			agregar_texto(bloque, "Respuesta correcta: %s" % pregunta.correcta, &"Secundario")
	for accion in datos.acciones:
		var practicar_boton := Button.new()
		practicar_boton.text = accion.texto
		practicar_boton.custom_minimum_size.y = 44
		MapaRuta.estilizar_boton(practicar_boton, MapaRuta.ACENTO, MapaRuta.OSCURO, MapaRuta.OSCURO)
		practicar_boton.pressed.connect(func():
			cerrar()
			practicar.emit(accion))
		contenido.add_child(practicar_boton)
	show()
	scroll.set_deferred("scroll_vertical", 0)
	cerrar_boton.grab_focus()


func agregar_texto(caja: Container, texto: String, variante: StringName = &"") -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = variante
	rotulo.add_theme_font_size_override("font_size", 16)
	rotulo.add_theme_constant_override("line_spacing", 5)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(rotulo)


func cerrar() -> void:
	hide()
	if is_instance_valid(origen) and origen.is_visible_in_tree():
		origen.grab_focus()


func _input(evento: InputEvent) -> void:
	if is_visible_in_tree() and evento is InputEventKey and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
