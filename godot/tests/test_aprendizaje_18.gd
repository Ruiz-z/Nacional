extends RefCounted

static func ejecutar() -> bool:
	var dominio := load("res://logica/aprendizaje/dominio.gd") as GDScript
	if dominio == null:
		return false
	var intentos := [{"valor": 0, "peso": 100}]
	for indice in range(9):
		intentos.append({"valor": 100, "peso": 1})
	intentos.append({"valor": 35, "peso": 6})
	return dominio.valor_pregunta(true) == 100 and dominio.valor_pregunta(false) == 0 \
		and dominio.peso("facil") == 1 and dominio.peso("media") == 2 \
		and dominio.peso("dificil", true) == 6 \
		and is_equal_approx(dominio.calcular(intentos), 74.0) \
		and dominio.calcular([{"valor": 130, "peso": 1}]) == 100 \
		and dominio.calcular([{"valor": -10, "peso": 1}]) == 0
