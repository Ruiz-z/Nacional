extends RefCounted

const Protocolo = preload("res://logica/entrada/protocolo.gd")
const ESPERA_LATIDO_MS := 3000

var protocolo := Protocolo.new()

var _fuente_panel := "virtual"
var _pausado := false
var _aviso := ""
var _ultimo_latido_ms := 0


func iniciar_panel(ahora_ms: int) -> void:
	protocolo.reiniciar_panel()
	_ultimo_latido_ms = ahora_ms
	_fuente_panel = "panel"
	_aviso = ""


func actualizar(ahora_ms: int) -> void:
	if _fuente_panel == "panel" and ahora_ms - _ultimo_latido_ms >= ESPERA_LATIDO_MS:
		_fuente_panel = "virtual"
		_pausado = true
		_aviso = "Panel desconectado. Continúa con el panel virtual."


func recibir(linea: String, fuente: String, ahora_ms: int) -> Dictionary:
	actualizar(ahora_ms)
	if fuente != _fuente_panel:
		return {}
	if fuente == "virtual" and _pausado:
		return {}
	var evento := protocolo.recibir(linea, fuente)
	if evento.get("ctrl") == "hb":
		if fuente == "panel":
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
