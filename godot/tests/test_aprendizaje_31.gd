extends RefCounted

static func ejecutar() -> bool:
	var indicadores = load("res://logica/aprendizaje/indicadores.gd")
	if indicadores == null:
		return false
	var competencia := "diagnostico-fallas"
	var intentos := []
	for datos in [["pre", 50, "causa-equivocada"], ["post", 80, "causa-equivocada"],
			["retest", 40, "causa-equivocada"], ["practica", 0, "falta-critica"],
			["practica", 0, "diagnostico-vs-accion"], ["practica", 25, "paso-omitido"]]:
		intentos.append({"competencia": competencia, "momento": datos[0], "valor": datos[1],
			"peso": 1, "tipo_error": datos[2], "tiempo_ms": 200, "item": "a",
			"formato": "opcion-multiple" if datos[0] == "pre" else "caso-diagnostico",
			"reloj_sim": "2026-01-01T00:00:00Z"})
	var todos: Dictionary = indicadores.calcular(intentos, {competencia: 2})
	var datos: Dictionary = todos[competencia]
	return datos.errores_recurrentes == {"causa-equivocada": 3} and datos.brechas == 1 \
		and datos.ganancia == 30 and datos.retencion == 50 and datos.confianza == "alta" \
		and datos.faltas_criticas == [{"item": "a", "fecha": "2026-01-01T00:00:00Z"}] \
		and datos.tiempo_promedio_por_accion_ms == {"a": 200.0} and datos.avance_ruta == 2 \
		and datos.dominio == 32.5 and datos.nivel == "Novato" \
		and todos["seguridad-alto-voltaje"].ganancia == "pendiente"
