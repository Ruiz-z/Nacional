extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Acciones = preload("res://tests/acciones_taller.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/motor.json"
	visor.add_child(bus)
	bus.flashcard.confirmar()
	bus.jugador.set_physics_process(false)
	var correcto := await recorrer(bus, arbol)
	if correcto:
		correcto = await comprobar_formato(bus, visor, arbol)
	visor.free()
	return correcto


static func recorrer(bus: Node3D, arbol: SceneTree) -> bool:
	var hud: Control = bus.hud_mision
	if hud.contador.text != "MISIÓN 1 DE 6" or hud.titulo.text != "Inspecciona la tapa del motor" 			or not fila(hud, "Toma Destornillador", false) or hud.progreso != [false, false, false, false, false, false]:
		return false
	bus.taller.cambiar_cajones(true, true)
	bus.abrir_menu(bus.taller.objetos.destornillador)
	if not Acciones.elegir(bus, "tomar"):
		return false
	Acciones.tecla(bus, 4)
	if not fila(hud, "Toma Destornillador", true) or not fila(hud, "Ten Destornillador en la mano (1)", false):
		return false
	Acciones.tecla(bus, 1)
	bus.abrir_menu(bus.zona_activa.piezas.tapa_motor)
	if not fila(hud, "Ten Destornillador en la mano (1)", true) or not Acciones.elegir(bus, "inspeccionar"):
		return false
	if not hud.celebrando or not hud.celebracion.visible or not hud.progreso[0] 			or bus.flashcard.visible or not bus.jugador.activo:
		return false
	# Ejecuta la segunda acción durante la celebración y deja avanzar el reloj de la escena.
	if not Acciones.equipar(bus, "revisar_refrigerante"):
		return false
	bus.ejecutar("revisar_refrigerante", "teclado")
	if not bus.motor.estado().refrigerante_revisado or not hud.celebrando:
		return false
	await arbol.create_timer(1.45).timeout
	if hud.celebrando or hud.contador.text != "MISIÓN 3 DE 6" or not hud.progreso[1]:
		return false
	if not Acciones.equipar(bus, "medir_temperatura"):
		return false
	bus.ejecutar("medir_temperatura", "teclado")
	Acciones.cerrar_exitos(bus)
	Acciones.mostrar_siguiente_mision(bus)
	if hud.contador.text != "MISIÓN 4 DE 6" or hud.titulo.text != "Bloquea y etiqueta el motor" 			or not Acciones.equipar(bus, "bloquear_y_etiquetar"):
		return false
	var seguridad := "Activa Bloqueo y Etiquetado en el panel"
	if not fila(hud, seguridad, false):
		return false
	bus.panel.get_node("Bloqueo").button_pressed = true
	bus.panel.get_node("Etiquetado").button_pressed = true
	await arbol.process_frame
	await arbol.process_frame
	if not fila(hud, seguridad, true):
		return false
	bus.abrir_menu(bus.zona_activa.piezas.inversor_motor)
	if not Acciones.elegir(bus, "bloquear_y_etiquetar") or bus.accion_pendiente != "bloquear_y_etiquetar":
		return false
	var eleccion: String = hud.filas[hud.filas.size() - 2].texto
	if not eleccion.begins_with("Elige Bloquear y etiquetar en ") or not fila(hud, eleccion, true) 			or not fila(hud, "Confirma en el panel", false):
		return false
	bus.panel.get_node("Confirmar").pressed.emit()
	if not hud.celebrando or not fila(hud, "Confirma en el panel", true) or bus.flashcard.visible:
		return false
	Acciones.mostrar_siguiente_mision(bus)
	return hud.contador.text == "MISIÓN 5 DE 6" and fila(hud, "Toma Abrazadera", false)


static func comprobar_formato(bus: Node3D, visor: SubViewport, arbol: SceneTree) -> bool:
	var hud: Control = bus.hud_mision
	var titulo := "Aprieta la abrazadera del circuito de refrigerante del motor"
	var respaldo: Dictionary = bus.datos.duplicate(true)
	respaldo.indicios[4].erase("mision")
	if not Escenario.indicios_validos(respaldo):
		return false
	for invalido in ["", "  ", 2, null]:
		respaldo.indicios[4].mision = invalido
		if Escenario.indicios_validos(respaldo):
			return false
	var mision: Dictionary = bus.misiones[4]
	mision.erase("mision")
	bus.firma_mision.clear()
	bus.actualizar_mision()
	if hud.titulo.text != mision.etiqueta:
		return false
	mision.mision = titulo
	bus.firma_mision.clear()
	bus.actualizar_mision()
	for ancho in [1280, 1920]:
		visor.size = Vector2i(ancho, 720 if ancho == 1280 else 1080)
		await arbol.process_frame
		await arbol.process_frame
		if hud.titulo.text != titulo or hud.titulo.get_line_count() < 2 				or hud.titulo.get_visible_line_count() != hud.titulo.get_line_count() 				or not visor.get_visible_rect().encloses(hud.titulo.get_global_rect()):
			return false
	var evento := InputEventKey.new()
	evento.keycode = KEY_H
	evento.pressed = true
	visor.push_input(evento, true)
	if not hud.visible or not hud.titulo.visible or not hud.contador.visible or hud.detalle.visible or hud.marca.visible:
		return false
	visor.push_input(evento, true)
	return hud.detalle.visible and hud.marca.visible


static func fila(hud: Control, texto: String, hecho: bool) -> bool:
	return hud.filas.any(func(subpaso: Dictionary): return subpaso.texto == texto and subpaso.hecho == hecho)
