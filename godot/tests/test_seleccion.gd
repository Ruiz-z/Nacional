extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Diagnostico = preload("res://logica/aprendizaje/diagnostico.gd")
const Evaluacion = preload("res://logica/aprendizaje/evaluacion.gd")
const Seleccion = preload("res://logica/aprendizaje/seleccion.gd")


static func ejecutar() -> bool:
	return orden() and diagnostico() and post()


# Banco de prueba: 6 preguntas por competencia y dificultad; los pares comparten grupo.
static func banco_de_prueba() -> Dictionary:
	var items := []
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["facil", "media", "dificil"]:
			for numero in range(6):
				items.append({"id": "%s-%s-%d" % [competencia, dificultad, numero], "competencia": competencia,
					"dificultad": dificultad, "formato": "opcion-multiple", "version": "1",
					"grupo": "%s-%s-%d" % [competencia, dificultad, numero / 2]})
	for numero in range(3):
		items.append({"id": "panel-%d" % numero, "competencia": "seguridad-alto-voltaje", "dificultad": "media",
			"formato": "accion-panel", "version": "1"})
		items.append({"id": "caso-%d" % numero, "competencia": "diagnostico-fallas", "dificultad": "media",
			"formato": "caso-diagnostico", "version": "1"})
	return {"items": items, "errores": [], "avisos": []}


static func ids(plan: Dictionary) -> Array:
	return plan.items.map(func(item: Dictionary) -> String: return item.id)


static func orden() -> bool:
	var items: Array = banco_de_prueba().items
	var uno := Seleccion.barajar(items, 7)
	var otro := Seleccion.barajar(items, 8)
	return Seleccion.barajar(items, 0) == items and uno.size() == items.size() \
		and uno == Seleccion.barajar(items, 7) and uno != otro and uno != items \
		and items[0].id == "seguridad-alto-voltaje-facil-0"


static func diagnostico() -> bool:
	var banco := banco_de_prueba()
	var base := Diagnostico.preparar(banco)
	var distintos := {}
	var estable := true
	var sin_grupo_repetido := true
	for semilla in range(1, 21):
		var plan := Diagnostico.preparar(banco, semilla)
		distintos[str(ids(plan))] = true
		estable = estable and ids(plan) == ids(Diagnostico.preparar(banco, semilla))
		var grupos := []
		for item in plan.items:
			var grupo: String = item.get("grupo", "")
			if not grupo.is_empty():
				sin_grupo_repetido = sin_grupo_repetido and grupo not in grupos
				grupos.append(grupo)
	# Con semilla 0 quedan las primeras del banco; con semillas distintas cambia el conjunto y no se repite el tema.
	return base.items.size() == 10 and base.items[0].id == "seguridad-alto-voltaje-media-0" \
		and distintos.size() >= 12 and estable and sin_grupo_repetido


static func post() -> bool:
	var banco := banco_de_prueba()
	for semilla in [0, 3, 11]:
		var pre: Dictionary = Diagnostico.preparar(banco, semilla)
		var pre_ids: Array = ids(pre)
		var evaluacion: Dictionary = Evaluacion.post(banco, pre_ids, semilla)
		var repetidas: Array = ids(evaluacion).filter(func(id: String) -> bool: return id in pre_ids)
		var grupos_pre: Array = pre.items.map(func(item: Dictionary) -> String: return item.get("grupo", ""))
		var temas_repetidos: Array = evaluacion.items.filter(func(item: Dictionary) -> bool:
			return item.get("grupo", "") != "" and item.get("grupo", "") in grupos_pre)
		if evaluacion.items.size() != 10 or not repetidas.is_empty() or not temas_repetidos.is_empty() \
				or not evaluacion.equivalente or ids(evaluacion) != ids(Evaluacion.post(banco, pre_ids, semilla)):
			return false
	return true
