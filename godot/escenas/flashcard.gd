extends CanvasLayer

signal abierta
signal confirmada(aviso: Dictionary)
signal terminada

const TIPOS := {
	"falta": ["FALTA ALGO", Color("#503b1c"), Color("#ffe1a1")],
	"aviso": ["AVISO", Color("#503b1c"), Color("#ffe1a1")],
	"error": ["ERROR", Color("#592d34"), Color("#ffdedf")],
	"critico": ["FALTA CRÍTICA", Color("#a52232"), Color("#ffffff")],
	"info": ["INFORMACIÓN", Color("#124747"), Color("#b5fffc")],
}

var cola: Array[Dictionary] = []
var indice := 1

@onready var tarjeta: PanelContainer = %Tarjeta
@onready var chip: Label = %Chip
@onready var contador: Label = %Contador
@onready var titulo: Label = %Titulo
@onready var cuerpo: Label = %Cuerpo
@onready var donde: Label = %Donde
@onready var fuente: Label = %Fuente
@onready var ok: Button = %OK


func _ready() -> void:
	ok.pressed.connect(confirmar)
	get_viewport().size_changed.connect(ajustar_ancho)
	ajustar_ancho()


func ajustar_ancho() -> void:
	tarjeta.custom_minimum_size.x = clampf(get_viewport().get_visible_rect().size.x - 48, 0, 640)


func encolar(aviso: Dictionary) -> void:
	if not cola.is_empty():
		if cola.back() != aviso:
			cola.append(aviso)
			mostrar_contador()
		return
	cola.append(aviso)
	indice = 1
	abierta.emit()
	mostrar_primera()


func mostrar_primera() -> void:
	var aviso: Dictionary = cola[0]
	var estilo: Array = TIPOS[aviso.tipo]
	var fondo := chip.get_theme_stylebox("normal", "Chip").duplicate() as StyleBoxFlat
	fondo.bg_color = estilo[1]
	fondo.border_color = fondo.bg_color.lightened(0.2)
	chip.add_theme_stylebox_override("normal", fondo)
	chip.add_theme_color_override("font_color", estilo[2])
	chip.text = estilo[0]
	titulo.text = aviso.titulo if not aviso.titulo.is_empty() else estilo[0].capitalize()
	cuerpo.text = aviso.texto
	donde.text = "Dónde está: " + aviso.donde
	donde.visible = not aviso.donde.is_empty()
	fuente.text = "Fuente: " + aviso.fuente
	fuente.visible = not aviso.fuente.is_empty()
	mostrar_contador()
	show()
	ok.grab_focus()


func mostrar_contador() -> void:
	var total := indice + cola.size() - 1
	contador.visible = total > 1
	contador.text = "%d de %d" % [indice, total]


func confirmar() -> void:
	if cola.is_empty():
		return
	var aviso: Dictionary = cola.pop_front()
	confirmada.emit(aviso)
	if cola.is_empty():
		hide()
		terminada.emit()
	else:
		indice += 1
		mostrar_primera()


func _input(evento: InputEvent) -> void:
	if not visible or evento is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	if not evento.is_pressed() or evento.is_echo():
		return
	if (evento is InputEventKey and evento.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]) \
			or (evento is InputEventJoypadButton and evento.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]):
		confirmar()
