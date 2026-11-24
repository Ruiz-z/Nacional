extends RefCounted

const Dominio = preload("res://logica/aprendizaje/dominio.gd")
const EvaluacionPanel = preload("res://logica/entrada/evaluacion_panel.gd")

static func intento(item: Dictionary, respuesta: Variant, tiempo_ms: int,
		fuente: String, momento: String, fecha: String) -> Dictionary:
	var error: Variant = null
	var correcta := false
	match item.formato:
		"opcion-multiple":
			correcta = respuesta == int(item.correcta)
		"accion-panel":
			var errores := EvaluacionPanel.comparar(respuesta, item.secuencia_esperada, {})
			correcta = errores.is_empty()
			if not correcta:
				error = errores[0].tipo_error
		"caso-diagnostico":
			correcta = respuesta == item.ruta_ideal
			if not correcta:
				error = "paso-omitido" if respuesta.size() < item.ruta_ideal.size() else "orden-incorrecto"
				for paso in item.pasos:
					if paso.id in respuesta and paso.id not in item.ruta_ideal:
						error = paso.tipo_error
						break
	return {"competencia": item.competencia, "item": item.id, "formato": item.formato,
		"dificultad": item.dificultad, "respuesta": JSON.stringify(respuesta),
		"valor": Dominio.valor_pregunta(correcta),
		"peso": Dominio.peso(item.dificultad, item.formato != "opcion-multiple"),
		"resultado": "correcto" if correcta else "incorrecto", "tipo_error": error,
		"tiempo_ms": tiempo_ms, "fuente_entrada": fuente, "momento": momento,
		"reloj_sim": fecha, "version_contenido": item.version}
