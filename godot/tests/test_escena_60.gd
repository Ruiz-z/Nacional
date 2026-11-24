extends RefCounted

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	var gabinete := bus.get_node("Sector")
	var lateral := bus.get_node("Interfaz/Lateral")
	var opciones: OptionButton = lateral.get_node("Accion")
	var correcto: bool = not gabinete.abierta and elegir(bus, "compuerta", "inspeccionar")
	lateral.get_node("ConfirmarAccion").pressed.emit()
	correcto = correcto and gabinete.abierta and elegir(bus, "terminal", "forzar_pieza")
	bus.panel.get_node("Confirmar").pressed.emit()
	correcto = correcto and gabinete.fragmento.visible and gabinete.chispa.visible \
		and not gabinete.tornillo.visible and gabinete.lectura == "Rojo"
	correcto = correcto and elegir(bus, "terminal", "reponer_pieza") \
		and opciones.get_item_text(opciones.selected).contains("costo")
	lateral.get_node("ConfirmarAccion").pressed.emit()
	correcto = correcto and not bus.motor.estado().tornillo_roto and gabinete.tornillo.visible \
		and not gabinete.fragmento.visible and gabinete.lectura == "Ámbar"
	correcto = correcto and elegir(bus, "monitor", "evaluar_indicio")
	lateral.get_node("ConfirmarAccion").pressed.emit()
	correcto = correcto and gabinete.lectura == "Verde" and elegir(bus, "bateria", "confirmar_solucion")
	lateral.get_node("ConfirmarAccion").pressed.emit()
	var resumen := lateral.get_node("Resumen")
	correcto = correcto and resumen.visible and not resumen.get_node("Reintentar").visible
	resumen.get_node("Reflexion").text = "Revisaría el aviso"
	resumen.get_node("Guardar").pressed.emit()
	correcto = correcto and resumen.get_node("Detalle").text.contains("Ruta ideal")
	resumen.get_node("Reintentar").pressed.emit()
	correcto = correcto and not resumen.visible and bus.motor.fin().is_empty() \
		and gabinete.abierta == bus.motor.estado().inspeccionado
	bus.free()
	return correcto


static func elegir(bus: Node, pieza: String, accion: String) -> bool:
	bus.abrir_menu(bus.get_node("Sector").piezas[pieza])
	var opciones: OptionButton = bus.get_node("Interfaz/Lateral/Accion")
	for indice in range(1, opciones.item_count):
		if opciones.get_item_metadata(indice) == accion:
			bus.recibir_accion({"accion": "elegir-accion", "valor": indice})
			return true
	return false
