extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Fuente = preload("res://logica/simulador/fuente_banco.gd")
const Protocolo = preload("res://logica/entrada/protocolo.gd")
const LATIDO := '{"v":1,"ctrl":"hb"}'


static func ejecutar() -> bool:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var salida: Array = []
	var args := ["--headless", "--no-header", "-s", raiz.path_join("tools/emisor_eventos.gd"), "--", "--banco"]
	if OS.execute(OS.get_executable_path(), args, salida, true) != 0 or salida.is_empty():
		return false
	var lineas := str(salida[0]).split("\n", false)
	if lineas.size() != 4 or not protocolo_y_respaldo(lineas):
		return false
	var arbol := Engine.get_main_loop() as SceneTree
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/modulo_auxiliar.json"
	arbol.root.add_child(bus)
	bus.flashcard.confirmar()
	var correcto := practicar(bus, lineas)
	bus.free()
	return correcto


static func protocolo_y_respaldo(lineas: PackedStringArray) -> bool:
	var parser := Protocolo.new()
	var alto_p := '{"v":1,"ctrl":"nodo_p","valor":1,"n":0,"t":0}'
	var bajo_q := '{"v":1,"ctrl":"nodo_q","valor":0,"n":1,"t":40}'
	if parser.recibir(alto_p, "panel") != {} or parser.recibir(alto_p, "banco").get("n") != 0:
		return false
	if parser.recibir(bajo_q, "banco").get("fuente_entrada") != "banco" \
			or parser.recibir(alto_p, "banco") != {}:
		return false
	var fuente := Fuente.new()
	var variante := {"s1_abierto": false, "s2_abierto": true}
	for linea in [lineas[1], lineas[2], lineas[0]]:
		fuente.recibir(linea, 0)
	if fuente.estado_interruptores() != {"s1_abierto": true, "s2_abierto": false}:
		return false
	for invalida in ["{", alto_p, bajo_q.replace('"valor":0', '"valor":3'), LATIDO.replace('"v":1', '"v":2')]:
		if fuente.recibir(invalida, 2900) != {}:
			return false
	if fuente.recibir(lineas[3].replace("1100", "1049"), 2900) != {} \
			or fuente.estado_interruptores() != {"s1_abierto": true, "s2_abierto": false}:
		return false
	fuente.recibir(LATIDO, 2999)
	fuente.actualizar(5998)
	if fuente.fuente() != "banco":
		return false
	fuente.actualizar(5999)
	var lectura := fuente.leer(variante)
	if fuente.fuente() != "virtual" or fuente.conexion.pausado() or lectura.tp2 != 0.0 \
			or lectura.aviso != "Se desconectó el banco físico. Sigue con el banco en pantalla.":
		return false
	fuente.recibir(LATIDO, 6000)
	fuente.recibir(alto_p, 6000)
	fuente.recibir(bajo_q, 6000)
	if fuente.estado_interruptores() != {"s1_abierto": false, "s2_abierto": true}:
		return false
	var cierre := fuente.recibir('{"v":1,"ctrl":"nodo_q","valor":1,"n":2,"t":90}', 6050)
	if cierre.get("tp1") != 5.0 or cierre.get("tp2") != 0.0:
		return false
	fuente.desconectar()
	return fuente.fuente() == "virtual" and not fuente.conexion.pausado()


static func practicar(bus: Node3D, lineas: PackedStringArray) -> bool:
	var ahora := Time.get_ticks_msec()
	for linea in lineas.slice(0, 3):
		bus.recibir_banco(linea, ahora)
	if not bus.zona_activa.estado_banco.text.contains("Fuente: banco físico"):
		return false
	bus.abrir_menu(bus.zona_activa.piezas.hoja_diagnostico)
	for numero in [1, 5]:
		Taller.tecla(bus, numero)
	for boton in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_A]:
		var evento := InputEventJoypadButton.new()
		evento.pressed = true
		evento.button_index = boton
		bus.get_viewport().push_input(evento, true)
	Taller.mostrar_siguiente_mision(bus)
	if not bus.hud_mision.ayuda.text.ends_with("Cierra el conductor abierto en el banco físico."):
		return false
	if not Taller.equipar(bus, "reconectar"):
		return false
	bus.ejecutar("reconectar", "virtual")
	if not bus.flashcard.visible or not bus.motor.fin().is_empty() \
			or bus.motor.mediciones.reportadas != {"tp1": "0", "tp2": "5"}:
		return false
	bus.flashcard.ok.pressed.emit()
	bus.abrir_menu(bus.zona_activa.piezas.conductor_banco)
	bus.elegir_accion(bus.menu_pieza.entradas.size() - 1, "teclado")
	if bus.accion_pendiente != "reconectar":
		return false
	bus.recibir_banco(lineas[3], ahora)
	if bus.motor.fin() != "resuelto" or bus.motor.puntaje() != 100 \
			or not bus.accion_pendiente.is_empty():
		return false
	var progreso: Dictionary = bus.progreso_indicios(bus.motor.estado())
	if not bus.misiones.all(func(mision: Dictionary): return Escenario.mision_cumplida(mision, progreso)):
		return false
	var decisiones: Array = bus.motor.resumen().linea_tiempo
	if decisiones.back().fuente_entrada != "banco" or decisiones.back().fuente_falla != "banco" \
			or decisiones[0].get("lectura-reportada") != "≈0 V":
		return false
	if not Taller.cerrar_orden(bus):
		return false
	bus.reintentar()
	bus.flashcard.confirmar()
	bus.fuente_banco.conexion.iniciar_fisica(ahora - 3000)
	bus._process(0.0)
	return bus.zona_activa.estado_banco.text.contains("Se desconectó el banco físico. Sigue con el banco en pantalla.") \
		and bus.motor.mediciones.fuente == "virtual" and bus.motor.estado().s2_abierto \
		and not bus.pausa_visible and bus.motor.fin().is_empty()
