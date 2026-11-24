extends SceneTree


func _initialize() -> void:
	var pruebas: Array[String] = []
	if not buscar_pruebas("res://tests", pruebas) or pruebas.is_empty():
		printerr("No se pudieron reunir las pruebas.")
		quit(1)
		return

	pruebas.sort()
	var fallos := 0
	for ruta in pruebas:
		if ejecutar_prueba(ruta):
			print("OK: ", ruta)
		else:
			printerr("FALLO: ", ruta)
			fallos += 1

	print("%d pruebas, %d fallos." % [pruebas.size(), fallos])
	quit(0 if fallos == 0 else 1)


func buscar_pruebas(ruta: String, pruebas: Array[String]) -> bool:
	var directorio := DirAccess.open(ruta)
	if directorio == null:
		printerr("No se pudo abrir ", ruta)
		return false

	for archivo in directorio.get_files():
		if archivo.begins_with("test_") and archivo.ends_with(".gd"):
			pruebas.append(ruta.path_join(archivo))

	for carpeta in directorio.get_directories():
		if not buscar_pruebas(ruta.path_join(carpeta), pruebas):
			return false
	return true


func ejecutar_prueba(ruta: String) -> bool:
	# Cada script de prueba define «static func ejecutar()» y devuelve true al pasar.
	var prueba := load(ruta) as GDScript
	if prueba == null or not prueba.can_instantiate() or not prueba.has_method("ejecutar"):
		return false
	var resultado: Variant = prueba.call("ejecutar")
	return resultado is bool and resultado
