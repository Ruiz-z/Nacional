extends RefCounted

const PruebaCarga = preload("res://tests/test_carga_banco.gd")


static func ejecutar() -> bool:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var script := raiz.path_join("tools/validar_contenido.gd")
	if not FileAccess.file_exists(script):
		return false
	var salida: Array = []
	var argumentos := ["--headless", "-s", script, "--"]
	var ejemplo := raiz.path_join("contenido/banco.json")
	if OS.execute(OS.get_executable_path(), argumentos + [ejemplo], salida, true) != 0 \
			or not str(salida[0]).split("\n").has("OK"):
		return false
	var ruta := OS.get_temp_dir().path_join("banco-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".json")
	if not PruebaCarga.escribir(ruta, "{\n\"items\": [}"):
		return false
	salida.clear()
	var codigo := OS.execute(OS.get_executable_path(), argumentos + [ruta], salida, true)
	DirAccess.remove_absolute(ruta)
	return codigo == 1 and ruta in str(salida[0]) and "línea" in str(salida[0])
