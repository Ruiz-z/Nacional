extends CanvasLayer

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal elegida(indice: int, fuente: String)
signal causa_marcada(causa: String)
signal cierre_solicitado

const COLORES := {
	"gris": [Color("#303c49"), Color("#e3eaf1")],
	"azul": [Color("#1b4164"), Color("#e0f1ff")],
	"rojo": [Color("#592d34"), Color("#ffdedf")],
	"ambar": [Color("#503b1c"), Color("#ffe1a1")],
	"verde": [Color("#204939"), Color("#d1f8e3")],
}
const CAUSAS := {
	"modulo-sin-comunicacion": "Módulo sin comunicación",
	"otro-modulo": "Otro módulo",
	"foco-danado": "Foco dañado",
	"fusible-abierto": "Fusible abierto",
	"aislamiento-degradado": "Aislamiento degradado",
	"aviso-inconsistente": "Aviso que no coincide con la lectura",
	"abrazadera-floja": "Abrazadera floja",
	"lectura-inconsistente": "Lectura que no coincide con la revisión",
	"alimentacion": "Falla de alimentación",
	"senal": "Falla de señal",
	"modulo": "Módulo dañado",
}

var entradas: Array[Dictionary] = []
var botones: Array[Button] = []
var causas: Array[Button] = []
@onready var contenido := $Centro/Tarjeta/Contenido
@onready var diagnostico := contenido.get_node("Diagnostico")
@onready var lista: ScrollContainer = contenido.get_node("Lista")
@onready var acciones: VBoxContainer = lista.get_node("Acciones")
@onready var cerrar_boton: Button = contenido.get_node("Cerrar")


func _ready() -> void:
	acciones.minimum_size_changed.connect(ajustar_lista)
	cerrar_boton.pressed.connect(func(): cierre_solicitado.emit())
	var pendiente: Label = contenido.get_node("Pendiente")
	estilo_chip(pendiente, "azul", 16)


static func nombre_causa(id: String) -> String:
	return TextoLimpio.limpiar(CAUSAS.get(id, id.left(1).to_upper() + id.substr(1).replace("-", " "))).texto


func abrir(titulo: String, lectura: String, opciones: Array[Dictionary],
		ids_causa: Array, marcada: String, estado: Dictionary, mueble := false) -> void:
	entradas = opciones
	contenido.get_node("Cabecera/Titulo").text = TextoLimpio.linea(titulo)
	var chip_estado: Label = contenido.get_node("Cabecera/Estado")
	chip_estado.text = TextoLimpio.linea(estado.texto)
	estilo_chip(chip_estado, estado.color)
	var lectura_limpia := TextoLimpio.limpiar(lectura)
	contenido.get_node("Lectura").text = lectura_limpia.texto
	contenido.get_node("Lectura").visible = not lectura_limpia.texto.is_empty()
	var marca: Label = contenido.get_node("Marca")
	marca.text = lectura_limpia.etiqueta
	marca.visible = not marca.text.is_empty()
	for boton in causas + botones:
		boton.get_parent().remove_child(boton)
		boton.queue_free()
	causas.clear()
	botones.clear()
	var grupo := ButtonGroup.new()
	for id: String in ids_causa:
		var boton := Button.new()
		var nombre := nombre_causa(id)
		boton.toggle_mode = true
		boton.button_group = grupo
		boton.add_theme_font_size_override("font_size", 15)
		boton.set_pressed_no_signal(id == marcada)
		boton.text = ("[x]  " if boton.button_pressed else "[ ]  ") + nombre
		boton.toggled.connect(func(activo: bool):
			boton.text = ("[x]  " if activo else "[ ]  ") + nombre)
		boton.pressed.connect(func(): causa_marcada.emit(id))
		diagnostico.get_node("Causas").add_child(boton)
		causas.append(boton)
	diagnostico.visible = not causas.is_empty()
	for indice in range(entradas.size()):
		agregar_accion(indice, entradas[indice], mueble)
	lista.visible = not botones.is_empty()
	ajustar_lista()
	contenido.get_node("SinAcciones").visible = botones.is_empty()
	contenido.get_node("AccionesTitulo").show()
	contenido.get_node("Pendiente").hide()
	show()
	lista.set_deferred("scroll_vertical", 0)
	var foco := botones[0] if not botones.is_empty() else (causas[0] if not causas.is_empty() else cerrar_boton)
	foco.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func agregar_accion(indice: int, entrada: Dictionary, compacto := false) -> void:
	var boton := Button.new()
	boton.accessibility_name = entrada.titulo
	boton.accessibility_description = "%s. %s" % [entrada.ejecucion, entrada.descripcion]
	boton.pressed.connect(func(): elegida.emit(indice, "teclado"))
	acciones.add_child(boton)
	botones.append(boton)
	if compacto:
		boton.text = "%d · %s" % [indice + 1, entrada.titulo]
		if entrada.requiere_panel:
			boton.text += " · Confirma en el panel"
		boton.custom_minimum_size.y = 36
		return

	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(fila)
	var tecla := agregar_chip(fila, str(indice + 1), "gris")
	tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tecla.custom_minimum_size.x = 28
	tecla.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var texto := VBoxContainer.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.add_theme_constant_override("separation", 2)
	fila.add_child(texto)
	var titulo := Label.new()
	titulo.text = entrada.titulo
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 17)
	var negrita := FontVariation.new()
	negrita.base_font = titulo.get_theme_default_font()
	negrita.variation_embolden = 0.6
	titulo.add_theme_font_override("font", negrita)
	texto.add_child(titulo)
	var descripcion := Label.new()
	descripcion.text = entrada.descripcion
	descripcion.theme_type_variation = &"Secundario"
	descripcion.add_theme_font_size_override("font_size", 15)
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_child(descripcion)

	var etiquetas := HFlowContainer.new()
	etiquetas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiquetas.custom_minimum_size.x = 200
	etiquetas.alignment = FlowContainer.ALIGNMENT_END
	etiquetas.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	etiquetas.add_theme_constant_override("h_separation", 4)
	etiquetas.add_theme_constant_override("v_separation", 4)
	fila.add_child(etiquetas)
	if not entrada.get("marca", "").is_empty():
		agregar_chip(etiquetas, entrada.marca, "gris")
	if entrada.ejecucion == "confirmar en panel":
		agregar_chip(etiquetas, "Confirma en el panel", "azul")
	else:
		agregar_chip(etiquetas, "Al elegirla", "gris")
	for campo in ["costo", "tiempo", "riesgo"]:
		if entrada[campo] != "—":
			var alto: bool = campo == "riesgo" and entrada.riesgo.to_lower().begins_with("alt")
			agregar_chip(etiquetas, "%s %s" % [campo.capitalize(), entrada[campo]], "ambar" if alto else "gris")
	margen.minimum_size_changed.connect(func(): boton.custom_minimum_size.y = margen.get_combined_minimum_size().y)
	boton.custom_minimum_size.y = margen.get_combined_minimum_size().y


