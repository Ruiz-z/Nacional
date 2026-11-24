extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")

const COLUMNAS := """
	INSERT INTO intento (tecnico, competencia, item, formato, dificultad, respuesta,
		valor, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento,
		reloj_sim, version_contenido)
"""
const VALORES := "(SELECT id FROM tecnico WHERE alias = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?"
const INSERTAR := COLUMNAS + "VALUES (" + VALORES + ");"
const INSERTAR_SI_AVANZO := COLUMNAS + "SELECT " + VALORES + " WHERE changes() = 1;"


static func guardar(base: String, alias: String, intento: Dictionary,
		consultar: Callable = Acceso.consultar) -> bool:
	var valores := preparar(alias, intento)
	return not valores.is_empty() and consultar.call(base, INSERTAR, valores) != null


static func preparar(alias: String, intento: Dictionary) -> Array:
	for campo in ["competencia", "item", "formato", "dificultad", "respuesta", "resultado",
			"fuente_entrada", "momento", "reloj_sim", "version_contenido"]:
		if not intento.get(campo) is String:
			return []
	if not intento.get("tiempo_ms") is int or intento.tiempo_ms < 0:
		return []
	if not Dominio.PESOS.has(intento.dificultad) or intento.momento not in ["pre", "post", "retest", "practica"]:
		return []
	var practica: bool = intento.formato != "opcion-multiple"
	var valor: float = Dominio.valor_pregunta(intento.resultado == "correcto")
	var peso := Dominio.peso(intento.dificultad, practica)
	var tipo_error: Variant = intento.get("tipo_error")
	match tipo_error:
		"falta-critica":
			valor = Dominio.falta_critica().valor
			peso = Dominio.falta_critica().peso
		"diagnostico-vs-accion":
			valor = Dominio.brecha().valor
			peso = Dominio.brecha().peso
		_:
			if practica:
				var puntaje: Variant = intento.get("valor")
				if not (puntaje is float or puntaje is int) or not is_finite(puntaje):
					return []
				valor = Dominio.valor_practica(puntaje)
	return [alias, intento.competencia, intento.item, intento.formato, intento.dificultad,
		intento.respuesta, valor, peso, intento.resultado, tipo_error, intento.tiempo_ms,
		intento.fuente_entrada, intento.momento, intento.reloj_sim, intento.version_contenido]


static func leer(base: String, alias: String, consultar: Callable = Acceso.consultar) -> Variant:
	return consultar.call(base, """
		SELECT intento.*, tecnico.alias FROM intento JOIN tecnico ON tecnico.id = intento.tecnico
		WHERE tecnico.alias = ? ORDER BY intento.id;
	""", [alias])
