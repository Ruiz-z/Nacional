extends VBoxContainer

signal nodo_activado(nodo: Dictionary, tipo: String, boton: Button)

const OSCURO := Color("#0E1A22")
const CLARO := Color("#ECFAFA")
const NEUTRO := Color("#5B7480")
const FONDO := Color("#1A2327")
const ACENTO := Color("#1AA7A6")
const PETROLEO := Color("#185275")
const PELIGRO := Color("#D64545")
const CAMINO := Color(0.92549, 0.98039, 0.98039, 0.7)
const ESTADOS := {
	"Primero": Color("#F2B705"),
	"Hoy": ACENTO,
	"Después": CLARO,
	"Hecho": Color("#3FAE6A"),
}
const SEPARACION := 56
const LIMITE_FICHAS := 3

var filas := VBoxContainer.new()
var conexiones: Array[Dictionary] = []


class MarcaHecho extends Control:
	func _draw() -> void:
		var punto := Vector2(size.x - 28, (size.y - 6) / 2.0)
		draw_polyline(PackedVector2Array([punto + Vector2(-8, 0),
			punto + Vector2(-2, 6), punto + Vector2(9, -6)]), OSCURO, 3.0, true)


func _ready() -> void:
	add_child(filas)


func mostrar(nodos: Array, origen: String, fuentes: Array, detalles: Dictionary) -> void:
	for hijo in get_children():
		if hijo != filas:
			remove_child(hijo)
			hijo.queue_free()
	for fila in filas.get_children():
		filas.remove_child(fila)
		fila.queue_free()
	conexiones.clear()
	if nodos.is_empty():
		hide()
		return

	add_theme_constant_override("separation", 20)
	agregar_cabecera(nodos[0].nombre, origen, fuentes)
	filas.add_theme_constant_override("separation", 36)

	for indice in nodos.size():
		var nodo: Dictionary = nodos[indice]
		var fila := HBoxContainer.new()
		fila.custom_minimum_size.y = 116
		fila.add_theme_constant_override("separation", SEPARACION)
		filas.add_child(fila)
		var izquierda := columna(fila, true)
		var medio := columna(fila, false)
		var derecha := columna(fila, true)
		var datos := nodo.duplicate()
		if detalles.has(nodo.competencia) and not fuentes.is_empty():
			datos.fuente_propuesta = "Fuente: %s" % ", ".join(fuentes)
		if indice == 0:
			var inicio := etiqueta("Empieza aquí", 16, &"Seccion")
			inicio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			inicio.add_theme_color_override("font_color", ESTADOS.Primero)
			medio.add_child(inicio)
		var centro := competencia(medio, datos, indice + 1)

		var errores: Array[Dictionary] = []
		for error in nodo.errores:
			var texto: String = error.nombre
			if error.conteo > 0:
				texto += " · %d" % error.conteo
			var critica: bool = error.tipo_error == "falta-critica"
			var ficha_error := {"texto": texto, "datos": error, "tipo": "error",
				"borde": PELIGRO if critica else NEUTRO,
				"tinta": CLARO if error.conteo > 0 else CLARO.darkened(0.24)}
			if critica:
				errores.push_front(ficha_error)
			else:
				errores.append(ficha_error)

		var practica: Array[Dictionary] = []
		for tema in nodo.temas:
			practica.append({"texto": tema.titulo, "datos": tema, "tipo": "tema"})
		for orden in nodo.ordenes:
			practica.append({"texto": orden.titulo, "datos": orden, "tipo": "orden"})

		conexiones.append({"centro": centro,
			"izquierda": fichas(izquierda, errores, datos, FONDO, NEUTRO),
			"derecha": fichas(derecha, practica, datos, PETROLEO, ACENTO)})
	show()
	queue_redraw()


