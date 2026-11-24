extends RefCounted

const Ordenes = preload("res://escenas/ordenes.tscn")


static func ejecutar() -> bool:
	var pantalla := Ordenes.instantiate()
	var arbol := Engine.get_main_loop() as SceneTree
	arbol.root.add_child(pantalla)
	var tarjetas: VBoxContainer = pantalla.tarjetas
	var correcto := titulos(tarjetas) == [
		["Falla de comunicación en la red", "Tuercas de rueda flojas"],
		["Faro delantero apagado", "Pérdida de aislamiento", "Freno desgastado", "Neumático pinchado"],
		["Alerta de temperatura del motor de tracción", "Módulo auxiliar sin respuesta",
			"Amortiguador dañado", "Fuga en la suspensión neumática"],
	]
	for tarjeta in tarjetas.find_children("*", "Button", true, false):
		var etiquetas: Array[String] = []
		for etiqueta in tarjeta.find_children("*", "Label", true, false):
			etiquetas.append(etiqueta.text)
		correcto = correcto and etiquetas.count("Ejemplo didáctico") == 1
	for etiqueta in pantalla.find_children("*", "Label", true, false):
		correcto = correcto and not etiqueta.text.contains("[MUESTRA]")
	for boton in pantalla.find_children("*", "Button", true, false):
		correcto = correcto and not boton.text.contains("[MUESTRA]") \
			and not boton.accessibility_name.contains("[MUESTRA]")
	var filtros: HBoxContainer = pantalla.get_node("Centro/Columna/Filtros")
	var nombres: Array[String] = []
	for boton in filtros.get_children():
		nombres.append(boton.text)
	correcto = correcto and nombres == ["Todas", "FG 2", "FG 3", "FG 5", "FG 7"] \
		and filtros.get_child(0).button_pressed
	filtros.get_child(2).pressed.emit()
	correcto = correcto and titulos(tarjetas) == [["Falla de comunicación en la red"],
		["Faro delantero apagado", "Pérdida de aislamiento"], ["Módulo auxiliar sin respuesta"]]
	var elegidas: Array[String] = []
	pantalla.orden_elegida.connect(func(archivo: String): elegidas.append(archivo.get_file()))
	tarjetas.find_children("*", "Button", true, false)[0].pressed.emit()
	correcto = correcto and elegidas == ["comunicacion.json"]
	pantalla.free()
	return correcto


static func titulos(tarjetas: VBoxContainer) -> Array:
	var resultado := []
	for seccion in tarjetas.get_children():
		var titulos_seccion: Array[String] = []
		for tarjeta in seccion.find_children("*", "Button", true, false):
			titulos_seccion.append(tarjeta.find_child("Titulo", true, false).text)
		resultado.append(titulos_seccion)
	return resultado
