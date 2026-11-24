extends RefCounted

const Protocolo = preload("res://logica/entrada/protocolo.gd")
const ESPERA_LATIDO_MS := 3000

var protocolo := Protocolo.new()

var _fuente_fisica: String
var _fuente_panel := "virtual"
var _pausado := false
var _aviso := ""
var _ultimo_latido_ms := 0


func _init(fuente_fisica := "panel") -> void:
	_fuente_fisica = fuente_fisica


func iniciar_panel(ahora_ms: int) -> void:
	iniciar_fisica(ahora_ms)


func iniciar_fisica(ahora_ms: int) -> void:
	protocolo.reiniciar_fuente(_fuente_fisica)
	_ultimo_latido_ms = ahora_ms
	_fuente_panel = _fuente_fisica
	_aviso = ""


func actualizar(ahora_ms: int) -> void:
	if _fuente_panel == _fuente_fisica and ahora_ms - _ultimo_latido_ms >= ESPERA_LATIDO_MS:
		desconectar()


func desconectar() -> void:
	if _fuente_panel == "virtual":
		return
	_fuente_panel = "virtual"
	_pausado = _fuente_fisica == "panel"
	_aviso = "Panel desconectado. Continúa con el panel virtual." if _pausado \
		else "Se desconectó el banco físico. Sigue con el banco en pantalla."


func recibir(linea: String, fuente: String, ahora_ms: int) -> Dictionary:
	actualizar(ahora_ms)
	if fuente != _fuente_panel:
		return {}
	if fuente == "virtual" and _pausado:
		return {}
	var evento := protocolo.recibir(linea, fuente)
	if evento.get("ctrl") == "hb":
		if fuente == _fuente_fisica:
			_ultimo_latido_ms = ahora_ms
		return {}
	return {} if _pausado else evento


func reanudar() -> void:
	_pausado = false


func pausado() -> bool:
	return _pausado


func fuente_panel() -> String:
	return _fuente_panel


func aviso() -> String:
	return _aviso


func etiqueta() -> String:
	if pausado():
		return aviso()
	return "Panel físico" if fuente_panel() == "panel" else "Panel virtual"