func agregar_cabecera(nombre: String, origen: String, fuentes: Array) -> void:
	var cabecera := VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 4)
	add_child(cabecera)
	move_child(cabecera, 0)
	cabecera.add_child(etiqueta("Tu ruta", 36, &"Titulo"))
	cabecera.add_child(etiqueta("Empieza por %s." % (nombre.left(1).to_lower() + nombre.substr(1)), 20))
	var referencias := PackedStringArray()
	for fuente in fuentes:
		if not fuente.to_lower().contains("ejemplo didáctico"):
			referencias.append(fuente)
	var base := "tu diagnóstico" if referencias.is_empty() else ", ".join(referencias)
	var nota := "Generada con IA · basada en: %s" % base if origen == "ia" else "Calculada sin IA"
	cabecera.add_child(etiqueta(nota, 14, &"Secundario"))
	var leyenda := HBoxContainer.new()
	leyenda.add_theme_constant_override("separation", 8)
	cabecera.add_child(leyenda)
	for estado in ESTADOS:
		var ficha := PanelContainer.new()
		var estilo := plano(ESTADOS[estado], OSCURO, 0)
		estilo.content_margin_left = 12
		estilo.content_margin_right = 12
		estilo.content_margin_top = 2
		estilo.content_margin_bottom = 2
		ficha.add_theme_stylebox_override("panel", estilo)
		leyenda.add_child(ficha)
		var texto := etiqueta(estado, 14, &"Seccion", OSCURO)
		texto.autowrap_mode = TextServer.AUTOWRAP_OFF
		ficha.add_child(texto)
	var pista := etiqueta("Toca un nodo para ver el detalle", 16, &"Secundario")
	pista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leyenda.add_child(pista)


func columna(fila: HBoxContainer, lateral: bool) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.custom_minimum_size.x = 274 if lateral else 360
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL if lateral else Control.SIZE_FILL
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_theme_constant_override("separation", 4)
	fila.add_child(caja)
	return caja


func competencia(caja: VBoxContainer, nodo: Dictionary, numero: int) -> PanelContainer:
	var estado: String = nodo.estado
	var panel := tarjeta(caja, nodo, "competencia", OSCURO, ESTADOS[estado], 88)
	var boton := panel.get_child(0) as Button
	boton.accessibility_name = nodo.nombre
	boton.accessibility_description = "%s · dominio %d %%" % [estado, nodo.dominio]

	var renglon := HBoxContainer.new()
	renglon.add_theme_constant_override("separation", 12)
	var interior := margen(panel, renglon, 12, 10, 12 if estado != "Hecho" else 46, 16)
	interior.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var placa := PanelContainer.new()
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.custom_minimum_size = Vector2(40, 40)
	placa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	placa.add_theme_stylebox_override("panel", plano(OSCURO, OSCURO, 0))
	renglon.add_child(placa)
	var indice := etiqueta(str(numero), 22, &"Seccion")
	indice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placa.add_child(indice)

	var textos := VBoxContainer.new()
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	renglon.add_child(textos)
	textos.add_child(etiqueta(nodo.nombre, 22, &"Seccion", OSCURO))
	textos.add_child(etiqueta(boton.accessibility_description, 16, &"", OSCURO))

	var base := ColorRect.new()
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.custom_minimum_size.y = 6
	base.color = Color(OSCURO, 0.22)
	margen(panel, base, 12, 0, 12, 8).size_flags_vertical = Control.SIZE_SHRINK_END
	var relleno := ColorRect.new()
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relleno.color = OSCURO
	base.add_child(relleno)
	relleno.set_anchor(SIDE_RIGHT, clampf(nodo.dominio / 100.0, 0.0, 1.0))
	relleno.set_anchor(SIDE_BOTTOM, 1.0)

	if estado == "Hecho":
		var marca := MarcaHecho.new()
		marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marca.resized.connect(marca.queue_redraw)
		panel.add_child(marca)
	return panel


func fichas(caja: VBoxContainer, elementos: Array[Dictionary], nodo: Dictionary,
		fondo: Color, borde: Color) -> Array[Control]:
	var visibles: Array[Control] = []
	for elemento in elementos.slice(0, LIMITE_FICHAS):
		visibles.append(ficha(caja, elemento.texto, elemento.datos.merged({"estado": nodo.estado}),
			elemento.tipo, fondo, elemento.get("borde", borde), elemento.get("tinta", CLARO)))
	if elementos.size() > LIMITE_FICHAS:
		visibles.append(ficha(caja, "+%d más" % (elementos.size() - LIMITE_FICHAS),
			nodo, "competencia", fondo, borde, CLARO))
	return visibles


