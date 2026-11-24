extends RefCounted

const Esquema = preload("res://logica/datos/esquema.gd")
const PruebaSQLite = preload("res://tests/test_aprendizaje_25.gd")

static func consultar(base: String, sql: String, parametros: Array = []) -> Variant:
	return PruebaSQLite.motor().call(base, sql, parametros)


static func con_base(prueba: Callable) -> bool:
	var carpeta := OS.get_temp_dir().path_join("nacional-" + Crypto.new().generate_random_bytes(8).hex_encode())
	if DirAccess.make_dir_absolute(carpeta) != OK:
		return false
	var base := carpeta.path_join("datos.sqlite")
	var correcto: bool = Esquema.crear(base, consultar) and prueba.call(base)
	for archivo in DirAccess.get_files_at(carpeta):
		DirAccess.remove_absolute(carpeta.path_join(archivo))
	DirAccess.remove_absolute(carpeta)
	return correcto
