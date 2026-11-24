extends RefCounted

const PESOS := {"facil": 1, "media": 2, "dificil": 3}

static func valor_pregunta(correcta: bool) -> int:
	return 100 if correcta else 0


static func valor_practica(puntaje: float) -> float:
	return clampf(puntaje, 0.0, 100.0)


static func peso(dificultad: String, practica: bool = false) -> int:
	return PESOS[dificultad] * (2 if practica else 1)


# Los intentos llegan ordenados del más antiguo al más reciente.
static func calcular(intentos: Array) -> float:
	return promedio(intentos.slice(maxi(0, intentos.size() - 10)))


static func promedio(intentos: Array) -> float:
	var suma := 0.0
	var pesos := 0.0
	for intento in intentos:
		suma += intento.valor * intento.peso
		pesos += intento.peso
	return clampf(suma / pesos, 0.0, 100.0) if pesos > 0.0 else 0.0


static func nivel(dominio: float) -> String:
	if dominio < 40:
		return "Novato"
	if dominio < 70:
		return "Básico"
	if dominio < 90:
		return "Competente"
	return "Experto"


static func falta_critica() -> Dictionary:
	return {"valor": 0, "peso": 3, "tipo_error": "falta-critica"}


static func brecha() -> Dictionary:
	return {"valor": 0, "peso": 1, "tipo_error": "diagnostico-vs-accion"}
