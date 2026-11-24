extends SceneTree


func _initialize() -> void:
	if not ClassDB.class_exists("SQLite") or not ClassDB.can_instantiate("SQLite"):
		printerr("SQLite no está registrado en Godot.")
		quit(1)
		return

	var conexion: Object = ClassDB.instantiate("SQLite")
	conexion.path = ":memory:"
	if not conexion.open_db():
		printerr("No se pudo abrir SQLite: ", conexion.error_message)
		quit(1)
		return

	var correcto: bool = (
		conexion.query("CREATE TABLE humo (valor INTEGER);")
		and conexion.query("INSERT INTO humo VALUES (42);")
		and conexion.query("SELECT valor FROM humo;")
		and conexion.query_result == [{"valor": 42}]
	)
	var cerrado: bool = conexion.close_db()
	if correcto and cerrado:
		print("OK: SQLite abrió la base, creó la tabla y leyó el valor 42.")
		quit(0)
	else:
		printerr("Falló la prueba de humo de SQLite.")
		quit(1)
