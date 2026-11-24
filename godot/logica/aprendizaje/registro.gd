extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")

static func guardar(base: String, alias: String, intento: Dictionary,
		consultar: Callable = Acceso.consultar) -> bool:
	for campo in ["competencia", "item", "formato", "dificultad", "respuesta", "resultado",
			"fuente_entrada", "momento", "reloj_sim", "version_contenido"]:
		if not intento.get(campo) is String:
			return false
	if not intento.get("tiempo_ms") is int or intento.tiempo_ms < 0:
		return false
	if not Dominio.PESOS.has(intento.dificultad) or intento.momento not in ["pre", "post", "retest", "practica"]:
		return false
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
					return false
				valor = Dominio.valor_practica(puntaje)
	return consultar.call(base, """
		INSERT INTO intento (tecnico, competencia, item, formato, dificultad, respuesta,
			valor, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento,
			reloj_sim, version_contenido)
		VALUES ((SELECT id FROM tecnico WHERE alias = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	""", [alias, intento.competencia, intento.item, intento.formato, intento.dificultad,
		intento.respuesta, valor, peso, intento.resultado, tipo_error, intento.tiempo_ms,
		intento.fuente_entrada, intento.momento, intento.reloj_sim, intento.version_contenido]) != null


static func leer(base: String, alias: String, consultar: Callable = Acceso.consultar) -> Variant:
	return consultar.call(base, """
		SELECT intento.*, tecnico.alias FROM intento JOIN tecnico ON tecnico.id = intento.tecnico
		WHERE tecnico.alias = ? ORDER BY intento.id;
	""", [alias])
