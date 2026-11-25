extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Epp = preload("res://logica/simulador/epp.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var raiz := arbol.root
	for nombre in ["faros", "motor", "neumatico_pinchado"]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % nombre
		bus.epp_obligatorio = true
		raiz.add_child(bus)
		var correcto := await comprobar(bus, arbol)
		bus.free()
		if not correcto:
			printerr("Estación EPP: ", nombre)
			return false
	var libre := Bus.instantiate()
	libre.archivo = "escenarios/faros.json"
	raiz.add_child(libre)
	var sin_epp: bool = libre.estacion_epp == null and not libre.motor.epp_pendiente()
	libre.free()
	return sin_epp


static func comprobar(bus: Node3D, arbol: SceneTree) -> bool:
	var estacion: Node3D = bus.estacion_epp
	if estacion == null or not bus.motor.epp_pendiente() or bus.jugador.activo:
		return false
	bus.flashcard.confirmar()
	if not bus.jugador.activo or bus.taller.pieza_guia != estacion \
			or bus.hud_mision.titulo.text != "Ponte el EPP en el casillero":
		return false
	var ofrecidos := Epp.ofrecidos(bus.datos)
	if estacion.ofrecidos != ofrecidos or not estacion.elegidos().is_empty():
		return false
	bus.jugador.set_physics_process(false)
	bus.jugador.ubicar(estacion.ENTRADA + Vector3.BACK * 0.65)
	await arbol.physics_frame
	for id in ofrecidos:
		if not estacion.piezas[id] is StaticBody3D or not apuntar(bus, id):
			return false
	var id := ofrecidos[0]
	if not interactuar(bus, id) or estacion.elegidos() != [id] or estacion.modelos[id].visible \
			or not bus.puesto_epp.text.contains(Epp.nombre(id)):
		return false
	if not interactuar(bus, id) or not estacion.elegidos().is_empty() or not estacion.modelos[id].visible:
		return false
	if not interactuar(bus, estacion.LISTO) or not bus.flashcard.visible \
			or bus.flashcard.cola[0].tipo != "falta" or not bus.motor.epp_pendiente() or bus.jugador.activo:
		return false
	var aviso: String = bus.flashcard.cola[0].texto
	var requeridos := Epp.requeridos(bus.datos)
	for requerido in requeridos:
		if not aviso.contains(Epp.nombre(requerido)) or not aviso.contains(Epp.MOTIVOS[requerido]):
			return false
	bus.flashcard.confirmar()
	var primera: String = bus.datos.ruta_ideal[0]
	var rechazo: Dictionary = bus.motor.ejecutar(primera, "teclado", 0)
	if rechazo.aplicada or not rechazo.motivo.contains("EPP") or not bus.jugador.activo:
		return false
	for requerido in requeridos:
		if not interactuar(bus, requerido):
			return false
	if not interactuar(bus, estacion.LISTO):
		return false
	return not bus.motor.epp_pendiente() and not estacion.disponible and bus.jugador.activo \
		and bus.resultado.text == "EPP puesto. Ya puedes trabajar."


static func apuntar(bus: Node3D, id: String) -> bool:
	var pieza: StaticBody3D = bus.estacion_epp.piezas[id]
	bus.apuntar_jugador(pieza.global_position)
	bus.alcance.force_raycast_update()
	return bus.alcance.get_collider() == pieza


static func interactuar(bus: Node3D, id: String) -> bool:
	if not apuntar(bus, id):
		return false
	bus.recibir_accion({"accion": "inspeccionar", "fuente_entrada": "control", "valor": 1})
	return true
