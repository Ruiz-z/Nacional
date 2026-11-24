extends Control

signal paso_solicitado(paso: String, perfil: Dictionary)

const Alias = preload("res://logica/flujo/alias.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Esquema = preload("res://logica/datos/esquema.gd")
const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Bus = preload("res://escenas/bus.tscn")
const Demo = preload("res://escenas/modo_demo.tscn")
const NOMBRES := {"alias": "Elegir alias", "diagnostico": "Diagnóstico", "ruta": "Ruta",
	"escenario": "Escenario", "post": "Post-test", "retest": "Retest", "tablero": "Tablero"}

var base := "user://nacional.sqlite"
var perfil := {}
var conexion := Conexion.new()
var pantalla: Node
var botones := {}
@onready var inicio := $Marco/Inicio


func _ready() -> void:
	var disponible := Esquema.crear(base)
	inicio.get_node("Alta").disabled = not disponible
	inicio.get_node("Elegir").disabled = not disponible
	inicio.get_node("Alta").pressed.connect(func(): seleccionar_alias(true))
	inicio.get_node("Elegir").pressed.connect(func(): seleccionar_alias(false))
	inicio.get_node("Alias").text_submitted.connect(func(_texto: String): seleccionar_alias(false))
	inicio.get_node("Demo").pressed.connect(abrir_demo)
	$Marco/Volver.pressed.connect(volver)
	for paso in Recorrido.PASOS:
		var boton := Button.new()
		boton.text = NOMBRES[paso]
		boton.pressed.connect(abrir_paso.bind(paso))
		inicio.get_node("Pasos").add_child(boton)
		botones[paso] = boton
	actualizar()
	inicio.get_node("Demo").grab_focus()
	if not disponible:
		inicio.get_node("Aviso").text = "No se pudo abrir la base local."


func _process(_delta: float) -> void:
	conexion.actualizar(Time.get_ticks_msec())
	inicio.get_node("Entrada").text = conexion.etiqueta()


func seleccionar_alias(alta: bool) -> void:
	var entrada: String = inicio.get_node("Alias").text
	var seleccion := Alias.alta(base, entrada) if alta else Alias.elegir(base, entrada)
	if seleccion.ok:
		perfil = seleccion
		actualizar()
	else:
		inicio.get_node("Aviso").text = seleccion.mensaje


func actualizar() -> void:
	var estado := Recorrido.estado(base, perfil.get("id", 0), int(Time.get_unix_time_from_system()))
	var siguiente: String = estado.get("siguiente", "alias")
	inicio.get_node("Siguiente").text = "%s · Siguiente paso: %s" % [
		perfil.get("alias", "Sin alias"), NOMBRES[siguiente]]
	inicio.get_node("Aviso").text = estado.get("aviso", "")
	for paso in botones:
		botones[paso].disabled = paso not in estado.get("habilitados", [])


func abrir_paso(paso: String) -> void:
	if not botones.has(paso) or botones[paso].disabled:
		return
	match paso:
		"escenario":
			abrir_bus(perfil.merged({"base": base}))
		"tablero":
			abrir_tablero({"base": base, "alias": perfil.alias})
		_:
			paso_solicitado.emit(paso, perfil.duplicate())
			inicio.get_node("Aviso").text = "La pantalla de %s está pendiente." % NOMBRES[paso]


func abrir_demo() -> void:
	var demo := Demo.instantiate()
	demo.base_real = base
	demo.tablero_solicitado.connect(abrir_tablero)
	demo.escenario_solicitado.connect(abrir_bus)
	abrir(demo)


func abrir_tablero(tecnico: Dictionary) -> void:
	var tablero := Tablero.instantiate()
	tablero.base = tecnico.base
	tablero.alias_actual = tecnico.alias
	abrir(tablero)


func abrir_bus(tecnico: Dictionary) -> void:
	var bus := Bus.instantiate()
	bus.conexion_panel = conexion
	bus.tecnico = tecnico
	abrir(bus)
	var volver_bus := Button.new()
	volver_bus.text = "Volver al menú"
	volver_bus.pressed.connect(volver)
	bus.lateral.add_child(volver_bus)
	bus.lateral.move_child(volver_bus, 0)
	$Marco/Volver.hide()


func abrir(nueva: Node) -> void:
	if is_instance_valid(pantalla):
		$Marco.remove_child(pantalla)
		pantalla.queue_free()
	inicio.hide()
	pantalla = nueva
	$Marco/Volver.show()
	if nueva is Control:
		nueva.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$Marco.add_child(nueva)


func volver() -> void:
	if is_instance_valid(pantalla):
		pantalla.queue_free()
		pantalla = null
	$Marco.show()
	$Marco/Volver.hide()
	inicio.show()
	actualizar()
	inicio.get_node("Demo").grab_focus()
