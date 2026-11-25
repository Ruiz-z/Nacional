extends RefCounted


static func ejecutar() -> bool:
	var esquema := load("res://logica/datos/esquema.gd") as GDScript
	if esquema == null:
		return false

	var carpeta := OS.get_temp_dir().path_join("nacional-" + Crypto.new().generate_random_bytes(8).hex_encode())
	if DirAccess.make_dir_absolute(carpeta) != OK:
		return false

	var consultar: Callable
	if ClassDB.class_exists("SQLite"):
		var acceso := load("res://logica/datos/acceso_sqlite.gd") as GDScript
		consultar = acceso.consultar
		print("Motor del esquema: godot-sqlite.")
	else:
		consultar = consultar_sqlite_local
		print("Motor del esquema: sqlite3 local. Complemento pendiente de verificar.")

	var base := carpeta.path_join("datos.sqlite")
	var respaldo := carpeta.path_join("respaldo de 'paso'.sqlite")
	var correcto: bool = comprobar(esquema, consultar, base, respaldo)
	for archivo in DirAccess.get_files_at(carpeta):
		DirAccess.remove_absolute(carpeta.path_join(archivo))
	DirAccess.remove_absolute(carpeta)
	return correcto


static func comprobar(esquema: GDScript, consultar: Callable, base: String, respaldo: String) -> bool:
	if not esquema.crear(base, consultar):
		printerr("Falló la creación del esquema.")
		return false

	var tablas: Variant = consultar.call(base, "SELECT name FROM sqlite_schema WHERE type = 'table' ORDER BY name;")
	var esperadas := [
		{"name": "brecha"}, {"name": "evento"}, {"name": "intento"},
		{"name": "leitner"}, {"name": "progreso"}, {"name": "reloj"}, {"name": "ruta_generada"},
		{"name": "tecnico"},
	]
	if tablas != esperadas or consultar.call(base, "SELECT alias FROM tecnico;") != []:
		printerr("La base inicial debe tener las siete tablas y ningún técnico.")
		return false

	if consultar.call(base, "INSERT INTO tecnico (alias) VALUES ('T-01');") == null:
		return false
	if not esquema.crear(base, consultar) or not esquema.respaldar(base, respaldo, consultar):
		printerr("Falló la reapertura del esquema o la copia de respaldo.")
		return false
	if consultar.call(base, "UPDATE tecnico SET alias = 'posterior';") == null:
		return false
	if not esquema.restaurar(base, respaldo, consultar):
		printerr("Falló la restauración del respaldo.")
		return false

	var filas := [{"alias": "T-01"}]
	return (
		consultar.call(base, "SELECT alias FROM tecnico;") == filas
		and consultar.call(respaldo, "SELECT alias FROM tecnico;") == filas
		and consultar.call(base, "PRAGMA integrity_check;") == [{"integrity_check": "ok"}]
	)


static func consultar_sqlite_local(ruta: String, sql: String) -> Variant:
	var salida: Array = []
	var codigo := OS.execute("sqlite3", ["-batch", "-bail", "-json", ruta, "PRAGMA foreign_keys = ON; " + sql], salida, true)
	if codigo != 0:
		printerr("Falló sqlite3 local: ", salida)
		return null
	var resultado := str(salida[0]).strip_edges()
	return [] if resultado.is_empty() else JSON.parse_string(resultado)
