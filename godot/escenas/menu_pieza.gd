extends CanvasLayer

signal elegida(indice: int, fuente: String)
signal causa_marcada(causa: String)
signal cierre_solicitado

var entradas: Array[Dictionary] = []
var botones: Array[Button] = []
@onready var contenido := $Centro/Tarjeta/Contenido
@onready var causa: OptionButton = contenido.get_node("Causa")
@onready var acciones: VBoxContainer = contenido.get_node("Acciones")


func _ready() -> void:
	contenido.get_node("Cerrar").pressed.connect(func(): cierre_solicitado.emit())
	causa.item_selected.connect(func(indice: int): causa_marcada.emit(causa.get_item_metadata(indice)))


func abrir(titulo: String, lectura: String, opciones: Array[Dictionary], causas: Array, marcada: String) -> void:
	entradas = opciones
	contenido.get_node("Titulo").text = titulo
	contenido.get_node("Lectura").text = lectura
	contenido.get_node("Lectura").visible = not lectura.is_empty()
	causa.clear()
	causa.add_item("Marcar una causa")
	causa.set_item_metadata(0, "")
	for id in causas:
		causa.add_item(id.replace("-", " ").capitalize())
		causa.set_item_metadata(causa.item_count - 1, id)
		if id == marcada:
			causa.select(causa.item_count - 1)
	causa.visible = not causas.is_empty()
	for boton in botones:
		acciones.remove_child(boton)
		boton.queue_free()
	botones.clear()
	for indice in range(entradas.size()):
		var entrada := entradas[indice]
		var boton := Button.new()
		boton.text = "%d. %s" % [indice + 1, entrada.texto]
		if entrada.costo != "—" or entrada.tiempo != "—" or entrada.riesgo != "—":
			boton.text += "\nCosto %s · Tiempo %s · Riesgo %s" % [entrada.costo, entrada.tiempo, entrada.riesgo]
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.add_theme_font_size_override("font_size", 16)
		boton.pressed.connect(func(): elegida.emit(indice, "teclado"))
		acciones.add_child(boton)
		botones.append(boton)
	acciones.show()
	contenido.get_node("Pendiente").hide()
	show()
	var foco: Control = botones[0] if not botones.is_empty() else contenido.get_node("Cerrar")
	foco.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func esperar_panel(accion: String) -> void:
	acciones.hide()
	causa.hide()
	var aviso: Label = contenido.get_node("Pendiente")
	aviso.text = "%s\nConfirma en el panel (Enter o botón Confirmar)\nControl · X" % accion
	aviso.show()
	contenido.get_node("Cerrar").grab_focus()


func cerrar() -> void:
	causa.get_popup().hide()
	var foco := get_viewport().gui_get_focus_owner()
	if foco != null and contenido.is_ancestor_of(foco):
		foco.release_focus()
	hide()


func elegir_con_control() -> bool:
	var indice := botones.find(get_viewport().gui_get_focus_owner())
	if indice < 0 or not acciones.visible:
		return false
	elegida.emit(indice, "control")
	return true


func mover_foco(paso: int) -> void:
	var controles: Array[Control] = []
	if causa.visible:
		controles.append(causa)
	if acciones.visible:
		controles.append_array(botones)
	controles.append(contenido.get_node("Cerrar"))
	var indice := controles.find(get_viewport().gui_get_focus_owner())
	controles[posmod(indice + paso, controles.size())].grab_focus()
