extends CanvasLayer

# Primer paso de cada orden: elegir el EPP que pide la tarea antes de tocar el autobús.

const Epp = preload("res://logica/simulador/epp.gd")
const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal confirmado(elegidos: Array)
signal equipado

var botones := {}
var aviso: Label
var detalle: Label
var boton_ok: Button
var _orden := {}


func _init() -> void:
	layer = 20
	visible = false


func abrir(orden: Dictionary) -> void:
	_orden = orden
	for hijo in get_children():
		hijo.queue_free()
	botones.clear()
	var fondo := ColorRect.new()
	fondo.color = Color(0.024, 0.051, 0.071, 0.82)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.add_child(centro)
	var tarjeta := PanelContainer.new()
	tarjeta.custom_minimum_size.x = clampf(get_viewport().get_visible_rect().size.x - 48, 0, 720)
	centro.add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	tarjeta.add_child(columna)
	var chip := Label.new()
	chip.theme_type_variation = &"Chip"
	chip.text = "PRIMER PASO · EPP"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	columna.add_child(chip)
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.text = "Equípate antes de empezar"
	columna.add_child(titulo)
	var riesgo := Label.new()
	riesgo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	riesgo.add_theme_font_size_override("font_size", 18)
	var nombre_orden: String = TextoLimpio.limpiar(str(orden.get("titulo", ""))).texto
	riesgo.text = "%s\n%s\nElige el equipo que pide esta tarea. Algunas piezas no hacen falta." % [
		nombre_orden, Epp.resumen_riesgo(orden)]
	columna.add_child(riesgo)
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 10)
	rejilla.add_theme_constant_override("v_separation", 10)
	columna.add_child(rejilla)
	for id in Epp.ofrecidos(orden):
		var boton := Button.new()
		boton.toggle_mode = true
		boton.text = Epp.nombre(id)
		boton.custom_minimum_size = Vector2(0, 48)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.focus_mode = Control.FOCUS_ALL
		boton.toggled.connect(func(_activo: bool): mostrar_detalle(id))
		boton.focus_entered.connect(func(): mostrar_detalle(id))
		rejilla.add_child(boton)
		botones[id] = boton
	detalle = Label.new()
	detalle.theme_type_variation = &"Secundario"
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.custom_minimum_size.y = 44
	detalle.text = "Elige una pieza para ver para qué sirve."
	columna.add_child(detalle)
	aviso = Label.new()
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_size_override("font_size", 17)
	aviso.add_theme_color_override("font_color", Color("#ffe1a1"))
	aviso.hide()
	columna.add_child(aviso)
	boton_ok = Button.new()
	boton_ok.text = "Ponerme el EPP"
	boton_ok.custom_minimum_size = Vector2(0, 52)
	boton_ok.pressed.connect(confirmar)
	columna.add_child(boton_ok)
	show()
	botones.values()[0].grab_focus()


func mostrar_detalle(id: String) -> void:
	detalle.text = "%s: %s" % [Epp.nombre(id), Epp.MOTIVOS.get(id, "")]


func elegidos() -> Array:
	var lista := []
	for id in botones:
		if botones[id].button_pressed:
			lista.append(id)
	return lista


func confirmar() -> void:
	if visible:
		confirmado.emit(elegidos())


# El juego devuelve la revisión: qué faltó o sobró. Si no faltó nada, el vestidor se cierra.
func mostrar_revision(revision: Dictionary) -> void:
	if revision.completo:
		hide()
		equipado.emit()
		return
	var faltan: Array = revision.faltantes.map(func(id: String): return "%s (%s)" % [
		Epp.nombre(id), Epp.MOTIVOS.get(id, "")])
	aviso.text = "Todavía no puedes trabajar. Te falta:\n" + "\n".join(faltan)
	aviso.show()
