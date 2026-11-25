extends RefCounted

const Materiales = preload("res://logica/flujo/materiales.gd")


static func ejecutar() -> bool:
	var base := "http://127.0.0.1:8765"
	var token := "abc-DEF_123"
	var carpeta := OS.get_temp_dir().path_join("nacional-mat-%s" % Crypto.new().generate_random_bytes(4).hex_encode())
	DirAccess.make_dir_recursive_absolute(carpeta.path_join("web"))
	var archivo := FileAccess.open(carpeta.path_join(Materiales.ARCHIVO_TOKEN), FileAccess.WRITE)
	archivo.store_string(token + "\n")
	archivo.close()
	var correcto: bool = Materiales.leer_token(carpeta) == token and Materiales.leer_token(carpeta.path_join("nada")).is_empty() \
		and Materiales.url("jefe", token) == base + "/acceso?token=" + token \
		and Materiales.url("admin", token) == base + "/acceso?token=" + token \
		and Materiales.url("tecnico", token) == base and Materiales.url("", token) == base \
		and Materiales.url("jefe", "") == base and Materiales.url("jefe", "  ") == base \
		and Materiales.url("admin", "a b&c").contains("a%20b%26c")
	DirAccess.remove_absolute(carpeta.path_join(Materiales.ARCHIVO_TOKEN))
	DirAccess.remove_absolute(carpeta.path_join("web"))
	DirAccess.remove_absolute(carpeta)
	return correcto
