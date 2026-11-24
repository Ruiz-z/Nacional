extends RefCounted

const Practica = preload("res://logica/simulador/practica.gd")


static func entradas(motor: RefCounted, escenario: Dictionary, componente: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var opciones := Practica.opciones(motor, escenario, componente)
	for id in opciones:
		var regla: Dictionary = opciones[id]
		resultado.append({
			"id": id,
			"texto": regla.descripcion.trim_prefix("[MUESTRA] "),
			"costo": str(regla.get("costo", "—")).trim_prefix("[MUESTRA] "),
			"tiempo": str(regla.get("tiempo", "—")).trim_prefix("[MUESTRA] "),
			"riesgo": str(regla.get("riesgo", "—")).trim_prefix("[MUESTRA] "),
			"requiere_panel": regla.get("requiere_panel", false),
		})
	return resultado
