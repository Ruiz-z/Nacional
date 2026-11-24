extends VBoxContainer

const ACENTO := Color("#72F5ED")
const SECUNDARIO := Color("#C0DBE7")
const FUENTE_TITULO = preload("res://assets/fuentes/Poppins-SemiBold.ttf")

var indice := -1
var celebrando := false
var mostrando_detalle := true
var animacion: Tween
var progreso: Array = []
var filas: Array = []
var pista := ""
var destello := 0.0
var contador: Label
var marca: Label
var titulo: Label
var detalle: VBoxContainer
var puntos: Control
var lista: VBoxContainer
var ayuda: Label
var celebracion: HBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var cabecera := HBoxContainer.new()
	add_child(cabecera)
	contador = etiqueta(cabecera, 14, ACENTO, true)
	contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marca = Label.new()
	marca.theme_type_variation = &"ChipOrden"
	cabecera.add_child(marca)
	titulo = etiqueta(self, 28, Color.WHITE, true)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle = VBoxContainer.new()
	detalle.add_theme_constant_override("separation", 8)
	add_child(detalle)
	puntos = Control.new()
	puntos.custom_minimum_size.y = 18
	puntos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detalle.add_child(puntos)
	puntos.draw.connect(dibujar_puntos)
	lista = VBoxContainer.new()
	lista.add_theme_constant_override("separation", 4)
	detalle.add_child(lista)
	ayuda = etiqueta(detalle, 15, SECUNDARIO)
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	celebracion = HBoxContainer.new()
	detalle.add_child(celebracion)
	var marca_cumplida := Control.new()
	marca_cumplida.custom_minimum_size = Vector2(26, 26)
	celebracion.add_child(marca_cumplida)
	marca_cumplida.draw.connect(func():
		marca_cumplida.draw_polyline(PackedVector2Array([
			Vector2(3, 14), Vector2(9, 20), Vector2(22, 7)]), ACENTO, 3.0, true))
	etiqueta(celebracion, 20, ACENTO, true).text = "Misión cumplida"
	celebracion.hide()


func etiqueta(contenedor: Container, tamano: int, color: Color, seminegrita := false) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_size_override("font_size", tamano)
	rotulo.add_theme_color_override("font_color", color)
	if seminegrita:
		rotulo.add_theme_font_override("font", FUENTE_TITULO)
	contenedor.add_child(rotulo)
	return rotulo


func mostrar(numero: int, nombre: String, estados: Array, subpasos: Array, texto_pista: String) -> void:
	indice = numero
	contador.text = "MISIÓN %d DE %d" % [indice + 1, estados.size()]
	titulo.text = nombre
	progreso = estados
	puntos.queue_redraw()
	if filas == subpasos and pista == texto_pista:
		return
	filas = subpasos
	pista = texto_pista
	for nodo in lista.get_children():
		lista.remove_child(nodo)
		nodo.queue_free()
	var primero := true
	for fila in filas:
		var renglon := HBoxContainer.new()
		lista.add_child(renglon)
		var color := SECUNDARIO if fila.hecho or not primero else Color.WHITE
		if fila.hecho:
			color = Color("#A9CBD8")
		etiqueta(renglon, 18, color).text = "[x]" if fila.hecho else "[ ]"
		var rotulo := etiqueta(renglon, 18, color)
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rotulo.text = fila.texto
		primero = primero and fila.hecho
	ayuda.text = pista
	actualizar_visibilidad()


func actualizar_visibilidad() -> void:
	detalle.visible = mostrando_detalle
	marca.visible = mostrando_detalle and not marca.text.is_empty()
	celebracion.visible = celebrando
	ayuda.visible = not celebrando and not pista.is_empty()


func celebrar(estados: Array, terminar: Callable) -> void:
	if animacion != null:
		animacion.kill()
	modulate.a = 1.0
	# Conserva a la vista la confirmación mientras se celebra el indicio.
	var completadas: Array = filas.map(func(fila: Dictionary):
		return {"texto": fila.texto, "hecho": true})
	mostrar(indice, titulo.text, estados, completadas, pista)
	celebrando = true
	progreso = estados
	puntos.queue_redraw()
	actualizar_visibilidad()
	destello = 0.38
	animacion = create_tween()
	animacion.tween_method(func(valor: float): destello = valor, destello, 0.0, 1.2)
	animacion.tween_callback(func():
		celebrando = false
		actualizar_visibilidad()
		terminar.call())


func entrada() -> void:
	# El contenedor conserva su tamaño mientras el texto entra desde la izquierda.
	var destino := position
	position.x -= 12
	modulate.a = 0.0
	animacion = create_tween().set_parallel()
	animacion.tween_property(self, "position:x", destino.x, 0.2).from(destino.x - 12)
	animacion.tween_property(self, "modulate:a", 1.0, 0.2)


func reiniciar() -> void:
	if animacion != null:
		animacion.kill()
	indice = -1
	celebrando = false
	destello = 0.0
	modulate.a = 1.0
	actualizar_visibilidad()


func dibujar_puntos() -> void:
	for numero in progreso.size():
		var centro := Vector2(7 + numero * 21, 9)
		if progreso[numero]:
			puntos.draw_circle(centro, 5.0, ACENTO, true, -1.0, true)
		elif numero == indice:
			puntos.draw_arc(centro, 6.0, 0.0, TAU, 24, ACENTO, 2.0, true)
		else:
			puntos.draw_circle(centro, 4.0, Color("#9AAEBB"), true, -1.0, true)
