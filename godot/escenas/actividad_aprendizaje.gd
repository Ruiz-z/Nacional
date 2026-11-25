extends ScrollContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal finalizada

const Actividad = preload("res://logica/flujo/actividad_aprendizaje.gd")
const Foundry = preload("res://logica/aprendizaje/foundry.gd")
const RutaIA = preload("res://logica/aprendizaje/ruta_ia.gd")
const Ordenes = preload("res://logica/simulador/ordenes.gd")
const DatosMapa = preload("res://logica/aprendizaje/mapa_ruta.gd")
const MapaRuta = preload("res://escenas/mapa_ruta.gd")
const PanelVirtual = preload("res://escenas/panel_virtual.tscn")

var actividad := Actividad.new()
var banco := {}
var item := {}
var seleccion := []
var fuente_entrada := "interfaz"
var inicio_ms := 0
var guardado := false
var ultima_retro := {}

var titulo_preparado := ""
var cliente_ia: Node
var retro: Label
var intro: Label
var resultados_caja: VBoxContainer
var roadmap_caja: MapaRuta
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
	crear_bloques()
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
		if actividad.paso == "ruta":
			await pedir_ruta_ia()
		mostrar_item()
	else:
		pregunta_visible.text = "Esta actividad aún no está disponible"
		mostrar_avisos()


# Pide a Foundry la ruta si hay configuración; si no hay, falla o no es válida, queda la ruta por reglas.
func pedir_ruta_ia() -> void:
	if cliente_ia == null:
		cliente_ia = Foundry.new()
	if not cliente_ia.disponible():
		return
	var ordenes: Array = Ordenes.listar().ordenes
	var contexto := actividad.contexto_ruta(ordenes)
	var llave := RutaIA.clave(contexto)
	var validada := RutaIA.leer_cache(actividad.base, actividad.perfil.id, llave)
	if validada.is_empty():
		add_child(cliente_ia) if cliente_ia.get_parent() == null else null
		pregunta_visible.text = "Armando tu ruta…"
		var competencias: Array = contexto.orden_base
		var respuesta: Dictionary = await cliente_ia.generar(RutaIA.INSTRUCCION, contexto, RutaIA.esquema(competencias))
		var ids := ordenes.map(func(orden: Dictionary) -> String: return orden.id)
		validada = RutaIA.validar(respuesta, competencias, actividad.historial, ids)
		if not validada.is_empty():
			RutaIA.guardar_cache(actividad.base, actividad.perfil.id, llave, validada)
	if not validada.is_empty():
		actividad.aplicar_ruta_ia(validada)


func crear_bloques() -> void:
	intro = Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.theme_type_variation = &"Secundario"
	intro.hide()
	contenido.add_child(intro)
	contenido.move_child(intro, contenido.get_node("Titulo").get_index() + 1)
	retro = Label.new()
	retro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retro.hide()
	contenido.add_child(retro)
	contenido.move_child(retro, intro.get_index() + 1)
	roadmap_caja = MapaRuta.new()
	roadmap_caja.hide()
	contenido.add_child(roadmap_caja)
	contenido.move_child(roadmap_caja, intro.get_index() + 1)
	resultados_caja = VBoxContainer.new()
	resultados_caja.add_theme_constant_override("separation", 10)
	contenido.add_child(resultados_caja)
	contenido.move_child(resultados_caja, detalle.get_index() + 1)


func texto_intro() -> String:
	var total := actividad.items.size()
	match actividad.paso:
		"diagnostico":
			return "Este diagnóstico mide lo que ya sabes en cuatro temas. Son %d preguntas, unos %d minutos. No es una calificación: sirve para armar tu ruta de aprendizaje." % [total, maxi(5, total)]
		"ruta":
			var origen := "Ruta calculada sin IA."
			if actividad.origen_ruta == "ia":
				origen = "Ruta generada con IA."
			return "Tu ruta parte del diagnóstico. Hoy tienes %d preguntas en %d lecciones cortas. %s" % [
				total, actividad.plan.lecciones.size(), origen]
	return ""


func mostrar_roadmap() -> void:
	var instantanea := Actividad.Diagnostico.resultado(actividad.historial, true)
	var de_hoy := {}
	for leccion in actividad.plan.lecciones:
		de_hoy[leccion.competencia] = true
	var nodos := DatosMapa.armar(actividad.motivos_ruta(), instantanea, actividad.historial,
		Ordenes.listar().ordenes, actividad.detalle_ia, de_hoy)
	roadmap_caja.mostrar(nodos, actividad.fuentes_ia, actividad.detalle_ia)


func mostrar_retro() -> void:
	if ultima_retro.is_empty():
		retro.hide()
		return
	var correcta: bool = ultima_retro.correcta
	retro.text = ("Respuesta anterior: correcta." if correcta else "Respuesta anterior: incorrecta. La correcta era: %s." % ultima_retro.respuesta)
	retro.add_theme_color_override("font_color", Color("#5BE3A0") if correcta else Color("#F2B705"))
	retro.show()


func registrar_retro(respuesta: Variant) -> void:
	ultima_retro = {}
	if item.get("formato") == "opcion-multiple" and respuesta is int:
		var correcta := int(item.correcta)
		ultima_retro = {"correcta": respuesta == correcta,
			"respuesta": TextoLimpio.linea(str(item.opciones[correcta]))}


func nivel_color(dominio: float) -> Color:
	if dominio < 40:
		return Color("#E5604D")
	if dominio < 70:
		return Color("#F2B705")
	return Color("#5BE3A0")


func mostrar_barras() -> void:
	for hijo in resultados_caja.get_children():
		resultados_caja.remove_child(hijo)
		hijo.queue_free()
	var orden: Array = actividad.resultados.keys()
	orden.sort_custom(func(a: String, b: String) -> bool:
		return actividad.resultados[a].dominio < actividad.resultados[b].dominio)
	var confianza := {"alta": "buena", "baja": "poca"}
	for competencia in orden:
		var resultado: Dictionary = actividad.resultados[competencia]
		var caja := VBoxContainer.new()
		var rotulo := Label.new()
		rotulo.text = "%s · %d %% · %s · confianza %s" % [
			Actividad.Banco.COMPETENCIAS[competencia], roundi(resultado.dominio), resultado.nivel,
			confianza.get(resultado.confianza, resultado.confianza)]
		caja.add_child(rotulo)
		var barra := ProgressBar.new()
		barra.max_value = 100
		barra.value = resultado.dominio
		barra.show_percentage = false
		barra.custom_minimum_size.y = 12
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = nivel_color(resultado.dominio)
		relleno.set_corner_radius_all(6)
		barra.add_theme_stylebox_override("fill", relleno)
		caja.add_child(barra)
		resultados_caja.add_child(caja)
	if not orden.is_empty():
		var cierre := Label.new()
		cierre.text = "Empieza por: %s." % Actividad.Banco.COMPETENCIAS[orden[0]]
		cierre.theme_type_variation = &"Seccion"
		resultados_caja.add_child(cierre)


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
	intro.text = texto_intro()
	intro.visible = indice == 0 and not intro.text.is_empty()
	if actividad.paso == "ruta" and indice == 0:
		mostrar_roadmap()
	else:
		roadmap_caja.hide()
	mostrar_retro()
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
	retro.hide()
	intro.hide()
	roadmap_caja.hide()
	mostrar_barras()
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
	registrar_retro(respuesta)
	if actividad.responder(respuesta, Time.get_ticks_msec() - inicio_ms, fuente_entrada, ahora()):
		mostrar_item()
	else:
		ultima_retro = {}
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
