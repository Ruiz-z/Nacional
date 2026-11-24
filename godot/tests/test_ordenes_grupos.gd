extends RefCounted

const Ordenes = preload("res://escenas/ordenes.tscn")


static func ejecutar() -> bool:
	var pantalla := Ordenes.instantiate()
	var arbol := Engine.get_main_loop() as SceneTree
	arbol.root.add_child(pantalla)
	var comunes := {"zona": "bajos", "dificultad": "media", "competencia": "Práctica"}
	pantalla.mostrar({"errores": [], "ordenes": [
		comunes.merged({"grupo_funcion": "FG7", "titulo": "Rueda", "archivo": "rueda.json"}),
		comunes.merged({"grupo_funcion": "FG3", "titulo": "Cable", "archivo": "cable.json"}),
		comunes.merged({"titulo": "Orden anterior", "archivo": "anterior.json"}),
		comunes.merged({"grupo_funcion": "FG7", "titulo": "Resorte", "archivo": "resorte.json"}),
		comunes.merged({"grupo_funcion": "FG5", "titulo": "Freno", "archivo": "freno.json"}),
	]})
	var tarjetas: VBoxContainer = pantalla.tarjetas
	var elegidas: Array[String] = []
	pantalla.orden_elegida.connect(func(archivo: String): elegidas.append(archivo))
	var grupo := tarjetas.get_node_or_null("FG7")
	var correcto := tarjetas.get_child_count() == 4 and grupo != null
	if correcto:
		var boton := grupo.get_child(1) as Button
		boton.pressed.emit()
		correcto = tarjetas.get_child(0).name == &"FG3" and tarjetas.get_child(3).name == &"Otros" \
			and tarjetas.get_node("FG3/Titulo").text == "FG 3 · Sistema eléctrico" \
			and tarjetas.get_node("FG5/Titulo").text == "FG 5 · Frenos" \
			and grupo.get_child_count() == 3 and boton.get_node("GrupoFuncion").text == "FG 7" \
			and elegidas == ["rueda.json"]
	pantalla.free()
	return correcto
