extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Clic = preload("res://tests/test_zonas_flujo.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/motor.json"
	visor.add_child(bus)
	var correcto := await comprobar(bus, arbol)
	visor.free()
	return correcto


static func comprobar(bus: Node3D, arbol: SceneTree) -> bool:
	var visor := bus.get_viewport()
	var tarjeta: CanvasLayer = bus.flashcard
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var modo_previo := Input.mouse_mode
	var reloj: int = bus.ultimo_ms
	bus.avisar("Primera", "exito")
	bus.avisar("Segunda", "error")
	bus.avisar("Primera", "exito")
	bus.avisar("Tercera", "aviso")
	bus.avisar("Segunda", "error")
	if bus.jugador.activo or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE \
			or visor.gui_get_focus_owner() != tarjeta.ok or tarjeta.contador.text != "1 de 3":
		return false
	var estado: Dictionary = bus.motor.estado()
	bus.ejecutar("inspeccionar", "teclado")
	bus.recibir_accion({"accion": "inspeccionar", "fuente_entrada": "control", "valor": 1})
	await arbol.process_frame
	await arbol.process_frame
	var boton: CheckButton = bus.panel.get_node("Bloqueo")
	Clic.clic(visor, boton.get_global_rect().get_center())
	Clic.clic(visor, Vector2(20, 500))
	if bus.motor.estado() != estado or bus.menu_pieza.visible or boton.button_pressed or not tarjeta.visible:
		return false

	var escala := Engine.time_scale
	Engine.time_scale = 10.0
	await arbol.create_timer(10.1).timeout
	Engine.time_scale = escala
	if not tarjeta.visible or tarjeta.cuerpo.text != "Primera" or tarjeta.chip.text != "BIEN HECHO" or bus.ultimo_ms != reloj:
		return false
	Clic.clic(visor, tarjeta.ok.get_global_rect().get_center())
	if tarjeta.cuerpo.text != "Segunda" or tarjeta.contador.text != "2 de 3" or bus.jugador.activo:
		return false
	pulsar_tecla(visor, KEY_ENTER)
	if tarjeta.cuerpo.text != "Tercera" or tarjeta.contador.text != "3 de 3":
		return false
	pulsar_tecla(visor, KEY_SPACE)
	if tarjeta.visible or not bus.jugador.activo or Input.mouse_mode != modo_previo \
			or bus.ultimo_ms <= reloj:
		printerr("Estado al cerrar: ", tarjeta.visible, " ", bus.jugador.activo, " ", Input.mouse_mode, " ", bus.ultimo_ms - reloj, " previo ", bus.raton_antes_flashcard)
		return false

	bus.abrir_menu(bus.zona_activa.piezas[bus.zona_activa.acceso])
	var foco := visor.gui_get_focus_owner()
	bus.avisar("Control", "exito")
	pulsar_control(visor, JOY_BUTTON_A)
	if tarjeta.visible or not bus.menu_pieza.visible or bus.jugador.activo \
			or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE or visor.gui_get_focus_owner() != foco:
		return false
	bus.avisar("Cancelar con teclado", "aviso")
	pulsar_tecla(visor, KEY_ESCAPE)
	if tarjeta.visible or not bus.menu_pieza.visible:
		return false
	bus.avisar("Cancelar con control", "aviso")
	pulsar_control(visor, JOY_BUTTON_B)
	if tarjeta.visible or not bus.menu_pieza.visible:
		return false
	bus.cerrar_menu()
	bus.avisar("Siguiente paso confirmado", "exito")
	pulsar_tecla(visor, KEY_ENTER)
	if tarjeta.visible:
		return false
	bus.avisar_temporal("Tapa cerrada")
	if not bus.resultado.visible or bus.duracion_aviso.wait_time < 3.0:
		return false
	await arbol.create_timer(2.8).timeout
	if not bus.resultado.visible:
		return false
	await bus.duracion_aviso.timeout
	await arbol.process_frame
	return not bus.resultado.visible


static func pulsar_tecla(visor: Viewport, tecla: Key) -> void:
	var evento := InputEventKey.new()
	evento.keycode = tecla
	evento.pressed = true
	visor.push_input(evento, true)


static func pulsar_control(visor: Viewport, boton: JoyButton) -> void:
	var evento := InputEventJoypadButton.new()
	evento.button_index = boton
	evento.pressed = true
	visor.push_input(evento, true)
