extends CanvasLayer

const TextoLimpio = preload("res://logica/texto_limpio.gd")
const Sonido = preload("res://logica/sonido.gd")

signal abierta
signal confirmada(aviso: Dictionary)
signal terminada
signal opcion_elegida(indice: int, fuente: String)

const TIPOS := {
	"orden": ["ORDEN DE TRABAJO", Color("#124747"), Color("#b5fffc")],
	"exito": ["BIEN HECHO", Color("#215040"), Color("#c7f9dd")],
	"cierre": ["CIERRE DE LA ORDEN", Color("#124747"), Color("#b5fffc")],
	"correcto": ["CORRECTO", Color("#215040"), Color("#c7f9dd")],
	"incorrecto": ["INCORRECTO", Color("#592d34"), Color("#ffdedf")],
	"falta": ["FALTA ALGO", Color("#503b1c"), Color("#ffe1a1")],
	"aviso": ["AVISO", Color("#503b1c"), Color("#ffe1a1")],
	"error": ["ERROR", Color("#592d34"), Color("#ffdedf")],
	"critico": ["FALTA CRÍTICA", Color("#a52232"), Color("#ffffff")],
	"info": ["INFORMACIÓN", Color("#124747"), Color("#b5fffc")],
}

var cola: Array[Dictionary] = []
var indice := 1
var opciones: Array[Button] = []

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
		if aviso not in cola:
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
	Sonido.reproducir({"exito": "exito", "correcto": "exito", "error": "error", "incorrecto": "error",
		"critico": "critico", "falta": "aviso", "aviso": "aviso"}.get(aviso.tipo, "clic"))
	var fondo := chip.get_theme_stylebox("normal", "Chip").duplicate() as StyleBoxFlat
	fondo.bg_color = estilo[1]
	fondo.border_color = fondo.bg_color.lightened(0.2)
	chip.add_theme_stylebox_override("normal", fondo)
	chip.add_theme_color_override("font_color", estilo[2])
	chip.text = estilo[0]
	titulo.text = TextoLimpio.limpiar(aviso.titulo).texto if not aviso.titulo.is_empty() else estilo[0].capitalize()
	cuerpo.text = TextoLimpio.limpiar(aviso.texto).texto
	var briefing: Dictionary = aviso.get("briefing", {})
	%Briefing.visible = not briefing.is_empty()
	cuerpo.visible = briefing.is_empty()
	if not briefing.is_empty():
		%Sintoma.text = briefing.sintoma
		%Objetivo.text = briefing.objetivo
		%Como.text = "\n".join(briefing.como)
		%Leyenda.text = "\n".join(aviso.get("leyenda", []))
	var textos := [aviso.titulo, aviso.texto, aviso.donde, aviso.fuente, aviso.get("marca", "")]
	textos.append_array(aviso.get("opciones", []))
	var marca: String = TextoLimpio.limpiar("\n".join(textos)).etiqueta
	%Marca.text = marca
	%Marca.visible = not marca.is_empty()
	donde.text = "Dónde está: " + TextoLimpio.limpiar(aviso.donde).texto
	donde.visible = not aviso.donde.is_empty()
	fuente.text = "Fuente: " + TextoLimpio.fuente(aviso.fuente)
	fuente.visible = not aviso.fuente.is_empty()
	mostrar_contador()
	for boton in opciones:
		boton.get_parent().remove_child(boton)
		boton.queue_free()
	opciones.clear()
	var nombres: Array = aviso.get("opciones", [])
	for numero in nombres.size():
		var boton := Button.new()
		boton.custom_minimum_size.y = 44
		boton.text = "%d · %s" % [numero + 1, TextoLimpio.limpiar(nombres[numero]).texto]
		boton.pressed.connect(func(): opcion_elegida.emit(numero, "teclado"))
		ok.get_parent().add_child(boton)
		opciones.append(boton)
	ok.visible = opciones.is_empty()
	show()
	(ok if opciones.is_empty() else opciones[0]).grab_focus()


func mostrar_contador() -> void:
	var total := indice + cola.size() - 1
	contador.visible = total > 1
	contador.text = "%d de %d" % [indice, total]


func confirmar() -> void:
	if cola.is_empty() or not opciones.is_empty():
		return
	var aviso: Dictionary = cola.pop_front()
	confirmada.emit(aviso)
	if cola.is_empty():
		hide()
		terminada.emit()
	else:
		indice += 1
		mostrar_primera()


func mostrar_respuesta(aviso: Dictionary) -> void:
	cola[0] = aviso
	mostrar_primera()


func _input(evento: InputEvent) -> void:
	if not visible or evento is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	if not evento.is_pressed() or evento.is_echo():
		return
	if not opciones.is_empty():
		var foco := opciones.find(get_viewport().gui_get_focus_owner())
		if evento is InputEventKey:
			var numero: int = evento.keycode - KEY_1
			if numero >= 0 and numero < mini(9, opciones.size()):
				opcion_elegida.emit(numero, "teclado")
			elif evento.keycode in [KEY_UP, KEY_DOWN]:
				opciones[posmod(foco + (1 if evento.keycode == KEY_DOWN else -1), opciones.size())].grab_focus()
			elif evento.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and foco >= 0:
				opcion_elegida.emit(foco, "teclado")
		elif evento is InputEventJoypadButton:
			if evento.button_index == JOY_BUTTON_A and foco >= 0:
				opcion_elegida.emit(foco, "control")
			elif evento.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
				var paso := 1 if evento.button_index == JOY_BUTTON_DPAD_DOWN else -1
				opciones[posmod(foco + paso, opciones.size())].grab_focus()
		return
	if (evento is InputEventKey and evento.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]) \
			or (evento is InputEventJoypadButton and evento.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]):
		confirmar()
