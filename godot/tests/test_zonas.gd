extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var raiz := (Engine.get_main_loop() as SceneTree).root
	for nombre in ["faros", "motor"]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % nombre
		raiz.add_child(bus)
		bus.flashcard.confirmar()
		var correcto := comprobar(bus, nombre)
		bus.free()
		if not correcto:
			return false
	return true


static func comprobar(bus: Node3D, nombre: String) -> bool:
	var zona: Node3D = bus.get("zona_activa")
	if zona == null:
		return false
	var acceso: StaticBody3D = zona.piezas[zona.acceso]
	var antes: Dictionary = bus.motor.estado()
	bus.abrir_menu(bus.get_node("Sector").piezas.compuerta)
	if not bus.menu_pieza.visible or bus.menu_pieza.entradas.size() != 1 or not bus.menu_pieza.entradas[0].navegacion \
			or bus.menu_pieza.diagnostico.visible or bus.motor.estado() != antes \
			or bus.menu_pieza.contenido.get_node("Lectura").text != "Cerrada":
		return false
	bus.cerrar_menu()
	if not Taller.equipar(bus, "inspeccionar"):
		return false
	bus.abrir_menu(acceso)
	if bus.menu_pieza.entradas.size() != 2 or zona.abierta \
			or bus.jugador.global_position.distance_to(acceso.global_position) > 2.5:
		return false
	bus.elegir_accion(0, "teclado")
	bus.mostrar_estado(true)
	if not zona.abierta or zona.bisagra.rotation == Vector3.ZERO:
		return false
	if nombre == "faros":
		var izquierdo: MeshInstance3D = zona.lentes.faro_izquierdo
		var derecho: MeshInstance3D = zona.lentes.faro_derecho
		if izquierdo.material_override.emission_enabled or not derecho.material_override.emission_enabled:
			return false
		if not Taller.equipar(bus, "medir_continuidad"):
			return false
		bus.ejecutar("medir_continuidad", "teclado")
		if not Taller.equipar(bus, "cambiar_foco_sin_desconectar"):
			return false
		bus.ejecutar("cambiar_foco_sin_desconectar", "teclado")
		if not zona.chispa.visible or not bus.flashcard.visible:
			return false
		bus.flashcard.ok.pressed.emit()
		if not Taller.equipar(bus, "cambiar_foco_correcto"):
			return false
		bus.ejecutar("cambiar_foco_correcto", "virtual")
		return izquierdo.material_override.emission_enabled and not zona.chispa.visible
	if not Taller.equipar(bus, "bloquear_y_etiquetar"):
		return false
	bus.abrir_menu(zona.piezas.inversor_motor)
	bus.elegir_accion(1, "teclado")
	bus.panel.get_node("Bloqueo").button_pressed = true
	bus.panel.get_node("Etiquetado").button_pressed = true
	bus.panel.get_node("Confirmar").pressed.emit()
	if not bus.motor.estado().bloqueo_confirmado or "ALERTA" not in zona.pantalla.text:
		return false
	bus.panel.get_node("Etiquetado").button_pressed = false
	if not Taller.equipar(bus, "tocar_cables_naranja_sin_bloqueo"):
		return false
	bus.abrir_menu(zona.piezas.inversor_motor)
	bus.elegir_accion(0, "teclado")
	return bus.motor.fin() == "falta-critica"
