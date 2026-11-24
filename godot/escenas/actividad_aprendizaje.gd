extends ScrollContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")

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

var titulo_preparado := ""
@onready var contenido := $Margen/Centro/Tarjeta/Contenido
@onready var opciones := contenido.get_node("Opciones")
@onready var enviar := contenido.get_node("Enviar")
@onready var detalle := contenido.get_node("Detalle")
@onready var aviso := contenido.get_node("Aviso")
@onready var fuente := contenido.get_node("Fuente")
@onready var pregunta_visible := contenido.get_node("Pregunta")
@onready var progreso := contenido.get_node("Progreso")
@onready var reiniciar := contenido.get_node("Reiniciar")


func _ready() -> void:
	enviar.pressed.connect(confirmar)
	reiniciar.pressed.connect(func():
		var inicio_anterior := inicio_ms
		mostrar_item()
		inicio_ms = inicio_anterior)
	if not titulo_preparado.is_empty():
		contenido.get_node("Titulo").text = titulo_preparado
	if not actividad.perfil.has("id") or actividad.base.is_empty():
		pregunta_visible.text = "Primero entra con tu alias"
		detalle.text = "Vuelve al menú y entra con tu alias."
		return
	if actividad.preparar(banco, ahora()):
		mostrar_item()
	else:
		pregunta_visible.text = "Esta actividad aún no está disponible"
		mostrar_avisos()


func mostrar_item() -> void:
	for hijo in opciones.get_children():
		opciones.remove_child(hijo)
		hijo.queue_free()
	detalle.text = ""
	fuente.text = ""
	contenido.get_node("Marca").hide()
	seleccion.clear()
	fuente_entrada = "interfaz"
	mostrar_avisos()
	var indice := actividad.intentos.size()
	progreso.max_value = actividad.items.size()
	progreso.value = mini(indice + 1, actividad.items.size())
	progreso.show()
	if indice == actividad.items.size():
		item = {}
		contenido.get_node("Numero").text = "Actividad completada"
		reiniciar.hide()
		pregunta_visible.text = "Respuestas completas."
		enviar.text = "Guardar y terminar"
		enviar.show()
		enviar.grab_focus()
		return

	item = actividad.items[indice]
	var leccion := actividad.leccion(indice)
	if not leccion.is_empty():
		detalle.text = "Lección corta %d de %d · %d min\n%s\n%s%s" % [
			actividad.numero_leccion(indice), actividad.plan.lecciones.size(), leccion.minutos,
			Actividad.Banco.COMPETENCIAS[leccion.competencia],
			"Ejemplo didáctico\n" if leccion.muestra else "", TextoLimpio.limpiar(leccion.explicacion).texto]
		detalle.text += "\n[color=#9aa7b4]Fuente de la lección: %s[/color]" % citar(leccion.fuente)
	if actividad.reloj_simulado:
		fuente.text += "Reloj simulado\n"
	fuente.text += "Fuente: %s" % citar(item.fuente)
	progreso.tooltip_text = "Pregunta %d de %d" % [indice + 1, actividad.items.size()]
	contenido.get_node("Numero").text = progreso.tooltip_text
	contenido.get_node("Numero").show()
	var pregunta: String
	enviar.text = "Enviar respuesta"
	enviar.visible = item.formato != "opcion-multiple"
	reiniciar.visible = enviar.visible
	match item.formato:
		"opcion-multiple":
			pregunta = item.pregunta
			for numero in range(item.opciones.size()):
				agregar_opcion(item.opciones[numero], responder.bind(numero))
		"caso-diagnostico":
			pregunta = "%s\n%s\nElige los pasos en el orden en que los harías." % [
				item.codigo_falla, "\n".join(item.sintomas)]
			for paso in item.pasos:
				agregar_opcion(paso.accion, agregar_paso.bind(paso))
		"accion-panel":
			pregunta = item.instruccion
			var panel := PanelVirtual.instantiate()
			panel.accion_recibida.connect(recibir_panel)
			opciones.add_child(panel)
	var pregunta_limpia := TextoLimpio.limpiar(pregunta)
	pregunta_visible.text = pregunta_limpia.texto
	var marca: String = pregunta_limpia.etiqueta
	if marca.is_empty() and item.get("muestra", false):
		marca = "Ejemplo didáctico"
	var etiqueta: Label = contenido.get_node("Marca")
	etiqueta.text = marca
	etiqueta.visible = not marca.is_empty()
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
	boton.text = TextoLimpio.linea(texto)
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.custom_minimum_size.y = 52
	boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boton.pressed.connect(accion)
	opciones.add_child(boton)


func agregar_paso(paso: Dictionary) -> void:
	seleccion.append(paso.id)
	detalle.text += "\n%d. %s" % [seleccion.size(), TextoLimpio.linea(paso.resultado)]


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
		aviso.text = "No se guardó tu avance. Pulsa Guardar y terminar otra vez."
		aviso.show()
		return
	guardado = true
	enviar.hide()
	pregunta_visible.text = "Paso guardado."
	var lineas := PackedStringArray()
	for competencia in actividad.resultados:
		var resultado: Dictionary = actividad.resultados[competencia]
		lineas.append("%s · %.1f %% · %s · Confianza %s" % [
			Actividad.Banco.COMPETENCIAS[competencia], resultado.dominio, resultado.nivel, resultado.confianza])
	if actividad.paso == "ruta":
		lineas.append("Temas para repasar")
		for competencia in actividad.ruta:
			lineas.append(Actividad.Banco.COMPETENCIAS[competencia])
	detalle.text = "\n".join(lineas)
	if not cierre.respaldo:
		actividad.avisos.append("Tu avance quedó guardado. Falló la copia de respaldo.")
		mostrar_avisos()
	finalizada.emit()


func responder(respuesta: Variant) -> void:
	if actividad.responder(respuesta, Time.get_ticks_msec() - inicio_ms, fuente_entrada, ahora()):
		mostrar_item()
	else:
		aviso.text = "No se pudo consultar la hora. Envía tu respuesta otra vez."
		aviso.show()


func citar(fuente: Variant) -> String:
	if fuente is String:
		return TextoLimpio.fuente(fuente)
	var datos := PackedStringArray()
	for campo in ["origen", "titulo", "seccion", "pagina", "referencia", "url"]:
		if fuente.has(campo):
			datos.append(TextoLimpio.fuente(str(fuente[campo])))
	return " · ".join(datos)


func ahora() -> int:
	return int(Time.get_unix_time_from_system())
