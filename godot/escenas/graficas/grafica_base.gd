extends Control

const FUENTE = preload("res://assets/fuentes/Poppins-Regular.ttf")
const FONDO := Color("#1a2327")
const TEXTO := Color("#eff7f7")
const SUAVE := Color("#b9c9ce")
const REJILLA := Color("#415358")
const ACENTO := Color("#1aa7a6")
const SERIES := [Color("#3987e5"), Color("#d95926"), Color("#199e70"), Color("#c98500")]
const TONOS := [Color("#78cece"), ACENTO, Color("#268788"), Color("#286d74")]
const TAM := 14

var datos: Dictionary = {}:
	set(nuevos):
		datos = nuevos
		seleccion = -1
		actualizar_descripcion()
		update_minimum_size()
		queue_redraw()
var marcas: Array[Dictionary] = []
var seleccion := -1
var rotulos: Array[Rect2] = []
var texto_fuera := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Consulta el valor de cada marca."
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)


func actualizar_descripcion() -> void:
	accessibility_name = datos.get("titulo", "")
	accessibility_description = datos.get("lectura", "") + " Usa las flechas para recorrer los valores o abre la tabla."


func _draw() -> void:
	marcas.clear()
	rotulos.clear()
	texto_fuera = false
	if datos.is_empty():
		return
	dibujar()
	if has_focus():
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), ACENTO, false, 1)
		if seleccion >= 0 and seleccion < marcas.size():
			draw_rect(marcas[seleccion].rect.grow(2), TEXTO, false, 2)


func dibujar() -> void:
	pass


func _gui_input(evento: InputEvent) -> void:
	if marcas.is_empty():
		return
	if evento.is_action_pressed("ui_right") or evento.is_action_pressed("ui_down"):
		seleccion = posmod(seleccion + 1, marcas.size())
	elif evento.is_action_pressed("ui_left") or evento.is_action_pressed("ui_up"):
		seleccion = posmod((0 if seleccion < 0 else seleccion) - 1, marcas.size())
	else:
		return
	accessibility_description = marcas[seleccion].texto
	mostrar_marca(marcas[seleccion].rect)
	queue_redraw()
	accept_event()


func mostrar_marca(marca_local: Rect2) -> void:
	var ancestro := get_parent()
	while ancestro != null and not ancestro is ScrollContainer:
		ancestro = ancestro.get_parent()
	if ancestro is ScrollContainer:
		var vista: Rect2 = ancestro.get_global_rect().grow(-4)
		var rect := marca_local.grow(4)
		rect.position += global_position
		if rect.end.y > vista.end.y:
			ancestro.scroll_vertical += ceili(rect.end.y - vista.end.y)
		elif rect.position.y < vista.position.y:
			ancestro.scroll_vertical -= ceili(vista.position.y - rect.position.y)


func _get_tooltip(punto: Vector2) -> String:
	var cercana := ""
	var distancia := INF
	for marca in marcas:
		if marca.rect.has_point(punto):
			var actual: float = punto.distance_squared_to(marca.rect.get_center())
			if actual < distancia:
				distancia = actual
				cercana = marca.texto
	return cercana


func marca(rect: Rect2, fila: Dictionary, columna: int) -> void:
	var texto := "%s · %s · %s" % [fila.nombre, datos.columnas[columna],
		valor_visible(fila.valores[columna], datos.get("unidad", ""))]
	if not fila.detalle.is_empty():
		texto += " · " + fila.detalle
	marcas.append({"rect": rect, "texto": texto})


static func valor_visible(valor: Variant, unidad: String = "") -> String:
	if valor == null:
		return "Sin datos"
	var cifra := str(int(valor)) if is_equal_approx(float(valor), float(roundi(valor))) else "%.1f" % valor
	return cifra + unidad


func rotulo(texto: String, zona: Rect2, color: Color = TEXTO,
		alineacion: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var mostrado := texto
	if FUENTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM).x > zona.size.x:
		# El texto completo queda disponible en la marca y en la tabla.
		while not mostrado.is_empty() and FUENTE.get_string_size(mostrado + "…",
				HORIZONTAL_ALIGNMENT_LEFT, -1, TAM).x > zona.size.x:
			mostrado = mostrado.left(-1)
		mostrado += "…"
	var ascenso := FUENTE.get_ascent(TAM)
	var base := zona.position.y + (zona.size.y - FUENTE.get_height(TAM)) * 0.5 + ascenso
	if not Rect2(Vector2.ZERO, size).grow(0.5).encloses(zona):
		texto_fuera = true
	var ancho := FUENTE.get_string_size(mostrado, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM).x
	var x := zona.position.x
	if alineacion == HORIZONTAL_ALIGNMENT_CENTER:
		x += (zona.size.x - ancho) * 0.5
	elif alineacion == HORIZONTAL_ALIGNMENT_RIGHT:
		x += zona.size.x - ancho
	rotulos.append(Rect2(x, base - ascenso, ancho, FUENTE.get_height(TAM)))
	draw_string(FUENTE, Vector2(zona.position.x, base), mostrado, alineacion, zona.size.x, TAM, color)


func barra(rect: Rect2, color: Color, radio: int = 4) -> void:
	if rect.size.x <= 0:
		return
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.corner_radius_top_right = radio
	estilo.corner_radius_bottom_right = radio
	estilo.anti_aliasing = false
	draw_style_box(estilo, rect)


func punto(centro: Vector2, color: Color) -> void:
	draw_circle(centro, 6, FONDO, true, -1, true)
	draw_circle(centro, 4, color, true, -1, true)


func respeta_limites() -> bool:
	var limite := Rect2(Vector2.ZERO, size).grow(0.5)
	if not marcas.all(func(dato: Dictionary) -> bool: return limite.encloses(dato.rect)):
		return false
	for i in rotulos.size():
		if not limite.encloses(rotulos[i]):
			return false
		for j in range(i):
			if rotulos[i].intersects(rotulos[j]):
				return false
	return true
