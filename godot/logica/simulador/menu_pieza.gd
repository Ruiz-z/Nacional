extends RefCounted

const Practica = preload("res://logica/simulador/practica.gd")


static func entradas(motor: RefCounted, escenario: Dictionary, componente: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var opciones := Practica.opciones(motor, escenario, componente)
	for id in opciones:
		var regla: Dictionary = opciones[id]
		var requiere_panel: bool = regla.get("requiere_panel", false)
		resultado.append({
			"id": id,
			"titulo": regla.get("titulo", regla.descripcion).trim_prefix("[MUESTRA] "),
			"descripcion": regla.descripcion.trim_prefix("[MUESTRA] "),
			"ejecucion": "confirmar en panel" if requiere_panel else "inmediata",
			"costo": str(regla.get("costo", "—")).trim_prefix("[MUESTRA] "),
			"tiempo": str(regla.get("tiempo", "—")).trim_prefix("[MUESTRA] "),
			"riesgo": str(regla.get("riesgo", "—")).trim_prefix("[MUESTRA] "),
			"requiere_panel": requiere_panel,
		})
	return resultado


static func navegacion(id: String, titulo: String) -> Dictionary:
	return {"id": id, "titulo": titulo, "descripcion": "", "ejecucion": "inmediata",
		"costo": "—", "tiempo": "—", "riesgo": "—", "requiere_panel": false, "navegacion": true}
