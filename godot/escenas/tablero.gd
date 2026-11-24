extends VBoxContainer

const Consultas = preload("res://logica/tablero/consultas.gd")
const Banco = preload("res://logica/competencias/banco.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")

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
	if perfil.is_empty():
		linea("Sin técnico seleccionado.")
		return
	linea(perfil.alias)
	if perfil.estado == "sin_sesiones":
		linea("Sin sesiones registradas.")
	for competencia in perfil.competencias:
		var valor: Dictionary = perfil.competencias[competencia]
		linea("%s · %s · confianza %s" % [Banco.COMPETENCIAS.get(competencia, competencia), valor.nivel, valor.confianza])
		if valor.dominio is float or valor.dominio is int:
			var barra := ProgressBar.new()
			barra.value = valor.dominio
			datos.add_child(barra)
		linea("Ganancia indicativa: %s · Retención simulada: %s" % [
			tendencia(valor.ganancia, 0, " pts"), tendencia(valor.retencion, 100, " %")])
		for error in valor.errores_recurrentes:
			linea("Error recurrente: %s (%d)" % [error, valor.errores_recurrentes[error]])
		linea("Brechas: %d" % valor.brechas)
		for brecha in valor.detalle_brechas:
			linea("%s · %s → %s" % [brecha.caso, brecha.causa_marcada, brecha.accion_ejecutada])
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


func linea(texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.text = texto
	datos.add_child(etiqueta)


static func tendencia(valor: Variant, referencia: float, unidad: String) -> String:
	if valor is String:
		return valor
	var flecha := "↑" if valor > referencia else ("↓" if valor < referencia else "→")
	return "%s %.1f%s" % [flecha, valor, unidad]
