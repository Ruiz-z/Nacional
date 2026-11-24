extends RefCounted

const TextoLimpio = preload("res://logica/texto_limpio.gd")

const Practica = preload("res://logica/simulador/practica.gd")


static func entradas(motor: RefCounted, escenario: Dictionary, componente: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var opciones := Practica.opciones(motor, escenario, componente)
	for id: String in opciones:
		if escenario.get("zona") == "banco" and id.begins_with("reportar_"):
			continue
		var regla: Dictionary = opciones[id]
		var requiere_panel: bool = regla.get("requiere_panel", false)
		resultado.append({
			"id": id,
			"marca": TextoLimpio.limpiar("\n".join([regla.get("titulo", ""), regla.descripcion,
				str(regla.get("costo", "")), str(regla.get("tiempo", "")), str(regla.get("riesgo", ""))])).etiqueta,
			"titulo": TextoLimpio.limpiar(regla.get("titulo", regla.descripcion)).texto,
			"descripcion": TextoLimpio.limpiar(regla.descripcion).texto,
			"ejecucion": "confirmar en panel" if requiere_panel else "inmediata",
			"costo": TextoLimpio.limpiar(str(regla.get("costo", "—"))).texto,
			"tiempo": TextoLimpio.limpiar(str(regla.get("tiempo", "—"))).texto,
			"riesgo": TextoLimpio.limpiar(str(regla.get("riesgo", "—"))).texto,
			"requiere_panel": requiere_panel,
		})
	return resultado


static func navegacion(id: String, titulo: String) -> Dictionary:
	return {"id": id, "titulo": titulo, "descripcion": "", "ejecucion": "inmediata",
		"costo": "—", "tiempo": "—", "riesgo": "—", "requiere_panel": false, "navegacion": true}
