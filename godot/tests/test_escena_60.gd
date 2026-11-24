extends RefCounted

const Bus = preload("res://escenas/bus.tscn")

static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	bus.ejecutar("inspeccionar", "teclado")
	bus.ejecutar("forzar_pieza", "teclado")
	var lateral := bus.get_node("Interfaz/Lateral")
	var opciones: OptionButton = lateral.get_node("Accion")
	var reparacion := false
	for indice in range(opciones.item_count):
		if opciones.get_item_metadata(indice) == "reponer_pieza":
			opciones.select(indice)
			lateral.get_node("ConfirmarAccion").pressed.emit()
			reparacion = not bus.motor.estado().tornillo_roto
			break
	bus.ejecutar("evaluar_indicio", "teclado")
	bus.ejecutar("confirmar_solucion", "teclado")
	var resumen := bus.get_node("Interfaz/Lateral/Resumen")
	var correcto: bool = reparacion and resumen.visible and not resumen.get_node("Reintentar").visible
	resumen.get_node("Reflexion").text = "Revisaría el aviso"
	resumen.get_node("Guardar").pressed.emit()
	correcto = correcto and resumen.get_node("Detalle").text.contains("Ruta ideal")
	resumen.get_node("Reintentar").pressed.emit()
	correcto = correcto and not resumen.visible and bus.motor.fin().is_empty()
	bus.free()
	return correcto
