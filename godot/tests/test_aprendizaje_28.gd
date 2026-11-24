extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")

static func ejecutar() -> bool:
	var evaluacion = load("res://logica/aprendizaje/evaluacion.gd")
	if evaluacion == null:
		return false
	var banco := {"items": []}
	var pre := []
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["media", "dificil"]:
			for version in ["pre", "post"]:
				var id: String = competencia + dificultad + version
				banco.items.append({"id": id, "competencia": competencia,
					"dificultad": dificultad, "formato": "opcion-multiple"})
				if version == "pre":
					pre.append(id)
	for formato in ["accion-panel", "caso-diagnostico"]:
		for version in ["pre", "post"]:
			banco.items.append({"id": formato + version, "formato": formato,
				"competencia": "seguridad-alto-voltaje" if formato == "accion-panel" else "diagnostico-fallas",
				"dificultad": "media"})
		pre.append(formato + "pre")
	var post: Dictionary = evaluacion.post(banco, pre)
	if post.items.size() != 10 or not post.equivalente:
		return false
	for item in post.items:
		if item.id in pre:
			return false
	if evaluacion.retest(banco, post, 0, 604799).disponible:
		return false
	if evaluacion.retest(banco, post, 0, 604800).items != post.items:
		return false
	banco.items.erase(post.items.back())
	var reemplazo: Dictionary = evaluacion.retest(banco, post, 0, 604800)
	if reemplazo.equivalente or reemplazo.items.size() != 10:
		return false
	var incompleto: Dictionary = evaluacion.post(banco, pre)
	return incompleto.items.size() == 10 and not incompleto.equivalente and not incompleto.avisos.is_empty()
