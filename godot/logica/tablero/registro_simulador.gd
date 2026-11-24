extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")

# Los intentos del motor se guardan mediante aprendizaje/registro.gd.
static func guardar(base: String, tecnico: int, entrega: Dictionary,
		consultar: Callable = Acceso.consultar) -> bool:
	var eventos: Variant = entrega.get("eventos")
	var brechas: Variant = entrega.get("brechas")
	if not eventos is Array or not brechas is Array or tecnico <= 0:
		return false
	if eventos.is_empty() and brechas.is_empty():
		return true
	return consultar.call(base, """
		BEGIN IMMEDIATE;
		INSERT INTO evento (tecnico, escenario, accion, estado_antes, estado_despues,
				criticidad, fuente_entrada, reloj_sim)
		SELECT payload ->> 'tecnico', value ->> 'escenario', value ->> 'accion',
			value -> 'estado_antes',
			json_object('estado', value -> 'estado_despues', 'tiempo_ms', value ->> 'tiempo_ms',
				'fuente', value ->> 'fuente', 'version_contenido', payload ->> 'version_contenido'),
			value ->> 'criticidad', value ->> 'fuente_entrada', value ->> 'reloj_sim'
		FROM (SELECT ? AS payload), json_each(payload, '$.eventos');
		INSERT INTO brecha (tecnico, competencia, caso, causa_marcada, accion_ejecutada, reloj_sim)
		SELECT payload ->> 'tecnico', value ->> 'competencia', value ->> 'caso', value ->> 'causa_marcada',
			value ->> 'accion_ejecutada', value ->> 'reloj_sim'
		FROM (SELECT ? AS payload), json_each(payload, '$.brechas');
		COMMIT;
	""", datos_entrega(tecnico, entrega)) != null


static func datos_entrega(tecnico: int, entrega: Dictionary) -> Array:
	var datos := JSON.stringify({"tecnico": tecnico, "eventos": entrega.eventos, "brechas": entrega.brechas,
		"version_contenido": entrega.get("version_contenido")})
	return [datos, datos]


static func leer_metadatos(evento: Dictionary) -> void:
	var estado: String = evento.estado_despues
	if not estado.strip_edges().begins_with("{"):
		return
	var datos: Variant = JSON.parse_string(estado)
	if datos is Dictionary and datos.has_all(["estado", "tiempo_ms", "fuente", "version_contenido"]):
		evento.estado_despues = JSON.stringify(datos.estado)
		evento["tiempo_ms"] = datos.tiempo_ms
		evento["fuente"] = datos.fuente
		evento["version_contenido"] = datos.version_contenido
