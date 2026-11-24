extends RefCounted


static func consultar(ruta: String, sql: String, parametros: Array = []) -> Variant:
	if not ClassDB.class_exists("SQLite") or not ClassDB.can_instantiate("SQLite"):
		printerr("El complemento godot-sqlite no está disponible.")
		return null

	var conexion: Object = ClassDB.instantiate("SQLite")
	conexion.path = ProjectSettings.globalize_path(ruta)
	conexion.default_extension = ""
	conexion.foreign_keys = true
	if not conexion.open_db():
		printerr("No se pudo abrir SQLite: ", conexion.error_message)
		return null

	var correcto: bool = conexion.query_with_bindings(sql, parametros)
	var filas: Variant = conexion.query_result if correcto else null
	if not correcto:
		printerr("Falló la consulta SQLite: ", conexion.error_message)
	if not conexion.close_db():
		printerr("No se pudo cerrar SQLite: ", conexion.error_message)
		return null
	return filas
