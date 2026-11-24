extends RefCounted

static func ejecutar() -> bool:
	var evaluacion = load("res://logica/aprendizaje/evaluacion.gd")
	if not evaluacion.has_method("ganancia"):
		return false
	return evaluacion.ganancia(40, 80) == 40 and evaluacion.ganancia(80, 40) == -40 \
		and evaluacion.retencion(0, 50) == "no calculable" \
		and evaluacion.retencion(60, 90) == 100 and evaluacion.retencion(80, 60) == 75
