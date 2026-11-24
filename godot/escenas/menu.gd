extends Control

signal paso_solicitado(paso: String, perfil: Dictionary)

const Banco = preload("res://logica/competencias/banco.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Esquema = preload("res://logica/datos/esquema.gd")
const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Ordenes = preload("res://escenas/ordenes.tscn")
const Bus = preload("res://escenas/bus.tscn")
const Demo = preload("res://escenas/modo_demo.tscn")
const Diagnostico = preload("res://escenas/diagnostico.tscn")
const Ruta = preload("res://escenas/ruta.tscn")
const Evaluacion = preload("res://escenas/evaluacion.tscn")
const NOMBRES := {"alias": "Elegir alias", "diagnostico": "Diagnóstico", "ruta": "Ruta",
	"escenario": "Escenario", "post": "Post-test", "retest": "Retest", "tablero": "Tablero"}

var base := "user://nacional.sqlite"
var perfil := {}
var banco_aprendizaje := {}
var conexion := Conexion.new()
var pantalla: Node
var botones := {}
@onready var inicio := $Marco/EntradaInicio/Centro/Columna/Tarjeta/Inicio


func _ready() -> void:
	if "--verificar-contenido" in OS.get_cmdline_user_args():
		verificar_contenido()
		return
	var disponible := Esquema.crear(base)
	inicio.get_node("Alta").disabled = not disponible
	inicio.get_node("Elegir").disabled = not disponible
	inicio.get_node("Alta").pressed.connect(func(): seleccionar_alias(true))
	inicio.get_node("Elegir").pressed.connect(func(): seleccionar_alias(false))
	inicio.get_node("Alias").placeholder_text = "Ejemplo: T-0001"
	inicio.get_node("Alias").text_submitted.connect(func(_texto: String): seleccionar_alias(false))
	inicio.get_node("Demo").pressed.connect(abrir_demo)
	$Marco/Volver.pressed.connect(volver)
	for paso in Recorrido.PASOS:
		var boton := Button.new()
		boton.text = NOMBRES[paso]
		boton.custom_minimum_size.y = 52
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.pressed.connect(abrir_paso.bind(paso))
		inicio.get_node("Pasos").add_child(boton)
		botones[paso] = boton
	actualizar()
	enfocar_inicio()
	if not disponible:
		inicio.get_node("Aviso").text = "No se pudo abrir la base local."


func verificar_contenido() -> void:
	var banco := Banco.cargar()
	var escenario := Escenario.cargar(Escenario.AISLAMIENTO)
	if not banco.errores.is_empty() or banco.items.is_empty() or not escenario.errores.is_empty():
		printerr("No se pudo verificar el contenido. Banco: ", banco.errores,
			" · Escenario: ", escenario.errores)
		get_tree().quit(1)
		return
	print("OK: banco (", banco.items.size(), " ítems) y escenario ", escenario.escenario.id)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	conexion.actualizar(Time.get_ticks_msec())
	inicio.get_node("Entrada").text = conexion.etiqueta()


func seleccionar_alias(alta: bool) -> void:
	var entrada: String = inicio.get_node("Alias").text
	var seleccion := Alias.alta(base, entrada) if alta else Alias.elegir(base, entrada)
	if seleccion.ok:
		perfil = seleccion
		actualizar()
		enfocar_inicio()
	else:
		inicio.get_node("Aviso").text = seleccion.mensaje


func actualizar() -> void:
	var estado := Recorrido.estado(base, perfil.get("id", 0), int(Time.get_unix_time_from_system()))
	var siguiente: String = estado.get("siguiente", "alias")
	inicio.get_node("Perfil").text = "Técnico · %s" % perfil.get("alias", "Sin alias")
	inicio.get_node("Siguiente").text = "Siguiente paso · %s" % NOMBRES[siguiente]
	var razon: String = estado.get("aviso", "")
	inicio.get_node("Aviso").text = razon if not razon.is_empty() else (
		"Elige o registra un alias para desbloquear el diagnóstico." if perfil.is_empty()
		else "Completa %s para seguir avanzando. Escenario está disponible como práctica libre y no cambia tu avance." % NOMBRES[siguiente]
			if siguiente != "escenario" else "Completa %s para seguir avanzando." % NOMBRES[siguiente])
	for paso in botones:
		var boton: Button = botones[paso]
		boton.disabled = paso not in estado.get("habilitados", []) \
			and not (paso == "retest" and siguiente == "retest") \
			and not (paso == "escenario" and not perfil.is_empty())
		boton.theme_type_variation = &"Primario" if paso == siguiente and razon.is_empty() else &""
		boton.tooltip_text = ("Selecciona un alias para empezar." if perfil.is_empty() else
			"Paso pendiente de habilitar por el recorrido.") if boton.disabled else razon
	inicio.get_node("Elegir").theme_type_variation = &"Primario" if siguiente == "alias" else &""


func enfocar_inicio() -> void:
	var siguiente: String = Recorrido.estado(base, perfil.get("id", 0),
		int(Time.get_unix_time_from_system())).get("siguiente", "alias")
	var boton: Control = botones.get(siguiente, inicio.get_node("Alias"))
	if not (boton is Button and boton.disabled):
		boton.grab_focus()


func abrir_paso(paso: String) -> void:
	if not botones.has(paso) or botones[paso].disabled:
		return
	match paso:
		"escenario":
			abrir_ordenes(perfil.merged({"base": base}))
		"tablero":
			abrir_tablero({"base": base, "alias": perfil.alias})
		"diagnostico", "ruta", "post", "retest":
			paso_solicitado.emit(paso, perfil.duplicate())
			var recurso := {"diagnostico": Diagnostico, "ruta": Ruta}.get(paso, Evaluacion) as PackedScene
			var actividad := recurso.instantiate()
			actividad.actividad.base = base
			actividad.actividad.perfil = perfil
			actividad.actividad.paso = paso
			actividad.banco = banco_aprendizaje
			if paso in ["post", "retest"]:
				actividad.titulo_preparado = NOMBRES[paso]
			actividad.finalizada.connect($Marco/Volver.grab_focus)
			abrir(actividad)
			if actividad.item.is_empty():
				$Marco/Volver.grab_focus()


func abrir_demo() -> void:
	var demo := Demo.instantiate()
	demo.base_real = base
	demo.tablero_solicitado.connect(abrir_tablero)
	demo.escenario_solicitado.connect(abrir_ordenes)
	abrir(demo)


func abrir_tablero(tecnico: Dictionary) -> void:
	var tablero := Tablero.instantiate()
	tablero.base = tecnico.base
	tablero.alias_actual = tecnico.alias
	abrir(tablero)


func abrir_ordenes(tecnico: Dictionary) -> void:
	var ordenes := Ordenes.instantiate()
	ordenes.orden_elegida.connect(func(archivo: String): abrir_bus(tecnico, archivo))
	abrir(ordenes)


func abrir_bus(tecnico: Dictionary, archivo: String = Escenario.AISLAMIENTO) -> void:
	var bus := Bus.instantiate()
	bus.archivo = archivo
	if tecnico.base == base:
		bus.decision_tomada.connect(func(_decision: Dictionary):
			if bus.resultados_guardados:
				var cierre := Recorrido.cerrar_escenario(base, tecnico.id, bus.motor.fin(),
					int(Time.get_unix_time_from_system()))
				if not cierre.is_empty():
					if not cierre.guardado:
						bus.lateral.get_node("Aviso").text += "\nNo se pudo guardar el avance."
					elif not cierre.respaldo:
						bus.lateral.get_node("Aviso").text += "\nSe guardó el avance, pero falta el respaldo.")
	bus.conexion_panel = conexion
	bus.tecnico = tecnico
	abrir(bus)
	bus.salida_solicitada.connect(volver)
	$Marco/Volver.hide()


func abrir(nueva: Node) -> void:
	if is_instance_valid(pantalla):
		$Marco.remove_child(pantalla)
		pantalla.queue_free()
	$Marco/EntradaInicio.hide()
	inicio.hide()
	pantalla = nueva
	$Marco/Volver.show()
	if nueva is Control:
		nueva.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$Marco.add_child(nueva)


func volver() -> void:
	if is_instance_valid(pantalla):
		$Marco.remove_child(pantalla)
		pantalla.queue_free()
		pantalla = null
	$Marco.show()
	$Marco/Volver.hide()
	$Marco/EntradaInicio.show()
	inicio.show()
	actualizar()
	enfocar_inicio()
