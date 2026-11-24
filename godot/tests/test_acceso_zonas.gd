extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")


static func ejecutar() -> bool:
	var raiz := (Engine.get_main_loop() as SceneTree).root
	for caso in [
		["aislamiento", "monitor", "la compuerta"],
		["faros", "fusible_faros", "la caja de fusibles"],
		["motor", "inversor_motor", "la tapa del motor"],
	]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % caso[0]
		raiz.add_child(bus)
		bus.flashcard.confirmar()
		var correcta := comprobar(bus, caso[1], caso[2])
		bus.free()
		if not correcta:
			printerr("Acceso de zona: ", caso[0])
			return false
	return true


static func comprobar(bus: Node3D, componente: String, nombre: String) -> bool:
	var zona: Node3D = bus.zona_activa
	var interna: StaticBody3D = zona.piezas[componente]
	var decisiones: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary): decisiones.append(decision))
	var inicial: Dictionary = bus.motor.estado()
	var puntaje: int = bus.motor.puntaje()
	if interna.collision_layer != 0 or not acceso(bus, "Abrir " + nombre) or not zona.abierta:
		return false
	bus.mostrar_estado()
	if not zona.abierta or interna.collision_layer != 2 or bus.motor.estado() != inicial:
		return false
	if not acceso(bus, "Cerrar " + nombre) or zona.abierta or interna.collision_layer != 0:
		return false
	if not decisiones.is_empty() or bus.motor.puntaje() != puntaje:
		return false
	if not Taller.equipar(bus, "inspeccionar"):
		return false
	bus.abrir_menu(interna)
	if bus.menu_pieza.visible or not acceso(bus, "Inspeccionar", false) or not zona.abierta:
		return false
	Taller.cerrar_exitos(bus)
	if not acceso(bus, "Cerrar " + nombre):
		return false
	bus.mostrar_estado(true)
	if zona.abierta or zona.bisagra.rotation != Vector3.ZERO or interna.collision_layer != 0:
		return false
	if not acceso(bus, "Abrir " + nombre) or interna.collision_layer != 2:
		return false
	bus.abrir_menu(interna)
	return bus.menu_pieza.visible and not bus.menu_pieza.entradas.is_empty() \
		and decisiones.size() == 1 and bus.motor.estado().inspeccionado and bus.motor.puntaje() == puntaje


static func acceso(bus: Node3D, titulo: String, navegacion := true) -> bool:
	bus.abrir_menu(bus.zona_activa.piezas[bus.zona_activa.acceso])
	var indice: int = bus.menu_pieza.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.titulo == titulo and entrada.get("navegacion", false) == navegacion)
	if not bus.menu_pieza.visible or indice < 0:
		return false
	bus.menu_pieza.botones[indice].pressed.emit()
	return not bus.menu_pieza.visible
