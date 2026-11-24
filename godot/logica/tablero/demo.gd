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
		INSERT INTO evento (tecnico, escenario, accion, estado_antes, estado_despues,
				criticidad, fuente_entrada, reloj_sim)
		SELECT tecnico.id, 'modulo_auxiliar', muestra.accion, '{}',
			json_object('estado', json('{}'), 'tiempo_ms', 1500, 'version_contenido', '1',
				'fuente', '[MUESTRA] valor de ejemplo, sin fuente oficial', 'tipo_error', muestra.error,
				'fuente_falla', 'virtual'),
			'normal', 'teclado', '2026-01-09T11:00:00Z'
		FROM tecnico CROSS JOIN (
			SELECT 'diagnosticar_senal' AS accion, 'punto-de-medicion-incorrecto' AS error
			UNION ALL SELECT 'diagnosticar_modulo', 'lectura-mal-interpretada'
		) AS muestra
		WHERE tecnico.alias = ? AND tecnico.demo = 1 AND NOT EXISTS (
			SELECT 1 FROM evento WHERE evento.tecnico = tecnico.id AND escenario = 'modulo_auxiliar'
				AND accion = muestra.accion AND reloj_sim = '2026-01-09T11:00:00Z');
		COMMIT;
	""", [ALIAS, ALIAS]) == null:
		return false
	var filas: Variant = consultar.call(base, "SELECT id FROM tecnico WHERE alias = ? AND demo = 1;", [ALIAS])
	return filas != null and not filas.is_empty()
