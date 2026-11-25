extends Control

signal nodo_activado(nodo: Dictionary, tipo: String, boton: Button)

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
		var centro := tarjeta(medio, nodo, "competencia", borde, fondo)
		centro.add_child(etiqueta(nodo.nombre, 20, &"Seccion"))
		centro.add_child(etiqueta("%s  ·  %d %%" % [nodo.estado, nodo.dominio], 16, &"Secundario"))
		if detalles.has(nodo.competencia) and not fuentes.is_empty():
			var texto_fuente := "Fuente: %s" % ", ".join(fuentes)
			var nota := tarjeta(medio, nodo.merged({"fuente_propuesta": texto_fuente}), "competencia")
			nota.add_child(etiqueta(texto_fuente, 13, &"Secundario"))

		var ramas_izquierda: Array[Control] = []
		for error in nodo.errores:
			var rama := tarjeta(izquierda, error, "error")
			var texto: String = error.nombre
			if error.conteo > 0:
				texto += " · %d" % error.conteo
			rama.add_child(etiqueta(texto, 16, &"Secundario" if error.conteo == 0 else &""))
			ramas_izquierda.append(izquierda.get_child(-1))

		var ramas_derecha: Array[Control] = []
		for tema in nodo.temas:
			var rama := tarjeta(derecha, tema, "tema")
			rama.add_child(etiqueta(tema.titulo, 16))
			rama.add_child(etiqueta("Fuente: %s" % tema.fuente.trim_suffix(".pdf"), 13, &"Secundario"))
			ramas_derecha.append(derecha.get_child(-1))
		for orden in nodo.ordenes:
			var rama := tarjeta(derecha, orden, "orden")
			rama.add_child(etiqueta(orden.titulo, 16))
			if not orden.get("marca", "").is_empty():
				rama.add_child(etiqueta(orden.marca, 13, &"Secundario"))
			ramas_derecha.append(derecha.get_child(-1))
		if not nodo.refuerzo.is_empty():
			var rama := tarjeta(derecha, nodo, "competencia")
			rama.add_child(etiqueta(nodo.refuerzo, 15, &"Secundario"))
			ramas_derecha.append(derecha.get_child(-1))
		elif ramas_derecha.is_empty():
			var rama := tarjeta(derecha, nodo, "competencia")
			rama.add_child(etiqueta("Sin órdenes sugeridas", 16, &"Secundario"))
			ramas_derecha.append(derecha.get_child(-1))

		conexiones.append({"centro": medio.get_child(0), "izquierda": ramas_izquierda,
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


func tarjeta(columna_nodo: VBoxContainer, nodo: Dictionary, tipo: String, borde: Color = NEUTRO, fondo: Color = FONDO) -> VBoxContainer:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.item_rect_changed.connect(queue_redraw)
	columna_nodo.add_child(panel)

	var boton := Button.new()
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton.add_theme_stylebox_override("normal", estilo)
	var resaltado := estilo.duplicate() as StyleBoxFlat
	resaltado.bg_color = fondo.lightened(0.10)
	resaltado.border_color = Color("#87D8D7")
	boton.add_theme_stylebox_override("hover", resaltado)
	boton.add_theme_stylebox_override("pressed", resaltado)
	var foco := estilo.duplicate() as StyleBoxFlat
	foco.draw_center = false
	foco.border_color = Color("#F4F7F7")
	foco.set_border_width_all(3)
	boton.add_theme_stylebox_override("focus", foco)
	boton.pressed.connect(func(): nodo_activado.emit(nodo, tipo, boton))
	panel.add_child(boton)

	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12 if lado in ["left", "right"] else 8)
	panel.add_child(margen)
	var texto := VBoxContainer.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.add_theme_constant_override("separation", 2)
	margen.add_child(texto)
	texto.child_entered_tree.connect(func(hijo: Node):
		if hijo is Label:
			if boton.accessibility_name.is_empty():
				boton.accessibility_name = hijo.text
			else:
				boton.accessibility_description = hijo.text)
	return texto


func etiqueta(texto: String, puntos: int, variante: StringName = &"") -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
