extends RefCounted

static func ejecutar() -> bool:
	var dominio = load("res://logica/aprendizaje/dominio.gd")
	if not dominio.has_method("nivel"):
		return false
	for caso in [[39, "Novato"], [40, "Básico"], [69, "Básico"], [70, "Competente"],
			[89, "Competente"], [90, "Experto"]]:
		if dominio.nivel(caso[0]) != caso[1]:
			return false
	return true
