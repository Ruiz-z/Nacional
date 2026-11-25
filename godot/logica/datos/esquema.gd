extends RefCounted

const AccesoSQLite = preload("res://logica/datos/acceso_sqlite.gd")

const CREAR_SQL := """
BEGIN;
CREATE TABLE IF NOT EXISTS tecnico (
	id INTEGER PRIMARY KEY,
	alias TEXT NOT NULL UNIQUE CHECK (length(trim(alias)) > 0),
	demo INTEGER NOT NULL DEFAULT 0 CHECK (demo IN (0, 1)),
	creado TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
) STRICT;
CREATE TABLE IF NOT EXISTS intento (
	id INTEGER PRIMARY KEY,
	tecnico INTEGER NOT NULL REFERENCES tecnico(id) ON DELETE CASCADE,
	competencia TEXT NOT NULL,
	item TEXT NOT NULL,
	formato TEXT NOT NULL,
	dificultad TEXT NOT NULL,
	respuesta TEXT NOT NULL,
	valor REAL NOT NULL CHECK (valor BETWEEN 0 AND 100),
	peso REAL NOT NULL CHECK (peso > 0),
	resultado TEXT NOT NULL,
	tipo_error TEXT,
	tiempo_ms INTEGER NOT NULL CHECK (tiempo_ms >= 0),
	fuente_entrada TEXT NOT NULL,
	momento TEXT NOT NULL CHECK (momento IN ('pre', 'post', 'retest', 'practica')),
	reloj_sim TEXT NOT NULL,
	version_contenido TEXT NOT NULL,
	sesion_id TEXT NOT NULL DEFAULT '',
	caso TEXT NOT NULL DEFAULT '',
	variante TEXT NOT NULL DEFAULT '',
	numero_intento INTEGER NOT NULL DEFAULT 0,
	ayudas INTEGER NOT NULL DEFAULT 0
) STRICT;
CREATE TABLE IF NOT EXISTS evento (
	id INTEGER PRIMARY KEY,
	tecnico INTEGER NOT NULL REFERENCES tecnico(id) ON DELETE CASCADE,
	escenario TEXT NOT NULL,
	accion TEXT NOT NULL,
	estado_antes TEXT NOT NULL,
	estado_despues TEXT NOT NULL,
	criticidad TEXT NOT NULL,
	fuente_entrada TEXT NOT NULL,
	reloj_sim TEXT NOT NULL
) STRICT;
CREATE TABLE IF NOT EXISTS brecha (
	id INTEGER PRIMARY KEY,
	tecnico INTEGER NOT NULL REFERENCES tecnico(id) ON DELETE CASCADE,
	competencia TEXT NOT NULL,
	caso TEXT NOT NULL,
	causa_marcada TEXT NOT NULL,
	accion_ejecutada TEXT NOT NULL,
	reloj_sim TEXT NOT NULL
) STRICT;
CREATE TABLE IF NOT EXISTS leitner (
	tecnico INTEGER NOT NULL REFERENCES tecnico(id) ON DELETE CASCADE,
	item TEXT NOT NULL,
	caja INTEGER NOT NULL CHECK (caja BETWEEN 1 AND 3),
	proxima_fecha_sim TEXT NOT NULL,
	PRIMARY KEY (tecnico, item)
) STRICT;
CREATE TABLE IF NOT EXISTS progreso (
	tecnico INTEGER PRIMARY KEY REFERENCES tecnico(id) ON DELETE CASCADE,
	paso_actual TEXT NOT NULL,
	ruta TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(ruta)),
	microlecciones_hechas INTEGER NOT NULL DEFAULT 0 CHECK (microlecciones_hechas >= 0)
) STRICT;
CREATE TABLE IF NOT EXISTS ruta_generada (
	tecnico INTEGER NOT NULL REFERENCES tecnico(id) ON DELETE CASCADE,
	clave TEXT NOT NULL,
	contenido TEXT NOT NULL CHECK (json_valid(contenido)),
	creado TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
	PRIMARY KEY (tecnico, clave)
) STRICT;
CREATE TABLE IF NOT EXISTS reloj (
	tecnico INTEGER PRIMARY KEY REFERENCES tecnico(id) ON DELETE CASCADE,
	desplazamiento_dias INTEGER NOT NULL DEFAULT 0 CHECK (desplazamiento_dias >= 0)
) STRICT;
COMMIT;
"""


# Columnas de intento añadidas después de la primera versión del esquema.
const COLUMNAS_SESION := {"sesion_id": "TEXT NOT NULL DEFAULT ''", "caso": "TEXT NOT NULL DEFAULT ''",
	"variante": "TEXT NOT NULL DEFAULT ''", "numero_intento": "INTEGER NOT NULL DEFAULT 0",
	"ayudas": "INTEGER NOT NULL DEFAULT 0"}


static func crear(ruta: String, consultar: Callable = AccesoSQLite.consultar) -> bool:
	var base := ProjectSettings.globalize_path(ruta)
	if consultar.call(base, CREAR_SQL) == null:
		return false
	return migrar(base, consultar)


# Añade a una base anterior las columnas de sesión sin perder sus intentos.
static func migrar(base: String, consultar: Callable) -> bool:
	var existentes: Variant = consultar.call(base, "SELECT name FROM pragma_table_info('intento');")
	if existentes == null:
		return false
	var nombres: Array = existentes.map(func(fila: Dictionary) -> String: return fila.name)
	for columna in COLUMNAS_SESION:
		if columna not in nombres \
				and consultar.call(base, "ALTER TABLE intento ADD COLUMN %s %s;" % [columna, COLUMNAS_SESION[columna]]) == null:
			return false
	return true


static func respaldar(base: String, respaldo: String, consultar: Callable = AccesoSQLite.consultar) -> bool:
	return copiar_base(base, respaldo, consultar)


static func restaurar(base: String, respaldo: String, consultar: Callable = AccesoSQLite.consultar) -> bool:
	return copiar_base(respaldo, base, consultar)


static func copiar_base(origen: String, destino: String, consultar: Callable) -> bool:
	origen = ProjectSettings.globalize_path(origen).simplify_path()
	destino = ProjectSettings.globalize_path(destino).simplify_path()
	if origen == destino or not FileAccess.file_exists(origen):
		return false
	# El destino debe estar cerrado y sin archivos de una transacción pendiente.
	for sufijo in ["-journal", "-wal", "-shm"]:
		if FileAccess.file_exists(destino + sufijo):
			return false

	var temporal := destino + "." + Crypto.new().generate_random_bytes(8).hex_encode() + ".tmp"
	var ruta_sql := temporal.replace("'", "''")
	if consultar.call(origen, "VACUUM INTO '%s';" % ruta_sql) != null:
		if DirAccess.rename_absolute(temporal, destino) == OK:
			return true
	if FileAccess.file_exists(temporal):
		DirAccess.remove_absolute(temporal)
	return false
