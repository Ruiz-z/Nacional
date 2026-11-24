extends ScrollContainer

signal orden_elegida(archivo: String)

const Ordenes = preload("res://logica/simulador/ordenes.gd")
const ZONAS := {"gabinete": "Gabinete lateral", "faros": "Faros", "motor": "Motor eléctrico",
	"cabina": "Cabina"}
const DIFICULTADES := {"facil": "Fácil", "media": "Media", "dificil": "Difícil"}


func _ready() -> void:
	var listado := Ordenes.listar()
	var tarjetas := $Centro/Columna/Tarjetas
	for orden in listado.ordenes:
		var tarjeta := Button.new()
		tarjeta.text = "%s\n%s · Dificultad %s\n%s" % [
			orden.titulo, ZONAS[orden.zona], DIFICULTADES[orden.dificultad], orden.competencia]
		tarjeta.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tarjeta.custom_minimum_size.y = 112
		tarjeta.pressed.connect(func(): orden_elegida.emit(orden.archivo))
		tarjetas.add_child(tarjeta)
	if tarjetas.get_child_count() > 0:
		tarjetas.get_child(0).grab_focus()
	var aviso := $Centro/Columna/Aviso
	if listado.ordenes.is_empty():
		aviso.text = "No hay órdenes de servicio disponibles."
	elif not listado.errores.is_empty():
		aviso.text = "Algunas órdenes no se pudieron cargar."
	aviso.visible = not aviso.text.is_empty()
