extends ScrollContainer

signal finalizada

const Actividad = preload("res://logica/flujo/actividad_aprendizaje.gd")
const PanelVirtual = preload("res://escenas/panel_virtual.tscn")

var actividad := Actividad.new()
var banco := {}
var item := {}
var seleccion := []
var fuente_entrada := "interfaz"
var inicio_ms := 0
var guardado := false

@onready var opciones := $Contenido/Opciones
@onready var enviar := $Contenido/Enviar
@onready var detalle := $Contenido/Detalle
@onready var aviso := $Contenido/Aviso


func _ready() -> void:
	enviar.pressed.connect(confirmar)
	$Contenido/Reiniciar.pressed.connect(func():
		var inicio_anterior := inicio_ms
		mostrar_item()
		inicio_ms = inicio_anterior)
	if actividad.preparar(banco, ahora()):
		mostrar_item()
	else:
		mostrar_avisos()


func mostrar_item() -> void:
	for hijo in opciones.get_children():
		opciones.remove_child(hijo)
		hijo.queue_free()
	detalle.text = ""
	seleccion.clear()
	fuente_entrada = "interfaz"
	mostrar_avisos()
	var indice := actividad.intentos.size()
	if indice == actividad.items.size():
		item = {}
		$Contenido/Reiniciar.hide()
		$Contenido/Pregunta.text = "Respuestas completas."
		enviar.text = "Guardar y terminar"
		enviar.show()
		enviar.grab_focus()
		return

	item = actividad.items[indice]
	var leccion := actividad.leccion(indice)
	if not leccion.is_empty():
		detalle.text = "Microlección %d de %d · %d min\n%s\n%s%s\nFuente: %s\n\n" % [
			actividad.numero_leccion(indice), actividad.plan.lecciones.size(), leccion.minutos,
			Actividad.Banco.COMPETENCIAS[leccion.competencia],
			"[MUESTRA] " if leccion.muestra else "", leccion.explicacion, citar(leccion.fuente)]
	if actividad.reloj_simulado:
		detalle.text += "Reloj simulado\n"
	detalle.text += "Ítem %d de %d · Fuente: %s" % [
		indice + 1, actividad.items.size(), citar(item.fuente)]
	var pregunta: String
	enviar.text = "Enviar respuesta"
	enviar.visible = item.formato != "opcion-multiple"
	$Contenido/Reiniciar.visible = enviar.visible
	match item.formato:
		"opcion-multiple":
			pregunta = item.pregunta
			for numero in range(item.opciones.size()):
				agregar_opcion(item.opciones[numero], responder.bind(numero))
		"caso-diagnostico":
			pregunta = "%s\n%s\nSelecciona los pasos en el orden en que los ejecutarías." % [
				item.codigo_falla, "\n".join(item.sintomas)]
			for paso in item.pasos:
				agregar_opcion(paso.accion, agregar_paso.bind(paso))
		"accion-panel":
			pregunta = item.instruccion
			var panel := PanelVirtual.instantiate()
			panel.accion_recibida.connect(recibir_panel)
			opciones.add_child(panel)
	$Contenido/Pregunta.text = ("[MUESTRA] " if item.get("muestra", false) else "") + pregunta
	var primero := opciones.get_child(0)
	if primero is Button:
		primero.grab_focus()
	else:
		primero.get_node("Bloqueo").grab_focus()
	inicio_ms = Time.get_ticks_msec()


func mostrar_avisos() -> void:
	aviso.text = "\n".join(actividad.avisos)
	aviso.visible = not aviso.text.is_empty()


func agregar_opcion(texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boton.pressed.connect(accion)
	opciones.add_child(boton)


func agregar_paso(paso: Dictionary) -> void:
	seleccion.append(paso.id)
	detalle.text += "\n%d. %s" % [seleccion.size(), paso.resultado]


func recibir_panel(evento: Dictionary) -> void:
	seleccion.append({"accion": evento.accion, "valor": evento.valor})
	fuente_entrada = evento.fuente_entrada


func confirmar() -> void:
	if guardado:
		return
	if not item.is_empty():
		responder(seleccion)
		return
	var cierre := actividad.guardar(ahora())
	if not cierre.get("guardado", false):
		aviso.text = "No se pudo guardar el paso. Intenta nuevamente."
		aviso.show()
		return
	guardado = true
	enviar.hide()
	$Contenido/Pregunta.text = "Paso guardado."
	var lineas := PackedStringArray()
	for competencia in actividad.resultados:
		var resultado: Dictionary = actividad.resultados[competencia]
		lineas.append("%s · %.1f %% · %s · Confianza %s" % [
			Actividad.Banco.COMPETENCIAS[competencia], resultado.dominio, resultado.nivel, resultado.confianza])
	if actividad.paso == "ruta":
		lineas.append("Prioridad actualizada")
		for competencia in actividad.ruta:
			lineas.append(Actividad.Banco.COMPETENCIAS[competencia])
	detalle.text = "\n".join(lineas)
	if not cierre.respaldo:
		actividad.avisos.append("El paso se guardó, pero no se pudo crear el respaldo.")
		mostrar_avisos()
	finalizada.emit()


func responder(respuesta: Variant) -> void:
	if actividad.responder(respuesta, Time.get_ticks_msec() - inicio_ms, fuente_entrada, ahora()):
		mostrar_item()
	else:
		aviso.text = "No se pudo leer el reloj. Intenta nuevamente."
		aviso.show()


func citar(fuente: Variant) -> String:
	if fuente is String:
		return fuente
	var datos := PackedStringArray()
	for campo in ["origen", "titulo", "seccion", "pagina", "referencia", "url"]:
		if fuente.has(campo):
			datos.append(str(fuente[campo]))
	return " · ".join(datos)


func ahora() -> int:
	return int(Time.get_unix_time_from_system())
