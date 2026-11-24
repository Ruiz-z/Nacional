extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Rutas = preload("res://logica/rutas_contenido.gd")
const Texto = preload("res://logica/texto_limpio.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var cantidad := 0
	for archivo in DirAccess.get_files_at(Rutas.resolver("escenarios", true)):
		if not archivo.ends_with(".json"):
			continue
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/" + archivo
		visor.add_child(bus)
		var correcta := comprobar(bus, visor)
		bus.free()
		if not correcta:
			printerr("Falló la tarjeta de orden de ", archivo)
			visor.free()
			return false
		cantidad += 1
	visor.free()
	return cantidad == 10


static func comprobar(bus: Node3D, visor: SubViewport) -> bool:
	if not coincide(bus) or bus.jugador.activo:
		return false
	var estado: Dictionary = bus.motor.estado()
	var decisiones: Array = []
	bus.decision_tomada.connect(func(decision: Dictionary): decisiones.append(decision))
	bus.ejecutar(bus.datos.ruta_ideal[0], "teclado")
	if not decisiones.is_empty() or bus.motor.estado() != estado:
		return false
	bus.flashcard.confirmar()
	if bus.flashcard.visible or not bus.jugador.activo:
		return false
	var evento := InputEventKey.new()
	evento.keycode = KEY_O
	evento.pressed = true
	visor.push_input(evento, true)
	if not coincide(bus) or bus.jugador.activo:
		return false
	bus.flashcard.confirmar()
	var inicio := InputEventJoypadButton.new()
	inicio.button_index = JOY_BUTTON_START
	inicio.pressed = true
	visor.push_input(inicio, true)
	if not coincide(bus):
		return false
	bus.flashcard.confirmar()
	# Lleva el motor al final para comprobar el reintento de cada orden sin repetir su recorrido.
	bus.motor._fin = "resuelto"
	bus.reintentar()
	return coincide(bus) and not bus.jugador.activo


static func coincide(bus: Node3D) -> bool:
	var tarjeta: CanvasLayer = bus.flashcard
	var briefing: Dictionary = bus.datos.get("briefing", {})
	return Escenario.briefing_valido(briefing) and tarjeta.visible and tarjeta.ok.visible \
		and tarjeta.chip.text == "ORDEN DE TRABAJO" and tarjeta.titulo.text == Texto.limpiar(bus.datos.titulo).texto \
		and tarjeta.get_node("%Sintoma").text == briefing.sintoma \
		and tarjeta.get_node("%Objetivo").text == briefing.objetivo \
		and tarjeta.get_node("%Como").text == "\n".join(briefing.como) \
		and not "[MUESTRA]" in str(briefing)
