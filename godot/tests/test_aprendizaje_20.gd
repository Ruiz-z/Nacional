extends RefCounted

static func ejecutar() -> bool:
	var dominio = load("res://logica/aprendizaje/dominio.gd")
	if not dominio.has_method("falta_critica") or not dominio.has_method("brecha"):
		return false
	var intentos := [{"valor": 100, "peso": 3}]
	intentos.append(dominio.falta_critica())
	if dominio.calcular(intentos) != 50:
		return false
	intentos.append(dominio.brecha())
	return is_equal_approx(dominio.calcular(intentos), 300.0 / 7.0)
