extends RefCounted

const Mapa = preload("res://logica/aprendizaje/mapa_ruta.gd")


static func ejecutar() -> bool:
	var motivos := [
		{"competencia": "hecha"}, {"competencia": "pendiente", "refuerzo": "Practica la medición."},
		{"competencia": "critica"}, {"competencia": "posterior"}, {"competencia": "reciente"},
	]
	var instantanea := {"hecha": {"dominio": 70.0}, "critica": {"dominio": 82.0},
		"pendiente": {"dominio": 65.0}, "reciente": {"dominio": 90.0}}
	var historial := [
		{"competencia": "critica", "tipo_error": "falta-critica", "sesion": 3},
		{"competencia": "pendiente", "tipo_error": "paso-omitido", "sesion": 4},
		{"competencia": "pendiente", "tipo_error": "paso-omitido", "sesion": 4},
		{"competencia": "pendiente", "tipo_error": "orden-incorrecto", "sesion": 4},
		{"competencia": "pendiente", "resultado": "incorrecto", "sesion": 4},
		{"competencia": "reciente", "tipo_error": "falta-critica", "sesion": 2},
		{"competencia": "reciente", "resultado": "correcto", "sesion": 3},
	]
	var catalogo := [
		{"id": "a", "titulo": "Primera orden"}, {"id": "b", "titulo": "Segunda orden"},
		{"id": "c", "titulo": "Tercera orden", "competencia": "reciente"}, {"id": "d", "titulo": "Cuarta orden"},
	]
	var sugerencias := {"pendiente": {"ordenes": ["inexistente", "b", "b", "a", "c", "d"]},
		"posterior": {"ordenes": ["inexistente"]}}
	var mapa := Mapa.armar(motivos, instantanea, historial, catalogo, sugerencias,
		{"pendiente": true, "critica": true, "hecha": true})
	return mapa.map(func(nodo: Dictionary) -> String: return nodo.estado) == [
			"Primero", "Hecho", "Hoy", "Después", "Después"] \
		and mapa[0].competencia == "critica" and mapa[0].dominio == 82 \
		and mapa[0].errores == [{"nombre": "Falta crítica", "conteo": 1}] \
		and mapa[1].errores == [{"nombre": "Sin errores", "conteo": 0}] \
		and mapa[2].errores == [{"nombre": "Omitir un paso", "conteo": 2},
			{"nombre": "Alterar el orden de los pasos", "conteo": 1},
			{"nombre": "Respuesta incorrecta", "conteo": 1}] \
		and mapa[2].ordenes == [catalogo[1], catalogo[0], catalogo[2]] \
		and mapa[2].refuerzo == "Practica la medición." and mapa[3].ordenes.is_empty() \
		and mapa[4].ordenes == [catalogo[2]] and mapa[4].competencia == "reciente"
