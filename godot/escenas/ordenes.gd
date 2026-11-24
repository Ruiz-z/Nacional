extends ScrollContainer

signal orden_elegida(archivo: String)

const Ordenes = preload("res://logica/simulador/ordenes.gd")
const ZONAS := {"gabinete": "Gabinete lateral", "faros": "Faros", "motor": "Motor eléctrico",
	"cabina": "Cabina", "banco": "Banco de arnés", "bajos": "Bajos del autobús"}
const DIFICULTADES := {"facil": "Fácil", "media": "Media", "dificil": "Difícil"}
const GRUPOS := {
	"FG0": "General", "FG1": "Servicio y mantenimiento", "FG2": "Motor",
	"FG3": "Sistema eléctrico", "FG4": "Transmisión", "FG5": "Frenos", "FG6": "Suspensión y dirección",
	"FG7": "Bastidor, resortes, amortiguadores y ruedas", "FG8": "Carrocería e interior",
	"FG9": "Temas diversos",
}

@onready var tarjetas: VBoxContainer = $Centro/Columna/Tarjetas


func _ready() -> void:
	draw.connect(func(): draw_rect(Rect2(Vector2.ZERO, size), Color("#ECFAFA")))
	resized.connect(queue_redraw)
	mostrar(Ordenes.listar())


func mostrar(listado: Dictionary) -> void:
	for anterior in tarjetas.get_children():
		tarjetas.remove_child(anterior)
		anterior.queue_free()
	var grupos := {}
	for orden: Dictionary in listado.ordenes:
		var fg: String = orden.get("grupo_funcion") if orden.get("grupo_funcion") is String else ""
		if not grupos.has(fg):
			grupos[fg] = []
		grupos[fg].append(orden)
	var claves := grupos.keys()
	claves.sort()
	if claves.has(""):
		claves.erase("")
		claves.append("")
	var primera: Button
	for fg: String in claves:
		var grupo := VBoxContainer.new()
		grupo.name = fg if not fg.is_empty() else "Otros"
		tarjetas.add_child(grupo)
		var titulo := Label.new()
		titulo.name = "Titulo"
		titulo.theme_type_variation = &"TituloClaro"
		titulo.add_theme_font_size_override("font_size", 22)
		titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var etiqueta := "FG " + fg.trim_prefix("FG")
		titulo.text = "Otros" if fg.is_empty() else etiqueta
		if GRUPOS.has(fg):
			titulo.text += " · " + GRUPOS[fg]
		grupo.add_child(titulo)
		for orden: Dictionary in grupos[fg]:
			var tarjeta := crear_tarjeta(orden, "Otros" if fg.is_empty() else etiqueta)
			grupo.add_child(tarjeta)
			if primera == null:
				primera = tarjeta
	if primera != null:
		primera.grab_focus()
	var aviso := $Centro/Columna/Aviso
	aviso.text = ""
	if listado.ordenes.is_empty():
		aviso.text = "No hay órdenes disponibles. Vuelve al menú y elige otra actividad."
	elif not listado.errores.is_empty():
		aviso.text = "Algunas órdenes no abrieron. Elige una de la lista."
	aviso.visible = not aviso.text.is_empty()


func crear_tarjeta(orden: Dictionary, etiqueta: String) -> Button:
	var tarjeta := Button.new()
	tarjeta.theme_type_variation = &"BotonOrden"
	tarjeta.text = "%s\n%s · Dificultad %s\n%s" % [
		orden.titulo + ("\n" + orden.marca if not orden.get("marca", "").is_empty() else ""), ZONAS.get(orden.zona, orden.zona),
		DIFICULTADES.get(orden.dificultad, orden.dificultad), orden.competencia]
	tarjeta.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tarjeta.custom_minimum_size.y = 136
	tarjeta.accessibility_name = "%s · %s" % [etiqueta, tarjeta.text]
	tarjeta.pressed.connect(func(): orden_elegida.emit(orden.archivo))
	var insignia := Label.new()
	insignia.name = "GrupoFuncion"
	insignia.theme_type_variation = &"Insignia"
	insignia.text = etiqueta
	insignia.position = Vector2(16, 12)
	tarjeta.add_child(insignia)
	return tarjeta
