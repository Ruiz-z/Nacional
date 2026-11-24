extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Diagnostico = preload("res://logica/aprendizaje/diagnostico.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")

static func preparar(orden: Array, catalogo: Array) -> Dictionary:
	var prioridades := orden.slice(0, 2)
	var seleccion := []
	for competencia in [prioridades.front(), prioridades.back(), prioridades.front()] if not prioridades.is_empty() else []:
		for leccion in catalogo:
			if leccion.competencia != competencia or leccion in seleccion:
				continue
			if not Banco.texto_presente(leccion.get("explicacion")) or not leccion.get("fuente"):
				continue
			if leccion.minutos < 3 or leccion.minutos > 5 or leccion.items.size() != 2:
				continue
			seleccion.append(leccion)
			break
	var avisos := []
	if seleccion.size() != 3:
		avisos.append("Faltan microlecciones para completar la sesión.")
	return {"lecciones": seleccion.duplicate(true), "avisos": avisos}


static func cerrar(plan: Dictionary, respuestas: Array, historial: Array, numero: int) -> Dictionary:
	if plan.lecciones.size() != 3 or respuestas.size() != 6:
		return {}
	var esperados := []
	for leccion in plan.lecciones:
		for item in leccion.items:
			esperados.append([leccion.competencia, item.id])
	var intentos := historial.duplicate()
	for respuesta in respuestas:
		var indice := esperados.find([respuesta.competencia, respuesta.item])
		if indice < 0:
			return {}
		esperados.remove_at(indice)
		var intento: Dictionary = respuesta.duplicate()
		intento.sesion = numero
		intentos.append(intento)
	var resultados := Diagnostico.resultado(intentos, true)
	var dominios := {}
	for competencia in resultados:
		dominios[competencia] = resultados[competencia].dominio
	return {"dominios": dominios, "ruta": Ruta.ordenar(dominios, intentos, numero)}


static func catalogo(banco: Dictionary) -> Array:
	var lecciones := []
	for competencia in Banco.COMPETENCIAS:
		var preguntas: Array = banco.items.filter(func(item: Dictionary) -> bool:
			return item.competencia == competencia and item.formato == "opcion-multiple")
		if preguntas.size() < 2:
			continue
		for indice in range(2):
			var inicio := (indice * 3) % preguntas.size()
			var ejemplo: Dictionary = preguntas[inicio]
			var primero := (inicio + 1) % preguntas.size()
			var segundo := (inicio + 2) % preguntas.size()
			lecciones.append({"competencia": competencia, "minutos": 3,
				"explicacion": ejemplo.get("explicacion", "%s\n%s" % [
					ejemplo.pregunta, ejemplo.opciones[int(ejemplo.correcta)]]),
				"fuente": ejemplo.fuente, "muestra": ejemplo.get("muestra", false),
				"items": [preguntas[primero], preguntas[segundo]]})
	return lecciones
