extends SceneTree

const Banco = preload("../godot/logica/competencias/banco.gd")


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() > 1:
		printerr("Uso: godot --headless -s tools/validar_contenido.gd -- [ruta del banco]")
		quit(1)
		return

	var ruta := "contenido/banco.json" if argumentos.is_empty() else argumentos[0]
	if not ruta.is_absolute_path():
		ruta = DirAccess.open(".").get_current_dir().path_join(ruta)
	var resultado := Banco.cargar(ruta)
	for aviso in resultado.avisos:
		print(aviso)
	for error in resultado.errores:
		printerr(error)
	if resultado.errores.is_empty():
		print("OK")
		quit(0)
	else:
		quit(1)
