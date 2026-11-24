extends RefCounted

const Banco = preload("res://logica/simulador/banco_arnes.gd")
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const PUERTO_UDP := 11521

var conexion := Conexion.new("banco")
var _nodos := {}


func recibir(linea: String, ahora_ms: int) -> Dictionary:
	actualizar(ahora_ms)
	if conexion.fuente_panel() == "virtual":
		var inicio := conexion.protocolo.recibir(linea, "banco")
		if inicio.is_empty() or (not conexion.aviso().is_empty() and inicio.ctrl != "hb"):
			return {}
		conexion.iniciar_fisica(ahora_ms)
	var evento := conexion.recibir(linea, "banco", ahora_ms)
	if evento.is_empty():
		return {}
	var anterior := estado_interruptores()
	_nodos[evento.ctrl] = evento.valor
	var actual := estado_interruptores()
	if not anterior.is_empty() and (anterior.s1_abierto or anterior.s2_abierto) \
			and not actual.s1_abierto and not actual.s2_abierto:
		return Banco.calcular(anterior.s1_abierto, anterior.s2_abierto)
	return {}


func actualizar(ahora_ms: int) -> void:
	conexion.actualizar(ahora_ms)
	if conexion.fuente_panel() == "virtual":
		_nodos.clear()


func desconectar() -> void:
	conexion.desconectar()
	_nodos.clear()


func fuente() -> String:
	return "banco" if _nodos.size() == 2 else "virtual"


func estado_interruptores() -> Dictionary:
	if fuente() == "virtual":
		return {}
	return {"s1_abierto": _nodos.nodo_p == 0, "s2_abierto": _nodos.nodo_q == 0}


func leer(estado: Dictionary) -> Dictionary:
	var interruptores := estado_interruptores()
	if interruptores.is_empty():
		var lectura := Mediciones.leer_variante(estado)
		if not conexion.aviso().is_empty():
			lectura.aviso = conexion.aviso()
		return lectura
	return Banco.calcular(interruptores.s1_abierto, interruptores.s2_abierto)
