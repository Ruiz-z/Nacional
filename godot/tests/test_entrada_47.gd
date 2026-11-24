extends RefCounted

const Protocolo = preload("res://logica/entrada/protocolo.gd")

static func ejecutar() -> bool:
	var protocolo := Protocolo.new()
	var tiempos := [100, 110, 149, 150]
	for i in range(tiempos.size()):
		var evento := protocolo.recibir(linea("bloqueo", i, tiempos[i]))
		if evento.is_empty() != (i in [1, 2]):
			return false
	return not protocolo.recibir(linea("etiquetado", 4, 151)).is_empty() \
		and not protocolo.recibir(linea("bloqueo", 1, 110), "virtual").is_empty() \
		and protocolo.recibir(linea("bloqueo", 1, 200)).is_empty() \
		and protocolo.errores().back().motivo == "Secuencia repetida"

static func linea(ctrl: String, n: int, t: int) -> String:
	return JSON.stringify({"v": 1, "ctrl": ctrl, "valor": 1, "n": n, "t": t})
