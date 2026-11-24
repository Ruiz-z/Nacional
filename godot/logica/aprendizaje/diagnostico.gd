extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")

static func preparar(banco: Dictionary) -> Dictionary:
	var plan := {"items": [], "faciles": {}, "avisos": []}
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["media", "dificil"]:
			agregar(plan, elegir(Banco.consultar(banco, competencia, dificultad),
				"opcion-multiple"), "%s / %s" % [competencia, dificultad])
		var facil := elegir(Banco.consultar(banco, competencia, "facil"), "opcion-multiple")
		plan.faciles[competencia] = facil
	agregar(plan, elegir(banco.items, "accion-panel"), "accion-panel")
	agregar(plan, elegir(banco.items, "caso-diagnostico"), "caso-diagnostico")
	return plan


static func elegir(items: Array, formato: String) -> Dictionary:
	for item in items:
		if item.formato == formato:
			return item.duplicate(true)
	return {}


static func agregar(plan: Dictionary, item: Dictionary, descripcion: String) -> void:
	if item.is_empty():
		plan.avisos.append("Falta una pregunta para %s." % descripcion)
	else:
		plan.items.append(item)


static func responder_media(plan: Dictionary, id: String, respuesta: int) -> bool:
	for indice in range(plan.items.size() - 1):
		var media: Dictionary = plan.items[indice]
		var dificil: Dictionary = plan.items[indice + 1]
		if media.id != id or media.formato != "opcion-multiple" or media.dificultad != "media":
			continue
		if dificil.competencia != media.competencia or dificil.dificultad != "dificil":
			return false
		if respuesta != media.correcta:
			var facil: Dictionary = plan.faciles[media.competencia]
			if facil.is_empty():
				plan.avisos.append("Falta una pregunta fácil para %s." % Banco.COMPETENCIAS.get(media.competencia, media.competencia))
				return false
			plan.items[indice + 1] = facil.duplicate(true)
		return true
	return false


const Dominio = preload("res://logica/aprendizaje/dominio.gd")

static func resultado(intentos: Array, ventana: bool = false) -> Dictionary:
	var resultados := {}
	for competencia in Banco.COMPETENCIAS:
		var propios := intentos.filter(func(intento: Dictionary) -> bool:
			return intento.competencia == competencia)
		var dominio := Dominio.calcular(propios) if ventana else Dominio.promedio(propios)
		var teoria := false
		var practica := false
		for intento in propios:
			if intento.get("tipo_error") in ["falta-critica", "diagnostico-vs-accion"]:
				continue
			teoria = teoria or intento.formato == "opcion-multiple"
			practica = practica or intento.formato in ["caso-diagnostico", "accion-panel", "escenario"]
		resultados[competencia] = {"dominio": dominio, "nivel": Dominio.nivel(dominio),
			"confianza": "alta" if teoria and practica else "baja"}
	return resultados
