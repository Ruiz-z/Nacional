extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Protocolo = preload("res://logica/entrada/protocolo.gd")
const Bus = preload("res://escenas/bus.tscn")
const Clic = preload("res://tests/test_zonas_flujo.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/modulo_auxiliar.json"
	visor.add_child(bus)
	bus.modo_captura = true
	var fallo := await comprobar(bus, arbol)
	visor.free()
	if not fallo.is_empty():
		printerr(fallo)
	return fallo.is_empty()


static func comprobar(bus: Node3D, arbol: SceneTree) -> String:
	var zona: Node3D = bus.zona_activa
	for variante in [false, true]:
		if not bus.flashcard.visible or not zona.piezas.multimetro.visible or zona.pantalla.text != "—" \
				or bus.taller.mueble_de("multimetro") != zona or not bus.taller.mano.is_empty():
			return "El multímetro debe empezar en la mesa con la tarjeta de orden abierta."
		if bus.motor.estado().s2_abierto != variante or not bus.motor.mediciones.medidas.is_empty():
			return "El reintento debe alternar la falla y borrar las lecturas."
		bus.flashcard.confirmar()
		bus.ubicar_jugador("tp0")
		await arbol.physics_frame
		await arbol.physics_frame
		if not apuntar_y_pulsar(bus, "tp0") or not bus.flashcard.visible \
				or not bus.flashcard.cuerpo.text.contains("Multímetro"):
			return "El borne debe pedir el multímetro si falta."
		bus.flashcard.confirmar()
		if not apuntar_y_pulsar(bus, "multimetro") or not bus.menu_pieza.visible:
			return "El clic debe alcanzar el multímetro de la mesa."
		await arbol.process_frame
		pulsar(bus.menu_pieza.botones[0])
		if bus.taller.mano != "multimetro" or zona.piezas.multimetro.visible or zona.pantalla.visible:
			return "Tomar el multímetro debe empuñarlo y apagar la pantalla de la mesa."
		if not apuntar_y_pulsar(bus, "tp1") or not bus.flashcard.visible \
				or bus.flashcard.cuerpo.text != "La punta negra va en TP0.":
			return "La punta invertida debe mostrar el aviso."
		bus.flashcard.confirmar()
		if not apuntar_y_pulsar(bus, "tp0") or not zona.pinzas.tp0.visible:
			return "Debe aparecer la pinza negra."
		if not apuntar_y_pulsar(bus, "tp1") or not zona.pinzas.tp1.visible:
			return "Debe aparecer la pinza roja en TP1."
		if bus.jugador.pantalla_multimetro.text != ("5.0 V" if variante else "0.0 V"):
			return "La lectura de TP1 debe aparecer en el multímetro de mano."
		Taller.cerrar_exitos(bus)
		if bus.hud_mision.progreso != [false, false, false, false]:
			return "Medir un borne no debe cumplir la misión compuesta."
		if not apuntar_y_pulsar(bus, "tp0") or zona.pinzas.tp1.visible \
				or not apuntar_y_pulsar(bus, "tp2") or not zona.pinzas.tp2.visible:
			return "La pinza roja debe pasar de TP1 a TP2."
		if bus.jugador.pantalla_multimetro.text != ("0.0 V" if variante else "5.0 V") \
				or bus.indicador_puntas.text != "Punta negra: TP0 · Punta roja: TP2":
			return "Falta la lectura en la mano o el indicador de puntas."
		Taller.cerrar_exitos(bus)
		if bus.hud_mision.progreso != [true, false, false, false]:
			return "Medir los dos bornes debe cumplir la misión compuesta."
		if not apuntar_y_pulsar(bus, "mesa_banco") or not Taller.elegir(bus, "dejar") \
				or not zona.piezas.multimetro.visible or zona.pinzas.tp0.visible or zona.pinzas.tp2.visible:
			return "Dejar el multímetro debe devolverlo a la mesa y retirar las pinzas."
		if not apuntar_y_pulsar(bus, "hoja_diagnostico") or not bus.hoja.visible:
			return "El clic debe abrir la hoja."
		await arbol.process_frame
		pulsar(bus.hoja.guardar)
		if bus.hoja.aviso.text != "Elige la lectura de TP1." or not bus.motor.mediciones.reportadas.is_empty():
			return "Una hoja incompleta debe mostrar el bloque pendiente sin guardar."
		for opcion in ([1, 3, 7] if variante else [0, 4, 6]):
			pulsar(bus.hoja.opciones[opcion])
		pulsar(bus.hoja.guardar)
		if bus.hoja.visible or not bus.motor.mediciones.error_diagnostico.is_empty() \
				or bus.hud_mision.progreso != [true, true, true, false]:
			return "Guardar la hoja debe registrar ambas lecturas y la causa."
		if not Taller.equipar(bus, "medir_tp1") or not Taller.equipar(bus, "reconectar") \
				or not apuntar_y_pulsar(bus, "conductor_banco"):
			return "El conductor debe abrir el menú de reparación."
		await arbol.process_frame
		pulsar(bus.menu_pieza.botones[0])
		if bus.accion_pendiente != "reconectar" or not bus.motor.fin().is_empty():
			return "La reparación debe esperar la confirmación."
		await arbol.create_timer((Protocolo.REBOTE_MS + 50) / 1000.0).timeout
		pulsar(bus.panel.get_node("Confirmar"))
		if bus.motor.fin() != "resuelto" or bus.motor.puntaje() != 100 or bus.interior.falla_auxiliar:
			return "La confirmación del panel debe cerrar la falla."
		if not Taller.cerrar_orden(bus):
			return "Debe aparecer el cierre de la orden."
		bus.reintentar()
	return ""

static func apuntar_y_pulsar(bus: Node3D, id: String) -> bool:
	var pieza: StaticBody3D = bus.zona_activa.piezas[id]
	bus.apuntar_jugador(pieza.global_position)
	bus.alcance.force_raycast_update()
	if bus.alcance.get_collider() != pieza:
		return false
	Clic.clic(bus.get_viewport(), bus.get_viewport().get_visible_rect().get_center())
	return true


static func pulsar(boton: Button) -> void:
	Clic.clic(boton.get_viewport(), boton.get_global_rect().get_center())
