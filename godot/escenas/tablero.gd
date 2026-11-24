extends VBoxContainer

const Consultas = preload("res://logica/tablero/consultas.gd")
const Banco = preload("res://logica/competencias/banco.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")
const COLORES_NIVEL := {
	"Novato": Color("#d64545"),
	"Básico": Color("#f2b705"),
	"Competente": Color("#1aa7a6"),
	"Experto": Color("#3fae6a"),
}

var base := ""
var alias_actual := ""
var instructor := false
@onready var datos := $Contenido/Datos
@onready var lista := $Alias


func _ready() -> void:
	$Vistas/Tecnico.pressed.connect(func(): cambiar_vista(false))
	$Vistas/Instructor.pressed.connect(func(): cambiar_vista(true))
	$Vistas/Ayuda.toggled.connect(func(_visible: bool): mostrar())
	lista.item_selected.connect(func(_indice: int): mostrar())
	cambiar_vista(false)
	$Vistas/Tecnico.grab_focus()


func cambiar_vista(es_instructor: bool) -> void:
	instructor = es_instructor
	$Vistas/Tecnico.theme_type_variation = &"" if instructor else &"Primario"
	$Vistas/Instructor.theme_type_variation = &"Primario" if instructor else &""
	lista.visible = instructor
	lista.clear()
	if instructor and not base.is_empty():
		for nombre in Vistas.aliases(base):
			lista.add_item(nombre)
	mostrar()


func mostrar() -> void:
	for hijo in datos.get_children():
		hijo.free()
	if $Vistas/Ayuda.button_pressed:
		linea(Vistas.AYUDA)
		return
	var nombre: String = lista.get_item_text(lista.selected) if instructor and lista.selected >= 0 else alias_actual
	var perfil := Consultas.tecnico(base, nombre) if not base.is_empty() and not nombre.is_empty() else {}
	if perfil.is_empty() or perfil.estado == "sin_sesiones":
		if not perfil.is_empty():
			linea(perfil.alias, &"Chip")
		var indicadores := fila_indicadores()
		indicador(indicadores, "Ganancia indicativa", "Pendiente", "Requiere diagnóstico y post-test")
		indicador(indicadores, "Retención simulada", "Pendiente", "Requiere post-test y retest")
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
		linea("Banco de arnés [DEMO]" if perfil.demo else "Banco de arnés", &"Seccion")
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
				brecha.caso, brecha.causa_marcada, brecha.accion_ejecutada], "1"])
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
			linea("%s · %s · promedio %.0f ms" % [escenario, accion, perfil.tiempos_por_escenario[escenario][accion]])
	var sesiones := Vistas.sesiones(perfil.intentos)
	if instructor:
		mostrar_historial(perfil, sesiones)
	else:
		var comparacion := Vistas.ultimas_sesiones(sesiones)
		for competencia in comparacion:
			linea(Banco.COMPETENCIAS.get(competencia, competencia))
			for sesion in comparacion[competencia]:
				mostrar_sesion(sesion)


func mostrar_historial(perfil: Dictionary, sesiones: Array) -> void:
	for competencia in perfil.competencias:
		var valores: Dictionary = perfil.competencias[competencia].dominios_evaluaciones
		linea("%s · Pre %s · Post %s · Retest simulado %s" % [competencia,
			valores.get("pre", "pendiente"), valores.get("post", "pendiente"), valores.get("retest", "pendiente")])
	linea("Línea de tiempo")
	for sesion in sesiones:
		mostrar_sesion(sesion)
	for intento in perfil.intentos:
		linea("%s · Ítem %s · Entrada %s · Versión %s" % [
			intento.reloj_sim, intento.item, intento.fuente_entrada, intento.version_contenido])
	for evento in perfil.eventos:
		linea("%s · Evento %s · Entrada %s · Fuente %s · Versión %s" % [
			evento.reloj_sim, evento.accion, evento.fuente_entrada, evento.get("fuente", "pendiente"),
			evento.get("version_contenido", "pendiente")])


func mostrar_sesion(sesion: Dictionary) -> void:
	linea("%s · %s · %s · %.1f %%" % [sesion.fecha,
		"retest simulado" if sesion.momento == "retest" else sesion.momento, sesion.competencia, sesion.dominio])


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
		linea("Aún no se han registrado errores recurrentes ni brechas.", &"Secundario", interior)
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
	etiqueta.text = texto
	etiqueta.theme_type_variation = estilo
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(datos if padre == null else padre).add_child(etiqueta)


static func tendencia(valor: Variant, referencia: float, unidad: String) -> String:
	if valor is String:
		return valor
	var flecha := "↑" if valor > referencia else ("↓" if valor < referencia else "→")
	return "%s %.1f%s" % [flecha, valor, unidad]
