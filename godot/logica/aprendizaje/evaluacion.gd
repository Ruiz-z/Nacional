extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Leitner = preload("res://logica/aprendizaje/leitner.gd")

static func post(banco: Dictionary, ids_pre: Array) -> Dictionary:
	var plan := {"items": [], "avisos": [], "equivalente": true}
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["media", "dificil"]:
			agregar_post(plan, banco.items, competencia, "opcion-multiple", dificultad, ids_pre)
	agregar_post(plan, banco.items, "seguridad-alto-voltaje", "accion-panel", "", ids_pre)
	agregar_post(plan, banco.items, "diagnostico-fallas", "caso-diagnostico", "", ids_pre)
	return plan


static func agregar_post(plan: Dictionary, items: Array, competencia: String, formato: String,
		dificultad: String, ids_pre: Array) -> void:
	var usados: Array = plan.items.map(func(item: Dictionary) -> String: return item.id)
	var item := buscar(items, competencia, formato, dificultad, usados + ids_pre)
	if item.is_empty():
		item = buscar(items, competencia, formato, "", usados + ids_pre)
		if item.is_empty():
			item = buscar(items, competencia, formato, dificultad, usados)
		if item.is_empty():
			item = buscar(items, competencia, formato, "", usados)
		avisar(plan, "Faltan ítems distintos del nivel previsto para %s / %s." % [competencia, formato])
	if not item.is_empty():
		plan.items.append(item.duplicate(true))


static func retest(banco: Dictionary, plan_post: Dictionary, fecha_post: int, ahora: int) -> Dictionary:
	var plan := {"items": [], "avisos": [], "equivalente": plan_post.equivalente,
		"disponible": ahora >= fecha_post + 7 * Leitner.SEGUNDOS_DIA}
	if not plan.disponible:
		return plan
	var reservados: Array = plan_post.items.map(func(item: Dictionary) -> String: return item.id)
	for anterior in plan_post.items:
		var actual := {}
		for item in banco.items:
			if item.id == anterior.id:
				actual = item
				break
		if actual.is_empty() or actual.get("version") != anterior.get("version"):
			avisar(plan, "El ítem %s del post-test cambió o ya no está disponible." % anterior.id)
		if actual.is_empty():
			actual = buscar(banco.items, anterior.competencia, anterior.formato, anterior.dificultad, reservados)
			if actual.is_empty():
				actual = buscar(banco.items, anterior.competencia, anterior.formato, "", [])
			if not actual.is_empty():
				reservados.append(actual.id)
		if not actual.is_empty():
			plan.items.append(actual.duplicate(true))
	return plan


static func buscar(items: Array, competencia: String, formato: String, dificultad: String,
		excluidos: Array) -> Dictionary:
	for item in items:
		if item.competencia == competencia and item.formato == formato and item.id not in excluidos \
				and (dificultad.is_empty() or item.dificultad == dificultad):
			return item
	return {}


static func avisar(plan: Dictionary, mensaje: String) -> void:
	plan.equivalente = false
	plan.avisos.append(mensaje)


static func ganancia(pre: float, post_test: float) -> float:
	return post_test - pre


static func retencion(post_test: float, retest_diferido: float) -> Variant:
	if post_test == 0.0:
		return "no calculable"
	return minf(100.0, retest_diferido / post_test * 100.0)
