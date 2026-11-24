extends RefCounted

static func ejecutar() -> bool:
	var leitner = load("res://logica/aprendizaje/leitner.gd")
	if not leitner.has_method("item_repetido"):
		return false
	var original := {"id": "A", "competencia": "c", "formato": "opcion-multiple", "dificultad": "media"}
	var variante := original.duplicate()
	variante.id = "B"
	variante.variante_de = "A"
	var ajena := variante.duplicate()
	ajena.id = "C"
	ajena.competencia = "otra"
	return leitner.item_repetido({"items": [original, ajena, variante]}, "A") == variante \
		and leitner.item_repetido({"items": [original, ajena]}, "A") == original \
		and leitner.item_repetido({"items": [original]}, "inexistente").is_empty()
