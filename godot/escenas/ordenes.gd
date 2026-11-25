extends ScrollContainer

signal orden_elegida(archivo: String)

const Banco = preload("res://logica/competencias/banco.gd")
const Ordenes = preload("res://logica/simulador/ordenes.gd")
const TextoLimpio = preload("res://logica/texto_limpio.gd")
const Niveles = preload("res://logica/flujo/niveles.gd")
const ZONAS := {"gabinete": "Gabinete lateral", "faros": "Faros", "motor": "Motor",
	"cabina": "Cabina", "banco": "Banco de arnés", "bajos": "Bajos del autobús"}
const DIFICULTADES := {"facil": "Fácil", "media": "Media", "dificil": "Difícil"}
const VERDE := [Color("#DDF4E6"), Color("#185B39")]
const COLORES := {"facil": VERDE, "media": [Color("#FFF0C8"), Color("#684800")],
	"dificil": [Color("#FCE2E2"), Color("#8F252B")]}
const TURQUESA := [Color("#D4F2F1"), Color("#175A60")]
const AZUL := [Color("#3675A6"), Color.WHITE]
const SEPARACION := 12
const ANCHO_TARJETA := 268

var tecnico: Dictionary = {}
var resueltas: Dictionary = {}
var dominios: Dictionary = {}
var catalogo: Array = []
var competencia_filtro := ""

@onready var columna: VBoxContainer = $Centro/Columna
@onready var tarjetas: VBoxContainer = $Centro/Columna/Tarjetas
@onready var filtros: HBoxContainer = $Centro/Columna/Filtros


func _ready() -> void:
	draw.connect(func(): draw_rect(Rect2(Vector2.ZERO, size), Color("#ECFAFA")))
	resized.connect(ajustar_columnas)
	resueltas = Ordenes.resueltas_por(tecnico)
	if tecnico.get("rol") == "tecnico" and tecnico.has_all(["base", "alias"]):
		dominios = Niveles.dominios(tecnico.base, tecnico.alias)
	mostrar(Ordenes.listar())


func mostrar(listado: Dictionary) -> void:
	catalogo = listado.ordenes.duplicate()
	if not competencia_filtro.is_empty():
		var nombre: String = Banco.COMPETENCIAS.get(competencia_filtro, competencia_filtro)
		catalogo = catalogo.filter(func(orden: Dictionary) -> bool: return orden.competencia == nombre)
		var titulo: Label = $Centro/Columna/Titulo
		titulo.text = "Órdenes del taller · %s" % nombre
		titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catalogo.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var fg_a := numero_fg(a.get("grupo_funcion"))
		var fg_b := numero_fg(b.get("grupo_funcion"))
		if fg_a != fg_b:
			return fg_a >= 0 and (fg_b < 0 or fg_a < fg_b)
		return titulo_limpio(a).nocasecmp_to(titulo_limpio(b)) < 0)
	limpiar_contenedor(filtros)
	var grupos: Array[int] = []
	for orden in catalogo:
		var fg := numero_fg(orden.get("grupo_funcion"))
		if fg >= 0 and fg not in grupos:
			grupos.append(fg)
	var seleccion := ButtonGroup.new()
	agregar_filtro("Todas", "", seleccion).set_pressed_no_signal(true)
	for fg in grupos:
		agregar_filtro("FG %d" % fg, "FG%d" % fg, seleccion)
	aplicar_filtro("")
	filtros.get_child(0).grab_focus()
	var aviso: Label = $Centro/Columna/Aviso
	aviso.text = ""
	if catalogo.is_empty():
		aviso.text = ("No hay órdenes disponibles. Vuelve al menú y elige otra actividad."
			if competencia_filtro.is_empty() else "No hay órdenes para esta competencia. Usa Volver para retomar la ruta.")
	elif not listado.errores.is_empty():
		aviso.text = "Algunas órdenes no abrieron. Elige una de la lista."
	aviso.visible = not aviso.text.is_empty()