func ajustar_lista() -> void:
	lista.custom_minimum_size.y = minf(acciones.get_combined_minimum_size().y, 310.0)


func agregar_chip(padre: Control, texto: String, color: String) -> Label:
	var etiqueta := Label.new()
	padre.add_child(etiqueta)
	etiqueta.text = texto
	estilo_chip(etiqueta, color)
	return etiqueta


func estilo_chip(etiqueta: Label, color: String, tam := 13) -> void:
	var estilo := etiqueta.get_theme_stylebox("normal", "Chip").duplicate() as StyleBoxFlat
	estilo.bg_color = COLORES[color][0]
	estilo.border_color = estilo.bg_color.lightened(0.14)
	for lado in [SIDE_LEFT, SIDE_RIGHT]:
		estilo.set_content_margin(lado, 7)
	for lado in [SIDE_TOP, SIDE_BOTTOM]:
		estilo.set_content_margin(lado, 3)
	etiqueta.add_theme_stylebox_override("normal", estilo)
	etiqueta.add_theme_color_override("font_color", COLORES[color][1])
	etiqueta.add_theme_font_size_override("font_size", tam)


func esperar_panel(banco_fisico := false) -> void:
	lista.hide()
	diagnostico.hide()
	contenido.get_node("AccionesTitulo").hide()
	var aviso: Label = contenido.get_node("Pendiente")
	aviso.text = "Cierra el conductor abierto en el banco físico." if banco_fisico \
		else "Acción lista: confirma en el panel (Enter o botón Confirmar)"
	aviso.show()
	cerrar_boton.grab_focus()


func cerrar() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	if foco != null and contenido.is_ancestor_of(foco):
		foco.release_focus()
	hide()


func elegir_con_control() -> bool:
	var foco := get_viewport().gui_get_focus_owner() as Button
	if lista.visible and foco in botones:
		elegida.emit(botones.find(foco), "control")
	elif diagnostico.visible and foco in causas:
		foco.button_pressed = true
		foco.pressed.emit()
	elif foco == cerrar_boton:
		cierre_solicitado.emit()
	else:
		return false
	return true


func mover_foco(paso: int) -> void:
	var controles: Array[Button] = []
	if diagnostico.visible:
		controles.append_array(causas)
	if lista.visible:
		controles.append_array(botones)
	controles.append(cerrar_boton)
	var indice := controles.find(get_viewport().gui_get_focus_owner())
	controles[posmod(indice + paso, controles.size())].grab_focus()
