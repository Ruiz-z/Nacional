extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var bus := Bus.instantiate()
	arbol.root.add_child(bus)
	bus.flashcard.confirmar()
	var navegacion: bool = await comprobar_navegacion(bus, arbol)
	bus.free()
	bus = Bus.instantiate()
	bus.archivo = "escenarios/comunicacion.json"
	arbol.root.add_child(bus)
	bus.flashcard.confirmar()
	var diagnostico := comprobar_diagnostico(bus)
	bus.free()
	return navegacion and diagnostico


static func comprobar_navegacion(bus: Node3D, arbol: SceneTree) -> bool:
	var jugador: CharacterBody3D = bus.jugador
	var exterior: Vector3 = bus.puerta_pasajeros.global_position
	var retorno := Vector3(-2.65, 0, exterior.z)
	var estado: Dictionary = bus.motor.estado()
	var ultimo: int = bus.ultimo_ms
	bus.ubicar_jugador(bus.zona_activa.acceso)
	jugador.ubicar(retorno)
	bus.apuntar_jugador(exterior)
	await arbol.physics_frame
	await arbol.physics_frame
	bus.alcance.force_raycast_update()
	if bus.alcance.get_collider() != bus.puerta_pasajeros:
		return false
	bus.avisar_temporal("Compuerta abierta")
	bus.abrir_menu(bus.puerta_pasajeros)
	if not bus.resultado.visible or bus.menu_pieza.entradas.size() != 1:
		return false
	bus.elegir_accion(0, "teclado")
	if not bus.negro.visible or jugador.activo or jugador.global_position != retorno:
		return false
	await arbol.create_timer(0.5).timeout
	if bus.negro.visible or not jugador.activo or bus.interior.falla_red 			or not jugador.global_position.is_equal_approx(bus.interior.to_global(bus.interior.ENTRADA)):
		return false

	var borde := Vector3(1.15, 0.01, bus.interior.ENTRADA.z)
	bus.ubicar_interior(borde, "puerta_salida")
	await arbol.physics_frame
	await arbol.physics_frame
	if not jugador.test_move(jugador.global_transform, Vector3(0.6, 0, 0)):
		return false
	bus.ubicar_interior(Vector3(0, 0, 5.1), "monitor")
	await arbol.physics_frame
	await arbol.physics_frame
	if not jugador.test_move(jugador.global_transform, Vector3(0, 0, 1)):
		return false
	bus.ubicar_interior(bus.interior.ENTRADA, "puerta_salida")
	await arbol.physics_frame
	await arbol.physics_frame
	bus.alcance.force_raycast_update()
	var salida := bus.alcance.get_collider() as StaticBody3D
	if salida != bus.interior.piezas.puerta_salida:
		return false
	bus.abrir_menu(salida)
	bus.elegir_accion(0, "teclado")
	await arbol.create_timer(0.5).timeout
	return jugador.global_position.is_equal_approx(retorno) and bus.motor.estado() == estado \
		and bus.ultimo_ms == ultimo and not bus.negro.visible


static func comprobar_diagnostico(bus: Node3D) -> bool:
	var interior: Node3D = bus.interior
	if bus.zona_activa != interior or "SIN COMUNICACIÓN" not in interior.pantalla.text \
			or bus.jugador.global_position != interior.to_global(interior.CABINA):
		return false
	bus.abrir_menu(interior.piezas.fusibles_cabina)
	if not bus.menu_pieza.visible or not bus.menu_pieza.entradas.is_empty():
		return false
	bus.cerrar_menu()
	for id in bus.datos.ruta_ideal:
		if not Taller.equipar(bus, id):
			return false
		var regla: Dictionary = bus.datos.acciones[id]
		bus.abrir_menu(interior.piezas[regla.componente])
		var indice := -1
		for i in range(bus.menu_pieza.entradas.size()):
			if bus.menu_pieza.entradas[i].id == id:
				indice = i
				break
		if indice < 0:
			return false
		bus.elegir_accion(indice, "teclado")
		if regla.get("requiere_panel", false):
			bus.panel.get_node("Confirmar").pressed.emit()
	return bus.motor.fin() == "resuelto" and interior.pantalla.text.ends_with("NORMAL")
