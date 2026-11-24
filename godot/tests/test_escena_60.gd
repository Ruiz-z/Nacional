extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var bus := Bus.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	var gabinete := bus.get_node("Sector")
	var lateral := bus.get_node("Interfaz/Lateral")
	var correcto: bool = not gabinete.abierta and elegir(bus, "compuerta", "inspeccionar")
	correcto = correcto and gabinete.abierta and elegir(bus, "terminal", "forzar_pieza")
	correcto = correcto and gabinete.fragmento.visible and gabinete.chispa.visible \
		and not gabinete.tornillo.visible and gabinete.lectura == "Rojo"
	correcto = correcto and bus.flashcard.visible
	bus.flashcard.ok.pressed.emit()
	correcto = correcto and Taller.equipar(bus, "reponer_pieza") \
		and elegir(bus, "terminal", "reponer_pieza") \
		and bus.accion_pendiente == "reponer_pieza" and gabinete.fragmento.visible \
		and bus.menu_pieza.contenido.get_node("Cabecera/Estado").text == "Daño"
	bus.panel.get_node("Confirmar").pressed.emit()
	correcto = correcto and not bus.motor.estado().tornillo_roto and gabinete.tornillo.visible \
		and not gabinete.fragmento.visible and gabinete.lectura == "Ámbar"
	correcto = correcto and elegir(bus, "monitor", "evaluar_indicio")
	correcto = correcto and gabinete.lectura == "Verde" and elegir(bus, "bateria", "confirmar_solucion")
	bus.recibir_accion({"accion": "confirmar", "fuente_entrada": "teclado"})
	var resumen := lateral.get_node("Resumen")
	correcto = correcto and resumen.visible and not resumen.get_node("Reintentar").visible
	resumen.get_node("Reflexion").text = "Revisaría el aviso"
	resumen.get_node("Guardar").pressed.emit()
	correcto = correcto and resumen.get_node("Detalle").text.contains("Ruta ideal")
	resumen.get_node("Reintentar").pressed.emit()
	correcto = correcto and not resumen.visible and bus.motor.fin().is_empty() \
		and gabinete.abierta == bus.motor.estado().inspeccionado \
		and bus.taller.inventario.cinturon.is_empty() and not bus.taller.cajones_abiertos
	bus.free()
	return correcto


static func elegir(bus: Node, pieza: String, accion: String) -> bool:
	bus.abrir_menu(bus.get_node("Sector").piezas[pieza])
	for indice in range(bus.menu_pieza.entradas.size()):
		if bus.menu_pieza.entradas[indice].id == accion:
			var boton: Button = bus.menu_pieza.botones[indice]
			boton.pressed.emit()
			return true
	return false
