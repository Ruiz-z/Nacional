extends RefCounted

const Esquema = preload("res://logica/datos/esquema.gd")
const Acceso = preload("res://logica/datos/acceso_sqlite.gd")

static func ejecutar() -> bool:
	var leitner = load("res://logica/aprendizaje/leitner.gd")
	if leitner == null:
		return false
	var base := OS.get_temp_dir().path_join("aprendizaje-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".sqlite")
	var consulta := motor()
	var correcto := Esquema.crear(base, consulta) \
		and consulta.call(base, "INSERT INTO tecnico (id, alias) VALUES (1, 'prueba');") != null \
		and comprobar(leitner, base, consulta)
	DirAccess.remove_absolute(base)
	return correcto


static func comprobar(leitner: GDScript, base: String, consulta: Callable) -> bool:
	for paso in [[false, 1, 1], [true, 2, 3], [true, 3, 7], [true, 3, 7], [false, 1, 1]]:
		if not leitner.registrar(base, 1, "a", paso[0], 0, consulta):
			return false
		var fecha: int = paso[2] * 86400
		if leitner.vencidos(base, 1, fecha - 1, consulta) != []:
			return false
		var vencidos: Variant = leitner.vencidos(base, 1, fecha, consulta)
		if not vencidos is Array or vencidos.size() != 1 or vencidos[0].caja != paso[1]:
			return false
	return true


static func motor() -> Callable:
	return Acceso.consultar if ClassDB.class_exists("SQLite") else consultar_local


static func consultar_local(base: String, sql: String, parametros: Array = []) -> Variant:
	# Los parámetros de texto se representan como literales hexadecimales.
	var partes := sql.split("?")
	if partes.size() != parametros.size() + 1:
		return null
	var sentencia: String = partes[0]
	for indice in range(parametros.size()):
		var valor: Variant = parametros[indice]
		if valor is String:
			sentencia += "CAST(X'%s' AS TEXT)" % valor.to_utf8_buffer().hex_encode()
		elif valor == null:
			sentencia += "NULL"
		else:
			sentencia += str(valor)
		sentencia += partes[indice + 1]
	var salida: Array = []
	# El binario del SDK de Android puede aparecer primero en PATH y carecer de FTS5.
	var ejecutable := "/usr/bin/sqlite3" if FileAccess.file_exists("/usr/bin/sqlite3") else "sqlite3"
	var codigo := OS.execute(ejecutable, ["-batch", "-bail", "-json", base,
		"PRAGMA foreign_keys = ON; " + sentencia], salida, true)
	if codigo != 0:
		printerr("Falló sqlite3 en la prueba: ", salida)
		return null
	var resultado := str(salida[0]).strip_edges()
	return [] if resultado.is_empty() else JSON.parse_string(resultado)
