extends PanelContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")
const MenuVisual = preload("res://escenas/menu_pieza.gd")
const FINALES := {
	"resuelto": "Orden resuelta",
	"falta-critica": "Orden detenida por una falta crítica",
	"estado-invalido": "No se pudo abrir la práctica",
	"limite-intentos": "Límite de intentos",
}

signal reintento_solicitado
signal salida_solicitada

var motor: RefCounted
var escenario := {}


func _ready() -> void:
	%Guardar.pressed.connect(guardar.bind(false))
	%Omitir.pressed.connect(guardar.bind(true))
	%Reflexion.text_submitted.connect(func(_texto: String): guardar(false))
	%Reintentar.pressed.connect(func(): reintento_solicitado.emit())
	%Volver.pressed.connect(func(): salida_solicitada.emit())
	mostrar(null)


func guardar(omitir: bool) -> void:
	if motor == null:
		return
	if not omitir and %Reflexion.text.strip_edges().is_empty():
		%Validacion.show()
		%Reflexion.grab_focus()
		%Desplazamiento.ensure_control_visible(%Validacion)
		return
	if motor.registrar_reflexion(%Reflexion.text, omitir):
		mostrar(motor)
		%Reintentar.grab_focus()
		%Desplazamiento.scroll_vertical = 0


func mostrar(actual: RefCounted, datos_orden: Dictionary = {}, aviso := "") -> void:
	if not datos_orden.is_empty():
		escenario = datos_orden
		%Aviso.text = TextoLimpio.linea(aviso)
		%Aviso.visible = not aviso.is_empty()
	var abrir := motor != actual or not visible
	motor = actual
	var datos: Dictionary = {} if motor == null else motor.resumen()
	var disponible := not datos.is_empty()
	visible = disponible or get_parent() == get_tree().root
	%Vacio.visible = not disponible
	%Estado.visible = disponible
	%Desplazamiento.visible = disponible
	%Acciones.visible = disponible
	if not disponible:
		%Reflexion.clear()
		%Validacion.hide()
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var reflexionado: bool = datos.has("ruta_ideal")
	%Estado.text = FINALES.get(datos.fin, "Práctica terminada")
	%Pregunta.text = ("Reflexión omitida" if datos.reflexion_omitida else TextoLimpio.linea(datos.reflexion)) \
		if reflexionado else datos.pregunta
	%Reflexion.visible = not reflexionado
	%Guardar.visible = not reflexionado
	%Omitir.visible = not reflexionado
	%Ruta.visible = reflexionado
	var acciones := [%Reintentar, %Volver] if reflexionado else [%Reflexion, %Guardar, %Omitir, %Reintentar, %Volver]
	for indice in acciones.size():
		var control: Control = acciones[indice]
		control.focus_next = control.get_path_to(acciones[(indice + 1) % acciones.size()])
		control.focus_previous = control.get_path_to(acciones[posmod(indice - 1, acciones.size())])
	if reflexionado:
		%Validacion.hide()
	var lineas := PackedStringArray()
	var marca_orden: String = TextoLimpio.limpiar(escenario.get("titulo", "")).etiqueta
	if not marca_orden.is_empty():
		lineas.append(marca_orden)
	var cierre: Dictionary = datos.diagnostico_final
	if not cierre.is_empty():
		lineas.append("Diagnóstico final: %s · Respuesta: %s" % [
			"Correcto" if cierre.correcto else "Incorrecto", MenuVisual.nombre_causa(cierre.elegida)])
		lineas.append("Causa real: %s · %s" % [MenuVisual.nombre_causa(cierre.real), TextoLimpio.linea(cierre.explicacion)])
		var marca: String = TextoLimpio.limpiar(cierre.fuente).etiqueta
		if not marca.is_empty():
			lineas.append(marca)
		lineas.append("Fuente: " + TextoLimpio.fuente(cierre.fuente))
	for intento in datos.comparacion:
		var metricas: Dictionary = datos.comparacion[intento]
		if not metricas.is_empty():
			lineas.append("%s: %d puntos · %d errores · %d ms" % [
				intento.capitalize(), metricas.puntaje, metricas.errores, metricas.tiempo_ms])
	if datos.has("errores_arnes"):
		lineas.append("Errores de medición: %d · Errores de interpretación: %d" % [
			datos.errores_arnes.medicion, datos.errores_arnes.interpretacion])
	for decision in datos.linea_tiempo:
		lineas.append("%s · %s · %s" % [nombre_accion(decision.accion),
			"Acierto" if decision.aplicada and decision.tipo_error.is_empty() else "Error",
			TextoLimpio.linea(decision.motivo)])
	for brecha in datos.brechas:
		lineas.append("Elegiste %s y ejecutaste %s." % [
			MenuVisual.nombre_causa(brecha.causa_marcada), nombre_accion(brecha.accion_ejecutada)])
	%Detalle.text = "\n".join(lineas)
	if reflexionado:
		var ruta := PackedStringArray(["Pasos para resolver la falla"])
		for paso in datos.ruta_ideal:
			ruta.append(TextoLimpio.linea(paso.descripcion))
			var marca: String = TextoLimpio.limpiar(paso.fuente).etiqueta
			if not marca.is_empty():
				ruta.append(marca)
			ruta.append("Fuente: " + TextoLimpio.fuente(paso.fuente))
		%Ruta.text = "\n".join(ruta)
	if abrir:
		%Desplazamiento.scroll_vertical = 0
		(%Reintentar if reflexionado else %Reflexion).grab_focus()


func _input(evento: InputEvent) -> void:
	if not visible or motor == null or not evento.is_pressed() or evento.is_echo():
		return
	if (evento is InputEventKey and evento.keycode == KEY_ESCAPE) \
			or (evento is InputEventJoypadButton and evento.button_index == JOY_BUTTON_B):
		get_viewport().set_input_as_handled()
		salida_solicitada.emit()
	elif (evento is InputEventKey and evento.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]) \
			or (evento is InputEventJoypadButton and evento.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		var subir: bool = evento.keycode == KEY_PAGEUP if evento is InputEventKey \
			else evento.button_index == JOY_BUTTON_LEFT_SHOULDER
		var pagina := int(%Desplazamiento.size.y)
		%Desplazamiento.scroll_vertical += -pagina if subir else pagina
		get_viewport().set_input_as_handled()
	elif evento is InputEventJoypadButton:
		var foco := get_viewport().gui_get_focus_owner()
		if evento.button_index == JOY_BUTTON_A and foco == %Reflexion:
			get_viewport().set_input_as_handled()
			guardar(false)
		elif evento.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN,
				JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT] and foco != null:
			var anterior: bool = evento.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]
			var siguiente := foco.find_prev_valid_focus() if anterior else foco.find_next_valid_focus()
			if siguiente != null:
				siguiente.grab_focus()
				get_viewport().set_input_as_handled()


func nombre_accion(id: String) -> String:
	var acciones: Dictionary = escenario.get("acciones", {})
	var recuperaciones: Dictionary = escenario.get("recuperaciones", {})
	var regla: Dictionary = acciones.get(id, recuperaciones.get(id, {}))
	return TextoLimpio.limpiar(regla.get("titulo", "Paso de la orden")).texto
