extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")

static func ejecutar() -> bool:
	var diagnostico = load("res://logica/aprendizaje/diagnostico.gd")
	if diagnostico == null:
		return false
	var banco := {"items": []}
	for competencia in Banco.COMPETENCIAS:
		for dificultad in Banco.DIFICULTADES:
			banco.items.append({"id": competencia + dificultad, "competencia": competencia,
				"dificultad": dificultad, "formato": "opcion-multiple", "correcta": 0})
	banco.items.append({"id": "panel", "competencia": "seguridad-alto-voltaje",
		"dificultad": "media", "formato": "accion-panel"})
	banco.items.append({"id": "caso", "competencia": "diagnostico-fallas",
		"dificultad": "media", "formato": "caso-diagnostico"})
	var plan: Dictionary = diagnostico.preparar(banco)
	var preguntas: Array = plan.items
	if preguntas.size() != 10 or not plan.avisos.is_empty():
		return false
	if not diagnostico.responder_media(plan, preguntas[0].id, 1):
		return false
	if not diagnostico.responder_media(plan, preguntas[2].id, 0):
		return false
	return preguntas[1].dificultad == "facil" and preguntas[3].dificultad == "dificil" \
		and preguntas[8].id == "panel" and preguntas[9].id == "caso"
