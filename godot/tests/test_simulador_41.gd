extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("resultados") or not sesion.resultados("fecha").is_empty():
		return false
	sesion.marcar_causa("otra")
	sesion.ejecutar("reparar", "panel", 4)
	sesion.ejecutar("preparar", "teclado", 8)
	sesion.ejecutar("reparar", "virtual", 12)
	var resultados: Dictionary = sesion.resultados("fecha")
	if resultados.version_contenido != "1" or resultados.escenario != "prueba" \
			or resultados.por_competencia["diagnostico-fallas"].valor != 92 \
			or resultados.errores[0].tipo_error != "orden-incorrecto" \
			or not resultados.faltas.is_empty() or resultados.brechas.size() != 1 \
			or resultados.eventos[2].tiempo_ms != 12 or resultados.eventos[2].fuente_entrada != "virtual":
		return false
	var escrituras := []
	var consultar := func(_base: String, _sql: String, parametros: Array) -> Array:
		escrituras.append(parametros)
		return []
	for intento in resultados.intentos:
		if not Registro.guardar("base", "alias", intento, consultar):
			return false
	return escrituras.size() == 2 and escrituras[1][9] == "diagnostico-vs-accion"
