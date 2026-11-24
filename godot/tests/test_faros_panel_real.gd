extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	for variante in ["ideal", "fusible", "chispa", "confirmacion_anticipada"]:
		var visor := SubViewport.new()
		visor.size = Vector2i(1280, 720)
		visor.own_world_3d = true
		arbol.root.add_child(visor)
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/faros.json"
		visor.add_child(bus)
		await arbol.process_frame
		var correcta := await recorrer(bus, variante, arbol)
		visor.free()
		if not correcta:
			printerr("Recorrido de faros: ", variante)
			return false
	return true


static func recorrer(bus: Node3D, variante: String, arbol: SceneTree) -> bool:
	if not comprobar_indicios(bus, 0):
		return false
	if not await paso(bus, "caja_fusibles", "inspeccionar", arbol) or not comprobar_indicios(bus, 1):
		return false
	if not await paso(bus, "conector_faros", "medir_continuidad", arbol) or not comprobar_indicios(bus, 2):
		return false
	match variante:
		"fusible":
			if not await paso(bus, "fusible_faros", "reponer_fusible_equivocado", arbol) \
					or not bus.motor.estado().fusible_quemado:
				return false
			bus.flashcard.ok.pressed.emit()
			if not await paso(bus, "fusible_faros", "reponer_fusible", arbol) \
					or bus.motor.estado().fusible_quemado:
				return false
		"chispa":
			if not await paso(bus, "faro_izquierdo", "cambiar_foco_sin_desconectar", arbol) \
					or not bus.zona_activa.chispa.visible:
				return false
			bus.flashcard.ok.pressed.emit()
		"confirmacion_anticipada":
			if not await paso(bus, "rele_faros", "confirmar_solucion", arbol, false) \
					or not bus.flashcard.visible or bus.flashcard.titulo.text != "Aún no puedes hacerlo" \
					or bus.flashcard.cuerpo.text != "Antes de seguir, revisa lo que falta: Foco izquierdo repuesto. Elige Cambiar el foco en el faro izquierdo. Confirma en el panel." \
					or not comprobar_indicios(bus, 2):
				return false
			bus.flashcard.ok.pressed.emit()
	if not await paso(bus, "faro_izquierdo", "cambiar_foco_correcto", arbol) \
			or bus.zona_activa.chispa.visible or not comprobar_indicios(bus, 3):
		return false
	if not await paso(bus, "rele_faros", "confirmar_solucion", arbol):
		return false
	return bus.motor.fin() == "resuelto" and comprobar_indicios(bus, 4)


static func paso(bus: Node3D, pieza: String, id: String, arbol: SceneTree, aplicada := true) -> bool:
	if not Taller.equipar(bus, id):
		return false
	bus.abrir_menu(bus.zona_activa.piezas[pieza])
	var indice: int = bus.menu_pieza.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.id == id)
	if not bus.menu_pieza.visible or indice < 0:
		return false
	var decisiones: Array[Dictionary] = []
	var registrar := func(decision: Dictionary): decisiones.append(decision)
	bus.decision_tomada.connect(registrar)
	bus.menu_pieza.botones[indice].pressed.emit()
	var requiere_panel: bool = bus.menu_pieza.entradas[indice].requiere_panel
	if requiere_panel and bus.accion_pendiente == id and decisiones.is_empty():
		await arbol.create_timer(0.2).timeout
		bus.panel.emitir("confirmar", 1)
		await arbol.create_timer(0.2).timeout
	bus.decision_tomada.disconnect(registrar)
	return decisiones.size() == 1 and decisiones[0].accion == id and decisiones[0].aplicada == aplicada \
		and decisiones[0].fuente_entrada == ("virtual" if requiere_panel else "teclado")


static func comprobar_indicios(bus: Node3D, completados: int) -> bool:
	Taller.mostrar_siguiente_mision(bus)
	var progreso: Dictionary = bus.progreso_indicios(bus.motor.estado())
	for indice in bus.misiones.size():
		if progreso[bus.misiones[indice].clave] != (indice < completados):
			return false
	return not bus.hud_mision.visible if completados == bus.misiones.size() \
		else bus.hud_mision.indice == completados
