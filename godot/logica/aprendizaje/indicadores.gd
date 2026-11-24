extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Diagnostico = preload("res://logica/aprendizaje/diagnostico.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")
const Evaluacion = preload("res://logica/aprendizaje/evaluacion.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")

static func consultar_tecnico(base: String, alias: String, avance: Dictionary = {},
		consultar: Callable = Acceso.consultar) -> Variant:
	var intentos: Variant = Registro.leer(base, alias, consultar)
	return null if intentos == null else calcular(intentos, avance)


static func calcular(intentos: Array, avance: Dictionary = {}) -> Dictionary:
	var resultados := Diagnostico.resultado(intentos, true)
	for competencia in resultados:
		var datos: Dictionary = resultados[competencia]
		var propias := intentos.filter(func(intento: Dictionary) -> bool:
			return intento.competencia == competencia)
		datos.merge(resumir(propias))
		datos.avance_ruta = avance.get(competencia, 0)
	return resultados


static func resumir(intentos: Array) -> Dictionary:
	var evaluaciones := {"pre": [], "post": [], "retest": []}
	var errores := {}
	var tiempos := {}
	var faltas := []
	var brechas := 0
	for intento in intentos:
		if evaluaciones.has(intento.momento):
			evaluaciones[intento.momento].append(intento)
		var error: Variant = intento.get("tipo_error")
		if error is String and not error.is_empty():
			errores[error] = errores.get(error, 0) + 1
		if error == "falta-critica":
			faltas.append({"item": intento.item, "fecha": intento.reloj_sim})
		elif error == "diagnostico-vs-accion":
			brechas += 1
		if not Dominio.es_puntuado(intento):
			continue
		var mediciones: Array = tiempos.get(intento.item, [0.0, 0])
		mediciones[0] += intento.tiempo_ms
		mediciones[1] += 1
		tiempos[intento.item] = mediciones

	var recurrentes := {}
	for error in errores:
		if errores[error] >= 3:
			recurrentes[error] = errores[error]
	for item in tiempos:
		tiempos[item] = tiempos[item][0] / tiempos[item][1]

	var dominios := {}
	for momento in evaluaciones:
		if not evaluaciones[momento].is_empty():
			dominios[momento] = Dominio.promedio(evaluaciones[momento])
	var ganancia: Variant = "pendiente"
	var retencion: Variant = "pendiente"
	if dominios.has_all(["pre", "post"]):
		ganancia = Evaluacion.ganancia(dominios.pre, dominios.post)
	if dominios.has_all(["post", "retest"]):
		retencion = Evaluacion.retencion(dominios.post, dominios.retest)
	return {"ganancia": ganancia, "retencion": retencion, "ganancia_indicativa": true,
		"dominios_evaluaciones": dominios,
		"brechas": brechas, "faltas_criticas": faltas, "errores_recurrentes": recurrentes,
		"tiempo_promedio_por_accion_ms": tiempos}
