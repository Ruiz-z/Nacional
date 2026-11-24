extends RefCounted

static func ejecutar() -> bool:
	var protocolo := load("res://logica/entrada/protocolo.gd").new() as RefCounted
	for linea in ["{", "[]", '{"v":2}', '{"v":1,"ctrl":"ajeno","valor":1,"n":1,"t":0}',
			'{"v":1,"ctrl":"confirmar","valor":1,"n":1.5,"t":0}']:
		if not protocolo.recibir(linea).is_empty():
			return false
	var linea := '{"v":1,"ctrl":"confirmar","valor":1,"n":1,"t":0}'
	var evento: Dictionary = protocolo.recibir(linea)
	return evento.get("n") == 1 and evento.get("fuente_entrada") == "panel" \
		and protocolo.recibir(linea).is_empty() and protocolo.errores().size() == 6 \
		and protocolo.recibir(linea, "virtual").get("fuente_entrada") == "virtual"
