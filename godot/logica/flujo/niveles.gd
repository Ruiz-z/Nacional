extends RefCounted

# El diagnóstico y la práctica reciente abren los niveles de las órdenes, competencia por competencia.

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Banco = preload("res://logica/competencias/banco.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")

const UMBRALES := {"facil": 0, "media": 50, "dificil": 75}


# Dominio por competencia con los últimos intentos puntuados. Sin intentos vale 0.
static func dominios(base: String, alias: String, consultar: Callable = Acceso.consultar) -> Dictionary:
	var resultado := {}
	for competencia in Banco.COMPETENCIAS:
		resultado[competencia] = 0.0
	var intentos: Variant = Registro.leer(base, alias, consultar)
	if not intentos is Array:
		return resultado
	for competencia in resultado:
		var propios: Array = intentos.filter(func(intento: Dictionary) -> bool:
			return intento.competencia == competencia)
		resultado[competencia] = Dominio.calcular(propios)
	return resultado


static func desbloqueada(dificultad: String, dominio: float) -> bool:
	return dominio >= UMBRALES.get(dificultad, 101)


static func nivel_abierto(dominio: float) -> String:
	if desbloqueada("dificil", dominio):
		return "dificil"
	return "media" if desbloqueada("media", dominio) else "facil"


static func motivo(dificultad: String, dominio: float, competencia: String) -> String:
	return "Necesitas %d en %s. Llevas %d." % [UMBRALES.get(dificultad, 100), competencia,
		roundi(dominio)]
