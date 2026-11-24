extends RefCounted


static func elegir(bus: Node3D, id: String) -> bool:
	var indice: int = bus.menu_pieza.entradas.find_custom(
		func(entrada: Dictionary) -> bool: return entrada.id == id)
	if not bus.menu_pieza.visible or indice < 0:
		return false
	bus.menu_pieza.botones[indice].pressed.emit()
	return true


static func equipar(bus: Node3D, accion: String) -> bool:
	var faltantes: Array = bus.taller.inventario.faltantes(bus.requisitos(accion), bus.carrito_cerca())
	if faltantes.is_empty():
		return true
	bus.taller.cambiar_cajones(true, true)
	for id in faltantes:
		bus.abrir_menu(bus.taller.objetos[id])
		if not elegir(bus, "tomar") or id not in bus.taller.inventario.accesibles(bus.carrito_cerca()):
			return false
	return true
