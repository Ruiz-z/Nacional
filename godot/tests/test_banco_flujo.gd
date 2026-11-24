extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

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
	if zona.piezas.size() != 4 or zona.pantalla.text != "—":
		return "El banco no muestra los tres bornes y la pantalla en reposo."
	var aviso: String = bus.interior.pantalla.text
	var aviso_banco: String = zona.estado_banco.text
	if aviso != "MÓDULO AUXILIAR · SIN RESPUESTA" or not aviso_banco.contains("banco en pantalla"):
		return "Falta el aviso del módulo o la fuente del banco."
	if not Taller.equipar(bus, "medir_tp1"):
		return "No se pudo empuñar el multímetro."
	await arbol.physics_frame
	await arbol.physics_frame
	for paso in [["tp1", "—", "La punta negra va en TP0."],
			["tp0", "—", "Polaridad invertida. Empieza en TP0."], ["tp0", "—", ""], ["tp0", "0.0 V", ""]]:
		if not apuntar_y_pulsar(bus, paso[0]) or zona.pantalla.text != paso[1]:
			return "No se manejaron las puntas invertidas o TP0 contra TP0."
		if bus.flashcard.visible != (not paso[2].is_empty()):
			return "La advertencia de puntas no se mostró cuando correspondía."
		if bus.flashcard.visible:
			if bus.flashcard.cuerpo.text != paso[2]:
				return "La tarjeta no explicó cómo colocar las puntas."
			bus.flashcard.ok.pressed.emit()
	if not bus.motor.mediciones.medidas.is_empty():
		return "Se guardó una medición sin un borne válido."
	for paso in [["tp0", "—"], ["tp1", "0.0 V"], ["tp0", "—"], ["tp2", "5.0 V"]]:
		if not apuntar_y_pulsar(bus, paso[0]) or zona.pantalla.text != paso[1]:
			return "El clic en %s no produjo la lectura esperada." % paso[0]
	if bus.resultado.text != "Medición registrada: TP2 = 5.0 V. Abre el multímetro y reporta la lectura de TP1.":
		return "El aviso central no muestra el punto y la tensión."
	if not bus.jugador.herramientas.multimetro.visible:
		return "El jugador no tiene el multímetro en la mano."
	if not apuntar_y_pulsar(bus, "multimetro") or not bus.menu_pieza.visible:
		return "El clic en el multímetro no abrió el registro."
	await arbol.process_frame
	await arbol.process_frame
	var menu: CanvasLayer = bus.menu_pieza
	for indice in [0, 4]:
		pulsar(menu.lecturas[indice])
	if bus.motor.mediciones.reportadas != {"tp1": "0", "tp2": "5"}:
		return "Los botones de lectura no guardaron ambas opciones."
	if bus.resultado.text != ("Lecturas anotadas. Abre el multímetro y elige la causa que indiquen tus lecturas.") or not bus.resultado.visible:
		return "El registro no muestra su confirmación."
	pulsar(menu.botones[0])
	if bus.motor.mediciones.diagnostico != "alimentacion" or not bus.motor.mediciones.error_diagnostico.is_empty():
		return "El diagnóstico correcto no se registró."
	if not Taller.equipar(bus, "reconectar") or not apuntar_y_pulsar(bus, "multimetro"):
		return "No se pudo volver al multímetro para reparar."
	await arbol.process_frame
	await arbol.process_frame
	pulsar(menu.botones[-1])
	if bus.accion_pendiente != "reconectar" or not bus.motor.fin().is_empty():
		return "La reparación no esperó la confirmación."
	await arbol.process_frame
	pulsar(bus.panel.get_node("Confirmar"))
	if bus.motor.fin() != "resuelto" or bus.motor.puntaje() != 100 or bus.interior.falla_auxiliar:
		return "El panel no cerró la falla."
	if not Taller.cerrar_orden(bus):
		return "No se mostró el cierre de la orden."
	bus.reintentar()
	if not bus.motor.estado().s2_abierto or not bus.motor.mediciones.medidas.is_empty() \
			or bus.interior.pantalla.text != aviso or zona.estado_banco.text != aviso_banco:
		return "El reintento no alternó la falla con el mismo aviso."
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