# Con dominios cargados, una orden se abre si su dificultad está al alcance de la competencia.
func bloqueada(orden: Dictionary) -> bool:
	if dominios.is_empty():
		return false
	return not Niveles.desbloqueada(orden.dificultad, dominios.get(orden.get("competencia_id", ""), 0.0))


func agregar_filtro(etiqueta: String, fg: String, seleccion: ButtonGroup) -> Button:
	var boton := Button.new()
	boton.text = etiqueta
	boton.theme_type_variation = &"FiltroOrden"
	boton.add_theme_font_size_override("font_size", 14)
	boton.add_theme_stylebox_override("pressed", fondo_chip(TURQUESA[0].darkened(0.08)))
	boton.add_theme_stylebox_override("hover_pressed", boton.get_theme_stylebox("pressed"))
	boton.custom_minimum_size = Vector2(76, 36)
	boton.toggle_mode = true
	boton.button_group = seleccion
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton.pressed.connect(aplicar_filtro.bind(fg))
	filtros.add_child(boton)
	return boton


func aplicar_filtro(fg: String) -> void:
	limpiar_contenedor(tarjetas)
	for dificultad: String in DIFICULTADES:
		var ordenes := catalogo.filter(func(orden: Dictionary) -> bool:
			return orden.dificultad == dificultad and (fg.is_empty() or orden.get("grupo_funcion") == fg))
		if ordenes.is_empty():
			continue
		var seccion := VBoxContainer.new()
		seccion.name = dificultad
		tarjetas.add_child(seccion)
		var encabezado := HBoxContainer.new()
		seccion.add_child(encabezado)
		encabezado.add_child(chip(DIFICULTADES[dificultad], COLORES[dificultad], 16))
		var cantidad := "1 orden" if ordenes.size() == 1 else "%d órdenes" % ordenes.size()
		encabezado.add_child(texto(cantidad, &"DetalleClaro", 14))
		var rejilla := GridContainer.new()
		rejilla.add_theme_constant_override("h_separation", SEPARACION)
		rejilla.add_theme_constant_override("v_separation", SEPARACION)
		seccion.add_child(rejilla)
		for orden in ordenes:
			rejilla.add_child(crear_tarjeta(orden))
	ajustar_columnas()


func ajustar_columnas() -> void:
	queue_redraw()
	var ancho := clampf(size.x - 40, ANCHO_TARJETA, 1152)
	columna.custom_minimum_size.x = ancho
	var columnas := clampi(floori((ancho + SEPARACION) / (ANCHO_TARJETA + SEPARACION)), 1, 4)
	var ancho_celda := floorf((ancho - SEPARACION * (columnas - 1)) / columnas)
	for seccion in tarjetas.get_children():
		var rejilla: GridContainer = seccion.get_child(1)
		rejilla.columns = columnas
		for tarjeta in rejilla.get_children():
			tarjeta.custom_minimum_size.x = ancho_celda


