extends RefCounted

const Inventario = preload("res://logica/simulador/inventario.gd")


static func elegir(bus: Node3D, id: String, objeto := "") -> bool:
	var indice: int = bus.menu_pieza.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.id == id and (objeto.is_empty() or entrada.get("objeto") == objeto))
	if not bus.menu_pieza.visible or indice < 0:
		return false
	bus.menu_pieza.botones[indice].pressed.emit()
	return true


static func tecla(bus: Node3D, numero: int) -> void:
	var evento := InputEventKey.new()
	evento.keycode = KEY_1 + numero - 1
	evento.pressed = true
	bus.get_viewport().push_input(evento, true)


static func equipar(bus: Node3D, accion: String) -> bool:
	var requiere: Dictionary = bus.requisitos(accion)
	var herramienta: String = requiere.get("herramienta", "")
	var necesarios: Array = requiere.get("piezas", []).duplicate()
	if not herramienta.is_empty():
		necesarios.push_front(herramienta)
	var taller: Node3D = bus.taller
	var almacen: Array[String] = taller.inventario.cinturon
	taller.cambiar_cajones(true, true)
	for id in necesarios:
		if id in taller.inventario.accesibles(bus.carrito_cerca()):
			continue
		while Inventario.espacio(almacen) + Inventario.CATALOGO[id].espacio > Inventario.CAPACIDAD:
			var sobra := almacen.find_custom(func(objeto: String) -> bool: return objeto not in necesarios)
			if sobra < 0:
				return false
			var objeto := almacen[sobra]
			tecla(bus, taller.espacio_de(objeto))
			var mueble: StaticBody3D = taller.caja_roja.piezas.caja_taller 				if Inventario.CATALOGO[objeto].tipo == "herramienta" else taller.mesa.piezas.mesa_taller
			bus.abrir_menu(mueble)
			if not elegir(bus, "dejar") or objeto in almacen:
				return false
		bus.abrir_menu(taller.objetos[id])
		if not elegir(bus, "tomar") or id not in taller.inventario.accesibles(bus.carrito_cerca()):
			return false
	if not herramienta.is_empty():
		tecla(bus, taller.espacio_de(herramienta))
	return herramienta.is_empty() or taller.mano == herramienta


static func cerrar_orden(bus: Node3D, numero := 1) -> bool:
	if not bus.flashcard.visible or bus.flashcard.opciones.is_empty():
		return false
	tecla(bus, numero)
	if not bus.flashcard.opciones.is_empty():
		return false
	bus.flashcard.confirmar()
	return bus.resumen.visible
