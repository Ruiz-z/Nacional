extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")
const Protocolo = preload("res://logica/entrada/protocolo.gd")
const REPARAR := "Elige Reconectar conductor en el banco. Confirma en el panel."
const CONFIRMAR_FAROS := "Elige Confirmar la solución en el relé y confirma en el panel."


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var tamano := arbol.root.size
	arbol.root.size = Vector2i(1280, 720)
	var correcta := await probar_ordenes(arbol)
	arbol.root.size = tamano
	return correcta


static func probar_ordenes(arbol: SceneTree) -> bool:
	var inicio := {
		"aislamiento": "Inspecciona el gabinete",
		"comunicacion": "Revisa los síntomas de la red",
		"faros": "Inspecciona la caja de fusibles",
		"modulo_auxiliar": "Mide TP1 y TP2 con el multímetro",
		"motor": "Inspecciona la tapa del motor",
	}
	for orden in inicio:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % orden
		arbol.root.add_child(bus)
		bus.flashcard.confirmar()
		await arbol.process_frame
		var correcta := comprobar_ayuda(bus, inicio[orden])
		if correcta and orden == "faros":
			correcta = await recorrer_faros(bus, arbol)
		if correcta and orden == "modulo_auxiliar":
			correcta = await recorrer_banco(bus, arbol)
		bus.free()
		if not correcta:
			printerr("Falló la guía o la confirmación de la orden ", orden)
			return false
	return true


static func recorrer_faros(bus: Node3D, arbol: SceneTree) -> bool:
	if not elegir(bus, "caja_fusibles", "inspeccionar") \
			or not comprobar_ayuda(bus, "Mide la continuidad en el conector de los faros.") \
			or not elegir(bus, "conector_faros", "medir_continuidad") \
			or not comprobar_ayuda(bus, "Elige Cambiar el foco en el faro izquierdo. Confirma en el panel.") \
			or not Taller.equipar(bus, "cambiar_foco_correcto") \
			or not elegir(bus, "faro_izquierdo", "cambiar_foco_correcto"):
		return false
	if not await confirmar(bus, arbol, "cambiar_foco_correcto") \
			or not bus.motor.estado().foco_repuesto \
			or not comprobar_ayuda(bus, CONFIRMAR_FAROS) \
			or not elegir(bus, "rele_faros", "confirmar_solucion"):
		return false
	bus.recibir_accion({"accion": "cancelar", "fuente_entrada": "teclado"})
	if not bus.accion_pendiente.is_empty() or bus.menu_pieza.visible \
			or bus.panel.get_node("Confirmar").theme_type_variation == &"Primario" \
			or not comprobar_ayuda(bus, CONFIRMAR_FAROS) \
			or not elegir(bus, "rele_faros", "confirmar_solucion"):
		return false
	return await confirmar(bus, arbol, "confirmar_solucion") and comprobar_resuelto(bus)


static func recorrer_banco(bus: Node3D, arbol: SceneTree) -> bool:
	if not Taller.equipar(bus, "medir_tp1"):
		return false
	for borne in ["tp0", "tp1", "tp0", "tp2"]:
		bus.tocar_borne(borne, "teclado")
		if bus.flashcard.visible:
			bus.flashcard.confirmar()
	if not comprobar_ayuda(bus, "Anota las lecturas en la hoja"):
		return false
	bus.abrir_menu(bus.zona_activa.piezas.hoja_diagnostico)
	for numero in [1, 5, 7]:
		Taller.tecla(bus, numero)
	bus.hoja.guardar.pressed.emit()
	if not comprobar_ayuda(bus, REPARAR) or bus.flashcard.visible:
		return false
	if not elegir(bus, "conductor_banco", "reconectar"):
		return false
	return await confirmar(bus, arbol, "reconectar") and comprobar_resuelto(bus)


static func elegir(bus: Node3D, pieza: String, id: String) -> bool:
	Taller.cerrar_exitos(bus)
	if not bus.menu_pieza.visible:
		if not Taller.equipar(bus, id):
			return false
		bus.abrir_menu(bus.zona_activa.piezas[pieza])
	var indice: int = bus.menu_pieza.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.id == id)
	if not bus.menu_pieza.visible or indice < 0:
		return false
	bus.elegir_accion(indice, "teclado")
	return true


static func confirmar(bus: Node3D, arbol: SceneTree, id: String) -> bool:
	# Deja asentar el diseño y respeta el antirrebote entre confirmaciones.
	await arbol.create_timer((Protocolo.REBOTE_MS + 50) / 1000.0).timeout
	var boton: Button = bus.panel.get_node("Confirmar")
	var franja: Label = bus.menu_pieza.contenido.get_node("Pendiente")
	if bus.accion_pendiente != id or not boton.is_visible_in_tree() or boton.disabled \
			or boton.theme_type_variation != &"Primario" or not franja.is_visible_in_tree() \
			or not franja.text.begins_with("Acción lista: confirma en el panel"):
		return false
	var centro := boton.get_global_rect().get_center()
	var movimiento := InputEventMouseMotion.new()
	movimiento.position = centro
	movimiento.global_position = centro
	arbol.root.push_input(movimiento)
	for pulsado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = pulsado
		evento.position = centro
		evento.global_position = centro
		arbol.root.push_input(evento)
		await arbol.process_frame
	return bus.accion_pendiente.is_empty() and not franja.is_visible_in_tree() \
		and boton.theme_type_variation != &"Primario"


static func comprobar_ayuda(bus: Node3D, texto: String) -> bool:
	Taller.mostrar_siguiente_mision(bus)
	return bus.hud_mision.visible and (bus.hud_mision.titulo.text == texto \
		or (bus.hud_mision.ayuda.visible and bus.hud_mision.ayuda.text == texto))


static func comprobar_resuelto(bus: Node3D) -> bool:
	Taller.mostrar_siguiente_mision(bus)
	return bus.motor.fin() == "resuelto" and not bus.hud_mision.visible
