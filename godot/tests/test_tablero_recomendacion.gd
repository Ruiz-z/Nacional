extends RefCounted

const Recomendacion = preload("res://logica/tablero/recomendacion.gd")
const Banco = preload("res://logica/competencias/banco.gd")

static func ejecutar() -> bool:
	var resultado := Recomendacion.calcular({})
	if resultado.estado != "Sin completar" or resultado.evidencias.is_empty():
		return false
	var competencias := {}
	for id in Banco.COMPETENCIAS:
		competencias[id] = {"dominio": 80.0, "nivel": "Competente", "errores_recurrentes": {}}
	var id := "diagnostico-fallas"
	var perfil := {"competencias": competencias, "intentos": [], "eventos": []}
	resultado = Recomendacion.calcular(perfil)
	if resultado.estado != "Sin alertas" or resultado.evidencias.size() != 5:
		return false
	competencias[id] = {"dominio": 40.0, "nivel": "Básico",
		"errores_recurrentes": {"paso-omitido": 3}}
	resultado = Recomendacion.calcular(perfil)
	if resultado.estado != "Con alertas" or not resultado.mensaje.begins_with("Reforzar Diagnóstico de fallas") \
			or not resultado.evidencias[0].contains("3 veces"):
		return false
	perfil.intentos.append({"competencia": id, "tipo_error": "falta-critica", "reloj_sim": "2026-01-02"})
	resultado = Recomendacion.calcular(perfil)
	if resultado.estado != "Con falta crítica" or not resultado.evidencias[0].contains("2026-01-02") \
			or resultado.pie != "Es una recomendación. La decisión de avance es del jefe directo.":
		return false
	competencias[id] = {"dominio": 80.0, "nivel": "Competente"}
	perfil.intentos.append({"competencia": id, "resultado": "correcto", "reloj_sim": "2026-01-03"})
	resultado = Recomendacion.calcular(perfil)
	if resultado.estado != "Con alertas" or not resultado.evidencias[0].contains("últimas tres sesiones"):
		return false
	for fecha in ["2026-01-04", "2026-01-05"]:
		perfil.intentos.append({"competencia": id, "resultado": "correcto", "reloj_sim": fecha})
	return Recomendacion.calcular(perfil).estado == "Sin alertas"
