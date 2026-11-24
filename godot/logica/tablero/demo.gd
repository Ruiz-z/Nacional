extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const ALIAS := "[DEMO] Taller-01"

static func precargar(base: String, consultar: Callable = Acceso.consultar) -> bool:
	# La inserción del perfil y su historial se publica en una sola transacción.
	if consultar.call(base, """
		BEGIN IMMEDIATE;
		INSERT INTO tecnico (alias, demo) VALUES (?, 1) ON CONFLICT(alias) DO NOTHING;
		WITH nuevo AS MATERIALIZED (SELECT last_insert_rowid() AS id WHERE changes() = 1)
		INSERT INTO intento (tecnico, competencia, item, formato, dificultad, respuesta,
			valor, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento, reloj_sim, version_contenido)
		SELECT nuevo.id,
			'sistema-electrico-bateria', 'bateria-muestra-01', 'opcion-multiple', 'facil',
			respuesta, valor, 1, resultado, tipo_error, tiempo, 'teclado', momento, fecha, '1'
		FROM (
			SELECT 'Carga completa' AS respuesta, 0 AS valor, 'incorrecto' AS resultado,
				'lectura-equivocada' AS tipo_error, 1500 AS tiempo, 'pre' AS momento, '2026-01-01T10:00:00Z' AS fecha
			UNION ALL SELECT 'La mitad de la carga', 100, 'correcto', NULL, 900, 'post', '2026-01-02T10:00:00Z'
			UNION ALL SELECT 'La mitad de la carga', 100, 'correcto', NULL, 850, 'retest', '2026-01-09T10:00:00Z'
		) CROSS JOIN nuevo;
		COMMIT;
	""", [ALIAS]) == null:
		return false
	var filas: Variant = consultar.call(base, "SELECT id FROM tecnico WHERE alias = ? AND demo = 1;", [ALIAS])
	return filas != null and not filas.is_empty()
