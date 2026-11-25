extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Epp = preload("res://logica/simulador/epp.gd")


static func ejecutar() -> bool:
	var raiz := (Engine.get_main_loop() as SceneTree).root
	for nombre in ["faros", "motor", "neumatico_pinchado"]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % nombre
		bus.epp_obligatorio = true
		raiz.add_child(bus)
		var correcto := comprobar(bus)
		bus.free()
		if not correcto:
			printerr("Vestidor: ", nombre)
			return false
	var libre := Bus.instantiate()
	libre.archivo = "escenarios/faros.json"
	raiz.add_child(libre)
	var sin_epp: bool = libre.vestidor == null and not libre.motor.epp_pendiente()
	libre.free()
	return sin_epp


static func comprobar(bus: Node3D) -> bool:
	if not bus.motor.epp_pendiente() or bus.vestidor.visible:
		return false
	bus.flashcard.confirmar()
	if not bus.vestidor.visible:
		printerr("El vestidor debe abrir tras la orden")
		return false
	var exigidos := Epp.requeridos(bus.datos)
	if bus.vestidor.botones.size() != exigidos.size() + 3:
		printerr("Botones: ", bus.vestidor.botones.size())
		return false
	bus.vestidor.confirmar()
	if not bus.vestidor.visible or not bus.vestidor.aviso.visible or not bus.motor.epp_pendiente():
		printerr("Sin elegir nada no debe dejar pasar")
		return false
	var primera: String = bus.datos.ruta_ideal[0]
	bus.ejecutar(primera, "teclado")
	if bus.motor.acciones_acertadas().size() != 0:
		printerr("Los pasos deben seguir bloqueados")
		return false
	for id in exigidos:
		bus.vestidor.botones[id].button_pressed = true
	bus.vestidor.confirmar()
	return not bus.vestidor.visible and not bus.motor.epp_pendiente()
