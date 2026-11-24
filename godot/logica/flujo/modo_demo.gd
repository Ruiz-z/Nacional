extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Esquema = preload("res://logica/datos/esquema.gd")
const Demo = preload("res://logica/tablero/demo.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")

static func abrir(base_real: String, consultar: Callable = Acceso.consultar) -> Dictionary:
	var base := ruta_demo(base_real)
	if not es_base_demo(base, consultar) or not Esquema.crear(base, consultar) \
			or not Demo.precargar(base, consultar):
		return {}
	var filas: Variant = consultar.call(base, "SELECT id FROM tecnico WHERE alias = ? AND demo = 1;", [Demo.ALIAS])
	if filas == null or filas.is_empty():
		return {}
	return {"base": base, "id": int(filas[0].id), "alias": Demo.ALIAS}


static func adelantar(base_real: String, dias: int, consultar: Callable = Acceso.consultar) -> bool:
	if dias <= 0:
		return false
	var demo := abrir(base_real, consultar)
	return not demo.is_empty() and Reloj.adelantar(demo.base, demo.id, dias, consultar)


static func restablecer(base_real: String, consultar: Callable = Acceso.consultar) -> bool:
	var base := ruta_demo(base_real)
	if not es_base_demo(base, consultar):
		return false
	var temporal := base + "." + Crypto.new().generate_random_bytes(8).hex_encode() + ".tmp"
	var correcto := Esquema.crear(temporal, consultar) and Demo.precargar(temporal, consultar) \
		and Esquema.restaurar(base, temporal, consultar)
	if FileAccess.file_exists(temporal):
		DirAccess.remove_absolute(temporal)
	return correcto


static func ruta_demo(base_real: String) -> String:
	return ProjectSettings.globalize_path(base_real).simplify_path() + ".demo.sqlite"


static func es_base_demo(base: String, consultar: Callable) -> bool:
	if not FileAccess.file_exists(base):
		return true
	var filas: Variant = consultar.call(base, "SELECT id FROM tecnico WHERE demo <> 1 OR alias <> ? LIMIT 1;", [Demo.ALIAS])
	return filas != null and filas.is_empty()