func crear_tarjeta(orden: Dictionary) -> Button:
	var tarjeta := Button.new()
	tarjeta.theme_type_variation = &"BotonOrden"
	tarjeta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cerrada := bloqueada(orden)
	tarjeta.disabled = cerrada
	tarjeta.pressed.connect(func(): orden_elegida.emit(orden.archivo))

	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	tarjeta.add_child(margen)
	var contenido := VBoxContainer.new()
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_theme_constant_override("separation", 3)
	margen.add_child(contenido)

	var etiquetas := HBoxContainer.new()
	etiquetas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiquetas.add_theme_constant_override("separation", 5)
	contenido.add_child(etiquetas)
	etiquetas.add_child(chip(DIFICULTADES[orden.dificultad], COLORES[orden.dificultad]))
	var fg := numero_fg(orden.get("grupo_funcion"))
	if fg >= 0:
		etiquetas.add_child(chip("FG %d" % fg, TURQUESA))
	var marca: String = orden.get("marca", TextoLimpio.limpiar(orden.titulo).etiqueta)
	for etiqueta in marca.split(" · ", false):
		etiquetas.add_child(chip(etiqueta, AZUL))

	var titulo := texto(titulo_limpio(orden), &"TituloClaro", 20)
	titulo.name = "Titulo"
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(titulo)
	var zona: String = ZONAS.get(orden.zona, orden.zona)
	var competencia: String = orden.competencia
	contenido.add_child(texto(zona, &"DetalleClaro", 14))
	contenido.add_child(texto(competencia, &"DetalleClaro", 14))

	var pie := HBoxContainer.new()
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(pie)
	var misiones := "Misiones: %d" % orden.get("misiones", 0)
	pie.add_child(texto(misiones, &"DetalleClaro", 14))
	var resuelta := resueltas.has(orden.get("id", ""))
	if resuelta:
		pie.add_child(chip("Resuelta", VERDE))
	var motivo := ""
	if cerrada:
		motivo = Niveles.motivo(orden.dificultad, dominios.get(orden.competencia_id, 0.0), competencia)
		pie.add_child(chip("Bloqueada", [Color("#E3E7EA"), Color("#46525A")]))
		var nota := texto(motivo, &"DetalleClaro", 14)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contenido.add_child(nota)
		contenido.modulate.a = 0.72
		tarjeta.tooltip_text = motivo

	tarjeta.accessibility_name = titulo.text
	var detalles := PackedStringArray()
	for etiqueta in etiquetas.get_children():
		detalles.append(etiqueta.text)
	detalles.append_array([zona, competencia, misiones])
	if resuelta:
		detalles.append("Resuelta")
	if cerrada:
		detalles.append("Bloqueada. " + motivo)
	tarjeta.accessibility_description = " · ".join(detalles)
	margen.minimum_size_changed.connect(func():
		tarjeta.custom_minimum_size.y = margen.get_combined_minimum_size().y)
	tarjeta.custom_minimum_size.y = margen.get_combined_minimum_size().y
	return tarjeta


func _unhandled_input(evento: InputEvent) -> void:
	if not evento is InputEventJoypadButton or not evento.is_pressed():
		return
	var foco := get_viewport().gui_get_focus_owner()
	if foco == null or not is_ancestor_of(foco):
		return
	var lados := {JOY_BUTTON_DPAD_UP: SIDE_TOP, JOY_BUTTON_DPAD_DOWN: SIDE_BOTTOM,
		JOY_BUTTON_DPAD_LEFT: SIDE_LEFT, JOY_BUTTON_DPAD_RIGHT: SIDE_RIGHT}
	if lados.has(evento.button_index):
		var vecino := foco.find_valid_focus_neighbor(lados[evento.button_index])
		if vecino != null:
			vecino.grab_focus()
			get_viewport().set_input_as_handled()


func chip(etiqueta: String, colores: Array, puntos := 12) -> Label:
	var insignia := texto(etiqueta, &"Insignia", puntos)
	insignia.add_theme_color_override("font_color", colores[1])
	insignia.add_theme_stylebox_override("normal", fondo_chip(colores[0]))
	return insignia


func fondo_chip(color: Color) -> StyleBoxFlat:
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = color
	fondo.set_corner_radius_all(10)
	fondo.content_margin_left = 7
	fondo.content_margin_right = 7
	fondo.content_margin_top = 2
	fondo.content_margin_bottom = 2
	return fondo


func texto(etiqueta: String, estilo: StringName, puntos: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = etiqueta
	rotulo.theme_type_variation = estilo
	rotulo.add_theme_font_size_override("font_size", puntos)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


func titulo_limpio(orden: Dictionary) -> String:
	return TextoLimpio.limpiar(orden.titulo).texto


func numero_fg(grupo: Variant) -> int:
	if grupo is String and grupo.begins_with("FG") and grupo.substr(2).is_valid_int():
		return int(grupo.substr(2))
	return -1


func limpiar_contenedor(contenedor: Container) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
