extends VBoxContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")

const Consultas = preload("res://logica/tablero/consultas.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const MenuPieza = preload("res://escenas/menu_pieza.gd")
const Banco = preload("res://logica/competencias/banco.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")
const Evidencia = preload("res://logica/tablero/evidencia.gd")
const Recomendacion = preload("res://logica/tablero/recomendacion.gd")
const Resultados = preload("res://logica/tablero/resultados.gd")
const COLORES_ESTADO := [Color("#d64545"), Color("#f2b705"), Color("#ecfafa"), Color("#3fae6a")]
const COLUMNAS_COMPETENCIA := ["Seguridad", "Eléctrico y batería", "Diagnóstico", "Electrónica"]
const COLORES_NIVEL := {
	"Novato": Color("#d64545"),
	"Básico": Color("#f2b705"),
	"Competente": Color("#1aa7a6"),
	"Experto": Color("#3fae6a"),
}

var base := ""
var alias_actual := ""
var jefe_directo := false
# Rol de quien abre el tablero (tecnico, jefe o admin). Sin rol no se entrega nada.
var rol := ""
var alias_ficha := ""
var ordenes := {}
var botones_tecnicos := {}
@onready var datos: VBoxContainer = $Contenido/Datos
@onready var contenido: ScrollContainer = $Contenido


func _ready() -> void:
	$Vistas/Tecnico.pressed.connect(func(): cambiar_vista(false))
	$Vistas/JefeDirecto.pressed.connect(func(): cambiar_vista(true))
	$Vistas/Ayuda.toggled.connect(func(_visible: bool): mostrar())
	$Vistas/VolverLista.pressed.connect(volver_lista)
	$Vistas/Exportar.pressed.connect(abrir_exportacion)
	$GuardarResultados.file_selected.connect(exportar)
	cambiar_vista(false)
	$Vistas/Tecnico.grab_focus()


func cambiar_vista(es_jefe: bool) -> void:
	jefe_directo = es_jefe
	alias_ficha = ""
	$Vistas/Tecnico.theme_type_variation = &"" if jefe_directo else &"Primario"
	$Vistas/JefeDirecto.theme_type_variation = &"Primario" if jefe_directo else &""
	$Vistas/Ayuda.set_pressed_no_signal(false)
	mostrar()


func mostrar() -> void:
	for hijo in datos.get_children():
		datos.remove_child(hijo)
		hijo.queue_free()
	botones_tecnicos.clear()
	contenido.scroll_vertical = 0
	$Titulo.theme_type_variation = &"Seccion" if jefe_directo else &"Titulo"
	$Subtitulo.visible = not jefe_directo
	$Vistas/Ayuda.text = "Cómo se calcula" if jefe_directo else "Cómo se calcula tu progreso"
	$Vistas/VolverLista.visible = jefe_directo and not alias_ficha.is_empty()
	$Vistas/Exportar.visible = $Vistas/VolverLista.visible
	if $Vistas/Ayuda.button_pressed:
		linea(Vistas.AYUDA)
		if jefe_directo:
			linea(Vistas.AYUDA_JEFE)
		return
	if jefe_directo:
		if alias_ficha.is_empty():
			mostrar_lista()
		else:
			mostrar_ficha()
		return
	var perfil := Consultas.tecnico(base, alias_actual) if not base.is_empty() and not alias_actual.is_empty() else {}
	if perfil.is_empty() or perfil.estado == "sin_sesiones":
		if not perfil.is_empty():
			linea(perfil.alias, &"Chip")
		var indicadores := fila_indicadores()
		indicador(indicadores, "Ganancia indicativa", "Pendiente", "Completa el diagnóstico y la evaluación")
		indicador(indicadores, "Retención simulada", "Pendiente", "Completa la evaluación y repítela")
		indicador(indicadores, "Faltas críticas", "—", "Sin prácticas registradas")
		var mensaje := tarjeta(datos)
		linea("Aún no hay resultados para mostrar", &"Seccion", mensaje)
		var detalle := "Completa tu primera actividad para empezar a ver tu progreso aquí."
		if perfil.is_empty():
			detalle = "Elige un alias desde el menú o abre el tablero del modo demo para explorar un historial de ejemplo."
		linea(detalle, &"Secundario", mensaje)
		return
	linea(perfil.alias, &"Chip")
	var indicadores := fila_indicadores()
	indicador(indicadores, "Ruta de aprendizaje", str(perfil.avance_ruta.completadas),
		"%d microlecciones pendientes" % perfil.avance_ruta.pendientes)
	indicador(indicadores, "Faltas críticas", str(perfil.faltas_criticas.conteo),
		"Última · %s" % perfil.faltas_criticas.ultima if perfil.faltas_criticas.ultima != null else "Sin faltas registradas")
	indicador(indicadores, "Brechas registradas", str(perfil.brechas.size()), "Diagnóstico frente a acción")
	if not perfil.errores_arnes.is_empty():
		linea("Banco de arnés", &"Seccion")
		var fila_banco := fila_indicadores()
		indicador(fila_banco, "Errores de medición", str(perfil.errores_arnes.medicion),
			"Punto, lectura reportada o paso omitido")
		indicador(fila_banco, "Errores de interpretación", str(perfil.errores_arnes.interpretacion),
			"Causa elegida tras lecturas correctas")
	linea("Dominio por competencia", &"Seccion")
	var filas: Array[Array] = []
	for competencia in perfil.competencias:
		var valor: Dictionary = perfil.competencias[competencia]
		var nombre_competencia: String = Banco.COMPETENCIAS.get(competencia, competencia)
		linea("%s · %s · Confianza %s" % [nombre_competencia, valor.nivel.capitalize(),
			valor.confianza], &"Chip")
		if valor.dominio is float or valor.dominio is int:
			var barra := ProgressBar.new()
			barra.value = valor.dominio
			barra.custom_minimum_size.y = 24
			var relleno := barra.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
			relleno.bg_color = COLORES_NIVEL[valor.nivel]
			relleno.border_color = relleno.bg_color
			barra.add_theme_stylebox_override("fill", relleno)
			barra.show_percentage = false
			datos.add_child(barra)
			linea("%.1f %% de dominio · Nivel %s" % [valor.dominio, valor.nivel], &"Secundario")
			linea("Ganancia y Retención simulada · %s" % nombre_competencia, &"Secundario")
			var tendencia_competencia := fila_indicadores()
			indicador(tendencia_competencia, "Ganancia indicativa",
				tendencia(valor.ganancia, 0, " pts"), "Post-test − diagnóstico")
			indicador(tendencia_competencia, "Retención simulada",
				tendencia(valor.retencion, 100, " %"), "Retest ÷ post-test")
		for error in valor.errores_recurrentes:
			var casos := PackedStringArray()
			for intento in perfil.intentos:
				if intento.competencia == competencia and intento.tipo_error == error and not casos.has(intento.item):
					casos.append(intento.item)
			filas.append(["Error recurrente", nombre_competencia,
				"%s · %s" % [error.replace("-", " ").capitalize(), ", ".join(casos)],
				str(valor.errores_recurrentes[error])])
		for brecha in valor.detalle_brechas:
			filas.append(["Brecha", nombre_competencia, "%s · %s → %s" % [
				nombre_orden(brecha.caso), MenuPieza.nombre_causa(brecha.causa_marcada),
				nombre_accion(brecha.caso, brecha.accion_ejecutada)], "1"])
		if valor.brechas > valor.detalle_brechas.size():
			filas.append(["Brecha", nombre_competencia, "Sin caso asociado",
				str(valor.brechas - valor.detalle_brechas.size())])
	mostrar_tabla(filas)
	linea("Actividad y recorrido", &"Seccion")
	linea("Ruta: %d completadas · %d pendientes" % [perfil.avance_ruta.completadas, perfil.avance_ruta.pendientes])
	for paso in perfil.ruta:
		if paso is String:
			linea("Pendiente: %s" % Banco.COMPETENCIAS.get(paso, paso))
		elif paso is Dictionary:
			linea("Pendiente: %s" % paso.get("titulo", paso.get("competencia", paso.get("id", ""))))
	linea("Faltas críticas: %d · última: %s" % [perfil.faltas_criticas.conteo,
		perfil.faltas_criticas.ultima if perfil.faltas_criticas.ultima != null else "pendiente"])
	for escenario in perfil.tiempos_por_escenario:
		for accion in perfil.tiempos_por_escenario[escenario]:
			linea("%s · %s · promedio %.0f ms" % [nombre_orden(escenario),
				nombre_accion(escenario, accion), perfil.tiempos_por_escenario[escenario][accion]])
	var comparacion := Vistas.ultimas_sesiones(Vistas.sesiones(perfil.intentos))
	for competencia in comparacion:
		linea(Banco.COMPETENCIAS.get(competencia, competencia))
		for sesion in comparacion[competencia]:
			mostrar_sesion(sesion)


func mostrar_historial(perfil: Dictionary, sesiones: Array, padre: Control) -> void:
	if not perfil.errores_arnes.is_empty():
		linea("Banco de arnés · %s de medición · %s de interpretación" % [
			cantidad(perfil.errores_arnes.medicion, "error", "errores"),
			cantidad(perfil.errores_arnes.interpretacion, "error", "errores")], &"", padre)
	for competencia in perfil.competencias:
		var valores: Dictionary = perfil.competencias[competencia].dominios_evaluaciones
		linea("%s · Diagnóstico %s · Evaluación %s · Retest simulado %s" % [Banco.COMPETENCIAS[competencia],
			valores.get("pre", "pendiente"), valores.get("post", "pendiente"), valores.get("retest", "pendiente")], &"", padre)
	linea("Línea de tiempo", &"Seccion", padre)
	for sesion in sesiones:
		mostrar_sesion(sesion, padre)
	for intento in perfil.intentos:
		linea("%s · Pregunta %s · Entrada %s · Versión %s" % [
			intento.reloj_sim, intento.item, intento.fuente_entrada, intento.version_contenido], &"", padre)
	for evento in perfil.eventos:
		linea("%s · Evento %s · Entrada %s · Fuente %s · Versión %s" % [
			evento.reloj_sim, nombre_accion(evento.get("escenario", ""), evento.accion), evento.fuente_entrada,
			TextoLimpio.fuente(evento.get("fuente", "pendiente")),
			evento.get("version_contenido", "pendiente")], &"", padre)


func orden(id: String) -> Dictionary:
	if id.is_empty() or not id.is_valid_identifier():
		return {}
	if not ordenes.has(id):
		var datos_orden := Escenario.cargar("escenarios/%s.json" % id)
		ordenes[id] = datos_orden.get("escenario", {})
	return ordenes[id]


func nombre_orden(id: String) -> String:
	return TextoLimpio.limpiar(orden(id).get("titulo", "Orden de servicio")).texto


func nombre_accion(id_orden: String, id_accion: String) -> String:
	if id_accion == "diagnostico_final":
		return "Diagnóstico final"
	var datos_orden := orden(id_orden)
	var acciones: Dictionary = datos_orden.get("acciones", {})
	var recuperaciones: Dictionary = datos_orden.get("recuperaciones", {})
	var regla: Dictionary = acciones.get(id_accion, recuperaciones.get(id_accion, {}))
	return TextoLimpio.limpiar(regla.get("titulo", "Paso de la orden")).texto


func mostrar_sesion(sesion: Dictionary, padre: Control = null) -> void:
	linea("%s · %s · %s · %.1f %%" % [sesion.fecha,
		"retest simulado" if sesion.momento == "retest" else sesion.momento,
		Banco.COMPETENCIAS.get(sesion.competencia, sesion.competencia), sesion.dominio], &"", padre)


func fila_indicadores() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	datos.add_child(fila)
	return fila


func tarjeta(padre: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(panel)
	var interior := VBoxContainer.new()
	panel.add_child(interior)
	return interior


func indicador(padre: HBoxContainer, titulo: String, valor: String, contexto: String) -> void:
	var interior := tarjeta(padre)
	linea(titulo, &"Metadato", interior)
	linea(valor.capitalize() if valor == "pendiente" else valor, &"Valor", interior)
	linea(contexto, &"Secundario", interior)


func mostrar_tabla(filas: Array[Array]) -> void:
	var interior := tarjeta(datos)
	linea("Errores recurrentes y brechas", &"Seccion", interior)
	if filas.is_empty():
		linea("Aquí verás errores que repitas y diferencias entre tu diagnóstico y lo que hiciste.", &"Secundario", interior)
		return
	var tabla := GridContainer.new()
	tabla.columns = 4
	tabla.add_theme_constant_override("h_separation", 24)
	tabla.add_theme_constant_override("v_separation", 12)
	interior.add_child(tabla)
	for encabezado in ["Tipo", "Competencia", "Caso o error", "Total"]:
		linea(encabezado, &"Metadato", tabla)
	for fila in filas:
		for celda in fila:
			linea(celda, &"", tabla)


func linea(texto: String, estilo: StringName = &"", padre: Control = null) -> void:
	var etiqueta := Label.new()
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.text = TextoLimpio.linea(texto)
	etiqueta.theme_type_variation = estilo
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(datos if padre == null else padre).add_child(etiqueta)


static func tendencia(valor: Variant, referencia: float, unidad: String) -> String:
	if valor is String:
		return valor
	var flecha := "↑" if valor > referencia else ("↓" if valor < referencia else "→")
	return "%s %.1f%s" % [flecha, valor, unidad]


func perfil_jefe(nombre: String) -> Dictionary:
	var perfil := Consultas.tecnico(base, nombre)
	if perfil.is_empty():
		return {}
	var competencias_por_accion := {}
	var ultima := ""
	for registro in perfil.intentos + perfil.eventos + perfil.brechas:
		var fecha: String = registro.reloj_sim
		if fecha > ultima:
			ultima = fecha
	for evento in perfil.eventos:
		var id: String = evento.escenario
		if competencias_por_accion.has(id):
			continue
		var escenario := orden(id)
		var mapa := {}
		var acciones: Dictionary = escenario.get("acciones", {}).merged(escenario.get("recuperaciones", {}))
		for accion in acciones:
			mapa[accion] = acciones[accion].get("competencia", "")
		var pasos: Array = escenario.get("ruta_ideal", [])
		if not pasos.is_empty():
			mapa["diagnostico_final"] = mapa.get(pasos[0], "")
		competencias_por_accion[id] = mapa
	perfil.competencias_por_accion = competencias_por_accion
	perfil.ultima_actividad = ultima
	perfil.recomendacion = Recomendacion.calcular(perfil)
	return perfil


func mostrar_lista() -> void:
	linea("Técnicos", &"Titulo")
	var perfiles: Array[Dictionary] = []
	if not base.is_empty():
		for nombre in Vistas.aliases(base, rol, alias_actual):
			var perfil := perfil_jefe(nombre)
			if not perfil.is_empty():
				perfiles.append(perfil)
	if perfiles.is_empty():
		linea("Aún no hay técnicos registrados.", &"Secundario")
		return
	perfiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.recomendacion.prioridad != b.recomendacion.prioridad:
			return a.recomendacion.prioridad < b.recomendacion.prioridad
		return a.alias.naturalnocasecmp_to(b.alias) < 0)

	var tabla := GridContainer.new()
	tabla.columns = 7
	tabla.add_theme_constant_override("h_separation", 16)
	tabla.add_theme_constant_override("v_separation", 10)
	datos.add_child(tabla)
	for texto in ["Alias", "Estado"] + COLUMNAS_COMPETENCIA + ["Última actividad"]:
		linea(texto, &"Metadato", tabla)
	for perfil in perfiles:
		var abrir := Button.new()
		abrir.text = alias_visible(perfil)
		abrir.tooltip_text = "Abrir ficha de " + abrir.text
		abrir.clip_text = true
		abrir.custom_minimum_size = Vector2(150, 46)
		abrir.alignment = HORIZONTAL_ALIGNMENT_LEFT
		abrir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nombre: String = perfil.alias
		abrir.pressed.connect(func(): abrir_ficha(nombre))
		tabla.add_child(abrir)
		botones_tecnicos[nombre] = abrir

		var estado := estado_visible(perfil.recomendacion, tabla)
		estado.custom_minimum_size.x = 157
		for id in Banco.COMPETENCIAS:
			var nivel: Dictionary = perfil.competencias[id]
			var celda := VBoxContainer.new()
			celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			celda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tabla.add_child(celda)
			linea(nivel.nivel.capitalize(), &"Secundario", celda)
			barra_dominio(nivel.dominio, celda)
		linea(fecha_visible(perfil.ultima_actividad, false), &"Secundario", tabla)


func abrir_ficha(nombre: String) -> void:
	alias_ficha = nombre
	$Vistas/Ayuda.set_pressed_no_signal(false)
	mostrar()
	$Vistas/VolverLista.grab_focus()


func volver_lista() -> void:
	var anterior := alias_ficha
	alias_ficha = ""
	$Vistas/Ayuda.set_pressed_no_signal(false)
	mostrar()
	var boton: Button = botones_tecnicos.get(anterior)
	if boton != null:
		boton.grab_focus()


func mostrar_ficha() -> void:
	var perfil := perfil_jefe(alias_ficha)
	if perfil.is_empty():
		linea("No se pudo abrir este historial.", &"Secundario")
		return
	var recomendacion: Dictionary = perfil.recomendacion
	var identidad := HBoxContainer.new()
	datos.add_child(identidad)
	linea(alias_visible(perfil), &"Seccion", identidad)
	var estado := estado_visible(recomendacion, identidad)
	estado.size_flags_horizontal = Control.SIZE_SHRINK_END
	separador(datos)

	linea("Recomendación", &"Metadato")
	linea(recomendacion.mensaje, &"Titulo")
	for respaldo in recomendacion.evidencias:
		linea(respaldo)
	linea(recomendacion.pie, &"Secundario")
	separador(datos)

	linea("Evidencia por competencia", &"Seccion")
	var evidencia := Evidencia.calcular(perfil.intentos, perfil.eventos, perfil.competencias_por_accion)
	var cuadricula := GridContainer.new()
	cuadricula.columns = 2
	cuadricula.add_theme_constant_override("h_separation", 30)
	cuadricula.add_theme_constant_override("v_separation", 16)
	datos.add_child(cuadricula)
	for id in Banco.COMPETENCIAS:
		var bloque := VBoxContainer.new()
		bloque.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bloque.add_theme_constant_override("separation", 5)
		cuadricula.add_child(bloque)
		mostrar_competencia(id, perfil.competencias[id], evidencia[id], bloque)
	separador(datos)
	linea("Faltas críticas", &"Seccion")
	if recomendacion.faltas.is_empty():
		linea("Sin faltas registradas.", &"Secundario")
	for falta in recomendacion.faltas:
		linea("%s · %s" % [fecha_visible(falta.fecha), Banco.COMPETENCIAS.get(falta.competencia, "Competencia sin registrar")])

	separador(datos)
	linea("Ganancia y retención", &"Seccion")
	for id in Banco.COMPETENCIAS:
		var nivel: Dictionary = perfil.competencias[id]
		linea("%s · Ganancia indicativa %s · Retención (retest simulado) %s" % [Banco.COMPETENCIAS[id],
			tendencia(nivel.ganancia, 0, " pts"), tendencia(nivel.retencion, 100, " %")])
	separador(datos)
	linea("Ruta pendiente", &"Seccion")
	if perfil.ruta.is_empty():
		linea("Sin actividades pendientes registradas.", &"Secundario")
	for paso in perfil.ruta:
		if paso is String:
			linea(Banco.COMPETENCIAS.get(paso, paso))
		elif paso is Dictionary:
			var id: String = paso.get("competencia", paso.get("id", ""))
			linea(paso.get("titulo", Banco.COMPETENCIAS.get(id, id)))

	var historial := desplegable("Ver historial", datos, &"AbrirHistorial")
	mostrar_historial(perfil, Vistas.sesiones(perfil.intentos), historial)


func mostrar_competencia(id: String, nivel: Dictionary, evidencia: Dictionary, bloque: VBoxContainer) -> void:
	separador(bloque)
	linea(Banco.COMPETENCIAS[id], &"Seccion", bloque)
	var pct := " · %.1f %%" % nivel.dominio if nivel.dominio is float or nivel.dominio is int else ""
	linea(nivel.nivel.capitalize() + pct, &"Metadato", bloque)
	barra_dominio(nivel.dominio, bloque)
	linea("%s · %s · %s" % [
		cantidad(evidencia.teoria, "respuesta", "respuestas"),
		cantidad(evidencia.practicas, "práctica virtual", "prácticas virtuales"),
		cantidad(evidencia.banco, "caso con banco", "casos con banco")], &"", bloque)
	linea("%s en %s · %s" % [cantidad(evidencia.errores, "error", "errores"),
		cantidad(evidencia.oportunidades, "oportunidad", "oportunidades"),
		cantidad(evidencia.sin_ayuda, "intento sin ayuda", "intentos sin ayuda")], &"Secundario", bloque)
	for tipo in nivel.errores_recurrentes:
		linea("%s · %d veces" % [Recomendacion.nombre_error(tipo).capitalize(),
			nivel.errores_recurrentes[tipo]], &"", bloque)
	if nivel.errores_recurrentes.is_empty():
		linea("Sin errores recurrentes.", &"Secundario", bloque)
	if not nivel.detalle_brechas.is_empty():
		var brechas := desplegable(cantidad(nivel.brechas, "brecha", "brechas"), bloque)
		for brecha in nivel.detalle_brechas:
			linea("%s · %s → %s" % [nombre_orden(brecha.caso), MenuPieza.nombre_causa(brecha.causa_marcada),
				nombre_accion(brecha.caso, brecha.accion_ejecutada)], &"", brechas)
	if evidencia.tiempos.is_empty():
		linea("0 acciones con tiempo registrado.", &"Secundario", bloque)
	else:
		var tiempos := desplegable("Tiempo medio por acción", bloque)
		for escenario in evidencia.tiempos:
			for accion in evidencia.tiempos[escenario]:
				var nombre: String = ("Respuesta " + accion) if escenario.is_empty() else nombre_accion(escenario, accion)
				linea("%s · %.0f ms" % [nombre, evidencia.tiempos[escenario][accion]], &"Secundario", tiempos)


func desplegable(titulo: String, padre: Control, nombre: StringName = &"") -> VBoxContainer:
	var boton := CheckButton.new()
	if not nombre.is_empty():
		boton.name = nombre
	boton.text = titulo
	boton.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	padre.add_child(boton)
	var detalle := VBoxContainer.new()
	detalle.hide()
	padre.add_child(detalle)
	boton.toggled.connect(func(activo: bool): detalle.visible = activo)
	return detalle


func estado_visible(recomendacion: Dictionary, padre: Control) -> HBoxContainer:
	var grupo := HBoxContainer.new()
	grupo.add_theme_constant_override("separation", 8)
	grupo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	padre.add_child(grupo)
	var marca := ColorRect.new()
	marca.color = COLORES_ESTADO[recomendacion.prioridad]
	marca.custom_minimum_size = Vector2(8, 8)
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grupo.add_child(marca)
	var etiqueta := Label.new()
	etiqueta.text = TextoLimpio.linea(recomendacion.estado)
	etiqueta.theme_type_variation = &"Metadato"
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	etiqueta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	grupo.add_child(etiqueta)
	return grupo


func barra_dominio(dominio: Variant, padre: Control) -> void:
	var barra := ProgressBar.new()
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color("#c0d4dc")
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#31444d")
	barra.add_theme_stylebox_override("fill", relleno)
	barra.add_theme_stylebox_override("background", fondo)
	barra.custom_minimum_size.y = 6
	barra.show_percentage = false
	barra.value = float(dominio) if dominio is float or dominio is int else 0.0
	padre.add_child(barra)


func separador(padre: Control) -> void:
	var linea_divisoria := HSeparator.new()
	var estilo := StyleBoxLine.new()
	estilo.color = Color("#31444d")
	linea_divisoria.add_theme_stylebox_override("separator", estilo)
	padre.add_child(linea_divisoria)


func abrir_exportacion() -> void:
	$GuardarResultados.current_file = "resultados"
	$GuardarResultados.popup_centered_clamped()


func exportar(destino: String) -> void:
	var correcto := Resultados.exportar(base, destino, destino.get_extension(), alias_ficha, rol)
	$AvisoExportacion.dialog_text = "Guardaste los resultados." if correcto else "No se pudo guardar. Elige otra carpeta e inténtalo de nuevo."
	$AvisoExportacion.popup_centered()


static func cantidad(numero: int, singular: String, plural: String) -> String:
	return "%d %s" % [numero, singular if numero == 1 else plural]


static func alias_visible(perfil: Dictionary) -> String:
	var alias_limpio: String = TextoLimpio.limpiar(perfil.alias).texto
	return alias_limpio + " · Demo" if perfil.demo else alias_limpio


static func fecha_visible(fecha: String, hora: bool = true) -> String:
	if fecha.is_empty():
		return "Sin actividad"
	return fecha.replace("T", " ").trim_suffix("Z") if hora else fecha.get_slice("T", 0)
