extends RefCounted

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var correcta := true
	for caso in [["faros", "caja_fusibles"], ["motor", "tapa_motor"], ["aislamiento", "compuerta"]]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % caso[0]
		var visor := SubViewport.new()
		visor.size = Vector2i(1280, 720)
		visor.own_world_3d = true
		arbol.root.add_child(visor)
		visor.add_child(bus)
		var fallo := await comprobar(bus, caso[1], arbol)
		if not fallo.is_empty():
			printerr("%s: %s" % [caso[0], fallo])
			correcta = false
		visor.free()
	return correcta


static func comprobar(bus: Node3D, acceso: String, arbol: SceneTree) -> String:
	var zona: Node3D = bus.zona_activa
	var tapa: StaticBody3D = zona.piezas[acceso]
	if zona.abierta:
		return "La tapa ya está abierta al aparecer."
	await arbol.physics_frame
	await arbol.physics_frame
	await arbol.physics_frame
	var rayo: RayCast3D = bus.alcance
	rayo.force_raycast_update()
	if rayo.get_collider() != tapa:
		return "El rayo desde %s alcanza %s, se esperaba %s en %s." % [
			rayo.global_position, rayo.get_collider(), acceso, tapa.global_position]
	if rayo.global_position.distance_to(rayo.get_collision_point()) >= rayo.target_position.length():
		return "La tapa está fuera del alcance."
	# Headless no captura el ratón. Habilita el muestreo físico de la mira durante estos pasos.
	bus.modo_captura = true
	var camara: Camera3D = bus.jugador.camara
	var inclinacion := camara.rotation.x
	if acceso != "compuerta":
		camara.rotation.x = deg_to_rad(70)
	await arbol.physics_frame
	await arbol.physics_frame
	await arbol.physics_frame
	bus.modo_captura = false
	camara.rotation.x = inclinacion
	# En faros y motor, el clic llega al volver a apuntar antes del siguiente paso físico.
	bus.recibir_accion(bus.panel.entrada.traducir("teclado", "clic", 1))
	var menu: CanvasLayer = bus.menu_pieza
	if not menu.visible:
		return "El clic sobre la tapa no abrió su menú."
	var indice: int = menu.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.id == "inspeccionar" and entrada.titulo == "Inspeccionar")
	if indice < 0:
		return "No aparece Inspeccionar en el menú de la tapa."
	await arbol.process_frame
	await arbol.process_frame
	var boton: Button = menu.botones[indice]
	clic(bus.get_viewport(), boton.get_global_rect().get_center())
	if not is_instance_valid(zona.animacion) or not zona.animacion.is_running():
		return "Inspeccionar no inició el Tween."
	await arbol.create_timer(0.65).timeout
	if not zona.abierta or not zona.bisagra.rotation_degrees.is_equal_approx(zona.giro_abierto):
		return "La tapa no terminó de abrir: %s." % zona.bisagra.rotation_degrees
	var cuerpo := bus.get_node("Autobus/Bus_Body") as MeshInstance3D
	var casco := cuerpo.global_transform * cuerpo.get_aabb()
	var placa: MeshInstance3D = tapa.superficie
	var limites := placa.global_transform * placa.get_aabb()
	if casco.intersects(limites):
		return "La tapa abierta invade el casco: %s." % limites
	var interiores: Array = {
		"caja_fusibles": ["conector_faros", "fusible_faros", "rele_faros", "faro_izquierdo", "faro_derecho"],
		"tapa_motor": ["monitor_temperatura", "motor_traccion", "bomba_motor", "radiador_motor", "inversor_motor"],
		"compuerta": ["monitor"],
	}[acceso]
	for id: String in interiores:
		var pieza: StaticBody3D = zona.piezas[id]
		bus.apuntar_jugador(pieza.global_position)
		rayo.force_raycast_update()
		if rayo.get_collider() != pieza:
			return "Con la tapa abierta, la mira alcanza %s en vez de %s." % [rayo.get_collider(), id]
	return ""

static func clic(ventana: Viewport, posicion: Vector2) -> void:
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.position = posicion
	evento.global_position = posicion
	evento.pressed = true
	ventana.push_input(evento, true)
	evento = evento.duplicate()
	evento.pressed = false
	ventana.push_input(evento, true)
