extends RefCounted

static func ejecutar() -> bool:
	var evaluar := load("res://logica/entrada/evaluacion_panel.gd") as GDScript
	var bloqueo := {"ctrl": "bloqueo", "valor": 1}
	var liberar := {"ctrl": "bloqueo", "valor": 0}
	var confirmar := {"ctrl": "confirmar", "valor": 1}
	var extra := {"ctrl": "cancelar", "valor": 1}
	var esperada := [bloqueo, confirmar]
	var criticidades := {"confirmar": "critica"}
	if not evaluar.comparar(esperada, esperada, criticidades).is_empty():
		return false
	var orden: Array = evaluar.comparar([confirmar, bloqueo], esperada, {}, true)
	var pasos: Array = evaluar.comparar([bloqueo, extra, confirmar, confirmar], esperada, criticidades)
	var insegura: Array = evaluar.comparar([bloqueo, liberar, confirmar],
		[bloqueo, liberar, confirmar], criticidades)
	return orden.size() == 1 and orden[0].tipo_error == "orden-incorrecto" \
		and pasos.size() == 2 and pasos[0].tipo_error == "paso-innecesario" \
		and pasos[1].tipo_error == "paso-innecesario" and insegura.size() == 1 \
		and insegura[0].tipo_error == "accion-insegura" and insegura[0].criticidad == "critica"