func ficha(caja: VBoxContainer, texto: String, datos: Dictionary, tipo: String,
		fondo: Color, borde: Color, tinta: Color) -> PanelContainer:
	var panel := tarjeta(caja, datos, tipo, borde, fondo, 30)
	var boton := panel.get_child(0) as Button
	boton.accessibility_name = texto
	if tipo == "competencia":
		boton.accessibility_description = datos.nombre
	boton.tooltip_text = texto
	var rotulo := etiqueta(texto, 16, &"", tinta)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	rotulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	margen(panel, rotulo, 12, 3, 12, 3)
	return panel


func tarjeta(caja: VBoxContainer, nodo: Dictionary, tipo: String, borde: Color, fondo: Color,
		alto: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = alto
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.item_rect_changed.connect(queue_redraw)
	caja.add_child(panel)
	var boton := Button.new()
	estilizar_boton(boton, fondo, borde)
	boton.pressed.connect(func(): nodo_activado.emit(nodo, tipo, boton))
	panel.add_child(boton)
	return panel


static func plano(fondo: Color, borde: Color, ancho: int = 2) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(ancho)
	estilo.set_corner_radius_all(3)
	return estilo


static func estilizar_boton(boton: Button, fondo: Color, borde: Color, tinta: Color = CLARO) -> void:
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton.add_theme_stylebox_override("normal", plano(fondo, borde))
	boton.add_theme_stylebox_override("hover", plano(fondo.lightened(0.15), borde))
	var pulsado := plano(fondo.darkened(0.08), borde)
	boton.add_theme_stylebox_override("pressed", pulsado)
	boton.add_theme_stylebox_override("hover_pressed", pulsado)
	var foco := plano(fondo, Color.WHITE, 3)
	foco.draw_center = false
	boton.add_theme_stylebox_override("focus", foco)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		boton.add_theme_color_override(estado, tinta)
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		var estilo := boton.get_theme_stylebox(estado)
		estilo.content_margin_left = 14
		estilo.content_margin_right = 14
	boton.add_theme_constant_override("outline_size", 0)


func margen(panel: PanelContainer, hijo: Control, izquierda: int, arriba: int, derecha: int, abajo: int) -> MarginContainer:
	var interior := MarginContainer.new()
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.add_theme_constant_override("margin_left", izquierda)
	interior.add_theme_constant_override("margin_top", arriba)
	interior.add_theme_constant_override("margin_right", derecha)
	interior.add_theme_constant_override("margin_bottom", abajo)
	panel.add_child(interior)
	interior.add_child(hijo)
	return interior


func etiqueta(texto: String, puntos: int, variante: StringName = &"", tinta: Color = CLARO) -> Label:
	var rotulo := Label.new()
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.text = texto
	rotulo.theme_type_variation = variante
	rotulo.add_theme_font_size_override("font_size", puntos)
	if variante != &"Secundario":
		rotulo.add_theme_color_override("font_color", tinta)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return rotulo


func _draw() -> void:
	var anterior := Vector2.ZERO
	for conexion in conexiones:
		var centro: Control = conexion.centro
		var caja := Rect2(centro.global_position - global_position, centro.size)
		var eje := caja.get_center()
		if anterior != Vector2.ZERO:
			var punta := Vector2(eje.x, caja.position.y - 4)
			draw_line(anterior, punta - Vector2(0, 7), CAMINO, 4.0)
			draw_colored_polygon(PackedVector2Array([punta, punta + Vector2(-7, -10),
				punta + Vector2(7, -10)]), CAMINO)
		anterior = Vector2(eje.x, caja.end.y)
		dibujar_ramas(Vector2(caja.position.x, eje.y), conexion.izquierda, -1)
		dibujar_ramas(Vector2(caja.end.x, eje.y), conexion.derecha, 1)


func dibujar_ramas(origen: Vector2, ramas: Array[Control], lado: int) -> void:
	if ramas.is_empty():
		return
	var cruce := origen + Vector2(lado * SEPARACION / 2.0, 0)
	var desde := cruce.y
	var hasta := cruce.y
	for rama in ramas:
		var extremo := rama.global_position - global_position + Vector2(
			rama.size.x if lado < 0 else 0.0, rama.size.y / 2.0)
		desde = minf(desde, extremo.y)
		hasta = maxf(hasta, extremo.y)
		draw_line(Vector2(cruce.x, extremo.y), extremo, NEUTRO, 2.0)
	draw_line(origen, cruce, NEUTRO, 2.0)
	if hasta > desde:
		draw_line(Vector2(cruce.x, desde), Vector2(cruce.x, hasta), NEUTRO, 2.0)
