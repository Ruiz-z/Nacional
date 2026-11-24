extends PanelContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")
const MenuVisual = preload("res://escenas/menu_pieza.gd")
const FINALES := {
	"resuelto": "Orden resuelta",
	"falta-critica": "Detenida por una falta crítica",
	"estado-invalido": "No se pudo abrir la práctica",
	"limite-intentos": "Límite de intentos",
}

const EXITO := Color("#3FAE6A")
const AVISO := Color("#F2B705")
const PELIGRO := Color("#D64545")
const NEUTRO := Color("#A9C2CD")
const RESULTADOS := {
	"acierto": ["Acierto", EXITO],
	"leve": ["Error leve", AVISO],
	"error": ["Error", PELIGRO],
	"critica": ["Falta crítica", PELIGRO],
	"omitido": ["Omitido", NEUTRO],
	"corregido": ["Corregido", EXITO],
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
	resized.connect(ajustar_columnas)
	ajustar_columnas()
	mostrar(null)


func guardar(omitir: bool) -> void:
	if motor == null:
		return
	if not omitir and %Reflexion.text.strip_edges().is_empty():
		%Validacion.show()
		%Reflexion.grab_focus()
		%Desplazamiento.ensure_control_visible.call_deferred(%Validacion)
		return
	if motor.registrar_reflexion(%Reflexion.text, omitir):
		mostrar(motor)
		%Reintentar.grab_focus()
		%Desplazamiento.ensure_control_visible.call_deferred(%Ruta)


func mostrar(actual: RefCounted, datos_orden: Dictionary = {}, aviso := "") -> void:
	if not datos_orden.is_empty():
		escenario = datos_orden
		%Aviso.text = TextoLimpio.limpiar(aviso).texto
		%Aviso.visible = not aviso.is_empty()
	var abrir := motor != actual or not visible
	motor = actual
	var datos: Dictionary = {} if motor == null else motor.resumen()
	var disponible := not datos.is_empty()
	visible = disponible or get_parent() == get_tree().root
	%Vacio.visible = not disponible
	%Estado.visible = disponible
	%Orden.visible = disponible
	TextoLimpio.mostrar_chip(%Marca, escenario.get("titulo", "") if disponible else "")
	%Desplazamiento.visible = disponible
	%Acciones.visible = disponible
	if not disponible:
		%Reflexion.clear()
		%Validacion.hide()
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var reflexionado: bool = datos.has("ruta_ideal")
	%Estado.text = FINALES.get(datos.fin, "Práctica terminada")
	var colores := {"resuelto": EXITO, "falta-critica": PELIGRO, "limite-intentos": AVISO}
	colorear_chip(%Estado, colores.get(datos.fin, NEUTRO))
	%NombreOrden.text = TextoLimpio.limpiar(escenario.get("titulo", "")).texto
	ajustar_columnas()
	%Pregunta.text = datos.pregunta
	%Respuesta.visible = reflexionado
	%Respuesta.text = "Reflexión omitida" if datos.reflexion_omitida else TextoLimpio.limpiar(datos.reflexion).texto
	%Reflexion.visible = not reflexionado
	%Guardar.visible = not reflexionado
	%Omitir.visible = not reflexionado
	%Ruta.visible = reflexionado
	%Ruta.get_parent().get_parent().visible = reflexionado
	var acciones := [%Reintentar, %Volver] if reflexionado else [%Reflexion, %Guardar, %Omitir, %Reintentar, %Volver]
	for indice in acciones.size():
		var control: Control = acciones[indice]
		control.focus_next = control.get_path_to(acciones[(indice + 1) % acciones.size()])
		control.focus_previous = control.get_path_to(acciones[posmod(indice - 1, acciones.size())])
	if reflexionado:
		%Validacion.hide()
	mostrar_indicadores(datos)
	mostrar_pasos(datos.linea_tiempo)
	mostrar_diagnostico(datos.diagnostico_final)
	mostrar_comparacion(datos.comparacion)
	mostrar_brechas(datos.brechas)
	if reflexionado:
		var ruta := PackedStringArray()
		var fuentes := PackedStringArray()
		for indice in datos.ruta_ideal.size():
			var paso: Dictionary = datos.ruta_ideal[indice]
			ruta.append("%d. %s" % [indice + 1, TextoLimpio.limpiar(paso.descripcion).texto])
			var fuente := TextoLimpio.fuente(paso.fuente)
			if not fuente.is_empty() and fuente not in fuentes:
				fuentes.append(fuente)
		%Ruta.text = "\n".join(ruta)
		%FuenteRuta.text = "Fuente: " + "\nFuente: ".join(fuentes)
		%FuenteRuta.visible = not fuentes.is_empty()
	if abrir:
		%Desplazamiento.follow_focus = false
		(%Reintentar if reflexionado else %Reflexion).grab_focus()
		%Desplazamiento.follow_focus = true
		%Desplazamiento.scroll_vertical = 0


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
	if id == "diagnostico_final":
		return "Diagnóstico final"
	var acciones: Dictionary = escenario.get("acciones", {})
	var recuperaciones: Dictionary = escenario.get("recuperaciones", {})
	var regla: Dictionary = acciones.get(id, recuperaciones.get(id, {}))
	return TextoLimpio.limpiar(regla.get("titulo", "Paso de la orden")).texto


func ajustar_columnas() -> void:
	%Indicadores.columns = 4 if size.x >= 1080 else (2 if size.x >= 520 else 1)
	var ancho_titulo: float = %NombreOrden.get_theme_font("font").get_string_size(
		%NombreOrden.text, HORIZONTAL_ALIGNMENT_LEFT, -1, %NombreOrden.get_theme_font_size("font_size")).x
	var cabe: bool = ancho_titulo + %Marca.get_minimum_size().x + 64 <= size.x
	%NombreOrden.autowrap_mode = TextServer.AUTOWRAP_OFF if cabe else TextServer.AUTOWRAP_WORD_SMART
	%NombreOrden.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if cabe else Control.SIZE_EXPAND_FILL
	%Columnas.columns = 2 if size.x >= 960 else 1


static func plural_errores(cantidad: int) -> String:
	return "%d error%s" % [cantidad, "" if cantidad == 1 else "es"]


static func formato_tiempo(milisegundos: int) -> String:
	var segundos := floori(milisegundos / 1000.0)
	if segundos < 1:
		return "menos de 1 s"
	if segundos < 60:
		return "%d s" % segundos
	return "%d min %d s" % [floori(segundos / 60.0), segundos % 60]


func etiqueta(padre: Control, texto: String, estilo := &"Label") -> Label:
	var nueva := Label.new()
	nueva.theme_type_variation = estilo
	nueva.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nueva.text = texto
	padre.add_child(nueva)
	return nueva


func colorear_chip(chip: Label, color: Color) -> void:
	var fondo := chip.get_theme_stylebox("normal", "Chip").duplicate() as StyleBoxFlat
	fondo.bg_color = Color("#0E1A22").lerp(color, 0.23)
	fondo.border_color = color
	chip.add_theme_stylebox_override("normal", fondo)


func limpiar_tarjeta(contenido: Control, desde := 1) -> void:
	for indice in range(contenido.get_child_count() - 1, desde - 1, -1):
		var hijo := contenido.get_child(indice)
		contenido.remove_child(hijo)
		hijo.queue_free()


func indicador(titulo: String, valor: String, color := Color.WHITE) -> VBoxContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%Indicadores.add_child(tarjeta)
	var contenido := VBoxContainer.new()
	tarjeta.add_child(contenido)
	etiqueta(contenido, titulo, &"Metadato")
	etiqueta(contenido, valor, &"Valor").add_theme_color_override("font_color", color)
	return contenido


func mostrar_indicadores(datos: Dictionary) -> void:
	limpiar_tarjeta(%Indicadores, 0)
	var actual: Dictionary = datos.comparacion.actual
	var anterior: Dictionary = datos.comparacion.anterior
	var puntos := indicador("Puntos", "%d de 100" % actual.puntaje)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size.y = 8
	barra.value = actual.puntaje
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puntos.add_child(barra)
	if not anterior.is_empty():
		var cambio: int = actual.puntaje - anterior.puntaje
		var texto := "Sin cambio respecto al intento anterior"
		if cambio != 0:
			texto = "%s %+d respecto al intento anterior" % [flecha(cambio), cambio]
		etiqueta(puntos, texto, &"Secundario").add_theme_color_override("font_color", color_cambio(cambio))
	var errores := indicador("Errores", plural_errores(actual.errores))
	if not datos.errores.is_empty():
		var criticos: int = datos.errores.filter(func(error: Dictionary) -> bool:
			return error.criticidad == "critica").size()
		var leves: int = datos.errores.filter(func(error: Dictionary) -> bool:
			return error.criticidad == "leve").size()
		if criticos + leves > 0:
			etiqueta(errores, "%d críticos / %d leves" % [criticos, leves], &"Secundario")
	if datos.has("errores_arnes"):
		etiqueta(errores, "Medición: %d\nInterpretación: %d" % [
			datos.errores_arnes.medicion, datos.errores_arnes.interpretacion], &"Secundario")
	indicador("Tiempo", formato_tiempo(actual.tiempo_ms))
	var cierre: Dictionary = datos.diagnostico_final
	indicador("Diagnóstico", estado_diagnostico(cierre),
		NEUTRO if cierre.is_empty() else color_cambio(1 if cierre.correcto else -1))


static func estado_diagnostico(cierre: Dictionary) -> String:
	if cierre.is_empty():
		return "Sin respuesta"
	return "Correcto" if cierre.correcto else "Incorrecto"


static func estado_paso(decision: Dictionary) -> String:
	if decision.criticidad == "critica":
		return "critica"
	if decision.tipo_error == "paso-omitido":
		return "omitido"
	if decision.aplicada and decision.tipo_error.is_empty():
		return "acierto"
	return "leve" if decision.criticidad == "leve" else "error"


static func agrupar_pasos(decisiones: Array) -> Array[Dictionary]:
	var grupos: Array[Dictionary] = []
	var anterior_por_accion := {}
	for decision in decisiones:
		var accion: String = decision.accion
		if grupos.is_empty() or grupos[-1].accion != accion:
			grupos.append({"accion": accion, "decisiones": [], "resultados": []})
		var grupo := grupos[-1]
		var estado := estado_paso(decision)
		var corregido: bool = estado == "acierto" and anterior_por_accion.get(accion) in ["leve", "error", "omitido"]
		grupo.decisiones.append(decision)
		grupo.resultados.append("corregido" if corregido else estado)
		anterior_por_accion[accion] = estado
	return grupos


func mostrar_pasos(decisiones: Array) -> void:
	limpiar_tarjeta(%Detalle, 0)
	var grupos := agrupar_pasos(decisiones)
	if grupos.is_empty():
		etiqueta(%Detalle, "Todavía no registraste pasos.", &"Secundario")
	for indice in grupos.size():
		var grupo := grupos[indice]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		%Detalle.add_child(fila)
		var marca := VBoxContainer.new()
		marca.add_theme_constant_override("separation", 0)
		fila.add_child(marca)
		var texto := VBoxContainer.new()
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texto.add_theme_constant_override("separation", 3)
		fila.add_child(texto)
		var titulo := nombre_accion(grupo.accion)
		if grupo.decisiones.size() > 1:
			titulo += " ×%d" % grupo.decisiones.size()
		etiqueta(texto, titulo, &"Metadato")
		var vistos := {}
		for intento in grupo.decisiones.size():
			var decision: Dictionary = grupo.decisiones[intento]
			var resultado: String = grupo.resultados[intento]
			var motivo: String = TextoLimpio.limpiar(decision.motivo).texto
			if motivo.is_empty() and resultado not in ["acierto", "omitido", "corregido"]:
				motivo = "Revisa el siguiente paso de la orden."
			var detalle: String = RESULTADOS[resultado][0]
			if not motivo.is_empty():
				detalle += ". " + motivo
			if detalle not in vistos:
				vistos[detalle] = true
				var rotulo := etiqueta(texto, detalle, &"Secundario")
				if resultado == "corregido":
					rotulo.add_theme_color_override("font_color", color_cambio(1))
		var punto := Panel.new()
		var circulo := StyleBoxFlat.new()
		circulo.bg_color = RESULTADOS[grupo.resultados[-1]][1]
		circulo.set_corner_radius_all(6)
		punto.add_theme_stylebox_override("panel", circulo)
		punto.custom_minimum_size = Vector2(12, 12)
		marca.add_child(punto)
		if indice < grupos.size() - 1:
			var linea := ColorRect.new()
			linea.color = Color("#6792A8")
			linea.custom_minimum_size.x = 2
			linea.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			linea.size_flags_vertical = Control.SIZE_EXPAND_FILL
			linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
			marca.add_child(linea)
			var espacio := Control.new()
			espacio.custom_minimum_size.y = 12
			texto.add_child(espacio)


func mostrar_diagnostico(cierre: Dictionary) -> void:
	var tarjeta: VBoxContainer = %DiagnosticoContenido
	limpiar_tarjeta(tarjeta)
	etiqueta(tarjeta, "¿Qué causó la falla?", &"Metadato")
	if cierre.is_empty():
		etiqueta(tarjeta, "No respondiste el diagnóstico en este intento.", &"Secundario")
		return
	fila_diagnostico(tarjeta, "Tu respuesta", cierre.elegida, cierre.correcto)
	fila_diagnostico(tarjeta, "Causa real", cierre.real, true)
	var explicacion: String = TextoLimpio.limpiar(cierre.explicacion).texto
	if not explicacion.is_empty():
		etiqueta(tarjeta, explicacion, &"Secundario")
	var fuente := TextoLimpio.fuente(cierre.fuente)
	if not fuente.is_empty():
		etiqueta(tarjeta, "Fuente: " + fuente, &"Secundario")


func fila_diagnostico(tarjeta: VBoxContainer, titulo: String, causa: String, correcto: bool) -> void:
	var fila := HBoxContainer.new()
	tarjeta.add_child(fila)
	etiqueta(fila, "%s: %s" % [titulo, MenuVisual.nombre_causa(causa)]).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chip := etiqueta(fila, "Correcto" if correcto else "Incorrecto", &"Chip")
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	colorear_chip(chip, EXITO if correcto else PELIGRO)


static func flecha(cambio: int) -> String:
	return "↑" if cambio > 0 else "↓"


static func color_cambio(cambio: int) -> Color:
	if cambio == 0:
		return NEUTRO
	return Color("#A8F0BE") if cambio > 0 else Color("#FFD0CB")


func mostrar_comparacion(comparacion: Dictionary) -> void:
	var tarjeta: VBoxContainer = %ComparacionContenido
	tarjeta.get_parent().visible = not comparacion.anterior.is_empty()
	limpiar_tarjeta(tarjeta)
	if comparacion.anterior.is_empty():
		return
	var columnas := GridContainer.new()
	columnas.columns = 2
	columnas.add_theme_constant_override("h_separation", 16)
	tarjeta.add_child(columnas)
	for titulo in ["Antes", "Ahora"]:
		etiqueta(columnas, titulo, &"Metadato").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var anterior: Dictionary = comparacion.anterior
	var actual: Dictionary = comparacion.actual
	var filas := [
		["%d puntos" % anterior.puntaje, "%d puntos" % actual.puntaje, actual.puntaje - anterior.puntaje, 1],
		[plural_errores(anterior.errores), plural_errores(actual.errores), actual.errores - anterior.errores, -1],
		[formato_tiempo(anterior.tiempo_ms), formato_tiempo(actual.tiempo_ms), actual.tiempo_ms - anterior.tiempo_ms, -1],
	]
	for fila in filas:
		etiqueta(columnas, fila[0], &"Secundario")
		var cambio: int = fila[2]
		var texto: String = fila[1]
		if cambio != 0:
			texto += "  %s %s" % [flecha(cambio), "Mejoró" if cambio * fila[3] > 0 else "Empeoró"]
		etiqueta(columnas, texto, &"Secundario").add_theme_color_override("font_color", color_cambio(cambio * fila[3]))


func mostrar_brechas(brechas: Array) -> void:
	var tarjeta: VBoxContainer = %BrechasContenido
	tarjeta.get_parent().visible = not brechas.is_empty()
	limpiar_tarjeta(tarjeta)
	for brecha in brechas:
		etiqueta(tarjeta, "Elegiste %s e hiciste este paso: %s." % [
			MenuVisual.nombre_causa(brecha.causa_marcada), nombre_accion(brecha.accion_ejecutada)], &"Secundario")
