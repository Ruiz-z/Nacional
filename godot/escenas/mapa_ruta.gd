extends Control

const NEUTRO := Color("#5B7480")
const FONDO := Color("#1A2327")
const ACENTO := Color("#1AA7A6")
const CRITICA := Color("#F2B705")
const SEPARACION := 40

var filas := VBoxContainer.new()
var conexiones: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(filas)
	filas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filas.add_theme_constant_override("separation", 26)
	filas.minimum_size_changed.connect(func():
		custom_minimum_size.y = filas.get_combined_minimum_size().y)


func mostrar(nodos: Array, fuentes: Array, detalles: Dictionary) -> void:
	for fila in filas.get_children():
		filas.remove_child(fila)
		fila.queue_free()
	conexiones.clear()
	if nodos.is_empty():
		hide()
		return

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", SEPARACION)
	filas.add_child(cabecera)
	for texto in ["Qué falló", "Competencia", "Qué practicar"]:
		var rotulo := etiqueta(texto, 16, &"Seccion")
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cabecera.add_child(rotulo)

	for nodo in nodos:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", SEPARACION)
		filas.add_child(fila)
		var izquierda := columna(fila)
		var medio := columna(fila)
		var derecha := columna(fila)
		var borde := NEUTRO
		var fondo := FONDO
		match nodo.estado:
			"Primero":
				borde = CRITICA
				fondo = Color("#332A1B")
			"Hoy":
				borde = ACENTO
				fondo = Color("#163739")
			"Hecho":
				fondo = Color("#0E1A22")
		var centro := tarjeta(medio, borde, fondo)
		centro.add_child(etiqueta(nodo.nombre, 20, &"Seccion"))
		centro.add_child(etiqueta("%s  ·  %d %%" % [nodo.estado, nodo.dominio], 16, &"Secundario"))
		if detalles.has(nodo.competencia) and not fuentes.is_empty():
			var nota := tarjeta(medio)
			nota.add_child(etiqueta("Fuente: %s" % ", ".join(fuentes), 13, &"Secundario"))

		var ramas_izquierda: Array[Control] = []
		for error in nodo.errores:
			var rama := tarjeta(izquierda)
			var texto: String = error.nombre
			if error.conteo > 0:
				texto += " · %d" % error.conteo
			rama.add_child(etiqueta(texto, 16, &"Secundario" if error.conteo == 0 else &""))
			ramas_izquierda.append(rama.get_parent())

		var ramas_derecha: Array[Control] = []
		for orden in nodo.ordenes:
			var rama := tarjeta(derecha)
			rama.add_child(etiqueta(orden.titulo, 16))
			if not orden.get("marca", "").is_empty():
				rama.add_child(etiqueta(orden.marca, 13, &"Secundario"))
			ramas_derecha.append(rama.get_parent())
		if not nodo.refuerzo.is_empty():
			var rama := tarjeta(derecha)
			rama.add_child(etiqueta(nodo.refuerzo, 15, &"Secundario"))
			ramas_derecha.append(rama.get_parent())
		elif ramas_derecha.is_empty():
			var rama := tarjeta(derecha)
			rama.add_child(etiqueta("Sin órdenes sugeridas", 16, &"Secundario"))
			ramas_derecha.append(rama.get_parent())

		conexiones.append({"centro": centro.get_parent(), "izquierda": ramas_izquierda,
			"derecha": ramas_derecha})
	show()
	queue_redraw()


func columna(fila: HBoxContainer) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_theme_constant_override("separation", 8)
	fila.add_child(caja)
	return caja


func tarjeta(columna_nodo: VBoxContainer, borde: Color = NEUTRO, fondo: Color = FONDO) -> VBoxContainer:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", estilo)
	panel.item_rect_changed.connect(queue_redraw)
	columna_nodo.add_child(panel)
	var texto := VBoxContainer.new()
	texto.add_theme_constant_override("separation", 2)
	panel.add_child(texto)
	return texto


func etiqueta(texto: String, puntos: int, variante: StringName = &"") -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = variante
	rotulo.add_theme_font_size_override("font_size", puntos)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return rotulo


func _draw() -> void:
	var anterior := Vector2.ZERO
	for conexion in conexiones:
		var centro: Control = conexion.centro
		var caja := Rect2(centro.global_position - global_position, centro.size)
		var eje := caja.get_center()
		if anterior != Vector2.ZERO:
			draw_line(anterior, Vector2(eje.x, caja.position.y), NEUTRO, 4.0)
		anterior = Vector2(eje.x, caja.end.y)
		dibujar_ramas(Vector2(caja.position.x, eje.y), conexion.izquierda, -1)
		dibujar_ramas(Vector2(caja.end.x, eje.y), conexion.derecha, 1)


func dibujar_ramas(origen: Vector2, ramas: Array[Control], lado: int) -> void:
	var cruce := origen + Vector2(lado * SEPARACION / 2.0, 0)
	var desde := cruce.y
	var hasta := cruce.y
	for rama in ramas:
		var extremo := rama.global_position - global_position + Vector2(
			rama.size.x if lado < 0 else 0.0, rama.size.y / 2.0)
		desde = minf(desde, extremo.y)
		hasta = maxf(hasta, extremo.y)
		draw_dashed_line(Vector2(cruce.x, extremo.y), extremo, NEUTRO, 2.0, 5.0)
	draw_dashed_line(origen, cruce, NEUTRO, 2.0, 5.0)
	if hasta > desde:
		draw_dashed_line(Vector2(cruce.x, desde), Vector2(cruce.x, hasta), NEUTRO, 2.0, 5.0)
