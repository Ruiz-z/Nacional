extends RefCounted

const Entrada = preload("res://logica/entrada/entrada.gd")

static func ejecutar() -> bool:
	var entrada := Entrada.new()
	var acciones: Array = entrada.procesar_lote([
		{"fuente_entrada": "teclado", "ctrl": "E", "valor": 1},
		{"fuente_entrada": "control", "ctrl": "A", "valor": 1},
		{"fuente_entrada": "control", "ctrl": "L", "valor": 1},
	])
	var registro: Array = entrada.registro()
	return acciones.size() == 2 and acciones[0].accion == "inspeccionar" \
		and acciones[1].accion == "bloqueo" and acciones[1].valor == 1 \
		and acciones[1].fuente_entrada == "control" and registro.size() == 3 \
		and registro[0].fuente_entrada == "teclado" and registro[2].fuente_entrada == "control"
