extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Leitner = preload("res://logica/aprendizaje/leitner.gd")
const Seleccion = preload("res://logica/aprendizaje/seleccion.gd")

# `semilla` (el id del técnico) varía las preguntas por persona; con 0 se usa el orden del banco.
static func post(banco: Dictionary, ids_pre: Array, semilla: int = 0) -> Dictionary:
	var plan := {"items": [], "avisos": [], "equivalente": true}
	var candidatas := Seleccion.barajar(banco.items, semilla)
	# El post evita los temas del diagnóstico si hay alternativa, para no repetir la misma idea.
	var grupos := []
	for item in banco.items:
		if item.id in ids_pre:
			Seleccion.recordar(grupos, item)
	for cupo in cupos():
		agregar_post(plan, candidatas, cupo[0], cupo[1], cupo[2], ids_pre, grupos)
	return plan


static func cupos() -> Array:
	var previstos := []
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["media", "dificil"]:
			previstos.append([competencia, "opcion-multiple", dificultad])
	previstos.append(["seguridad-alto-voltaje", "accion-panel", ""])
	previstos.append(["diagnostico-fallas", "caso-diagnostico", ""])
	return previstos


static func reconstruir_post(filas: Array, ids_pre: Array) -> Dictionary:
	var plan := {"items": [], "equivalente": filas.size() == cupos().size()}
	var previstos := cupos()
	var usados := ids_pre.duplicate()
	for indice in range(filas.size()):
		var fila: Dictionary = filas[indice]
		plan.items.append({"id": fila.item, "version": fila.version_contenido,
			"competencia": fila.competencia, "formato": fila.formato, "dificultad": fila.dificultad})
		if indice < previstos.size():
			var cupo: Array = previstos[indice]
			if fila.item in usados or fila.competencia != cupo[0] or fila.formato != cupo[1] \
					or (not cupo[2].is_empty() and fila.dificultad != cupo[2]):
				plan.equivalente = false
		usados.append(fila.item)
	return plan


static func agregar_post(plan: Dictionary, items: Array, competencia: String, formato: String,
		dificultad: String, ids_pre: Array, grupos: Array = []) -> void:
	var usados: Array = plan.items.map(func(item: Dictionary) -> String: return item.id)
	var item := buscar(items, competencia, formato, dificultad, usados + ids_pre, grupos)
	if item.is_empty() and not grupos.is_empty():
		item = buscar(items, competencia, formato, dificultad, usados + ids_pre)
	if item.is_empty():
		item = buscar(items, competencia, formato, "", usados + ids_pre)
		if item.is_empty():
			item = buscar(items, competencia, formato, dificultad, usados)
		if item.is_empty():
			item = buscar(items, competencia, formato, "", usados)
		avisar(plan, "Faltan preguntas del mismo nivel para %s." % Banco.COMPETENCIAS.get(competencia, competencia))
	if not item.is_empty():
		plan.items.append(item.duplicate(true))
		Seleccion.recordar(grupos, item)


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
			avisar(plan, "Una pregunta de la evaluación anterior cambió o ya no está disponible.")
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
		excluidos: Array, grupos_excluidos: Array = []) -> Dictionary:
	for item in items:
		if item.competencia == competencia and item.formato == formato and item.id not in excluidos \
				and (dificultad.is_empty() or item.dificultad == dificultad) \
				and (grupos_excluidos.is_empty() or Seleccion.grupo_de(item).is_empty()
					or Seleccion.grupo_de(item) not in grupos_excluidos):
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
