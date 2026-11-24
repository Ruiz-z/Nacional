extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
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
			or lectura.aviso != "Banco desconectado · falla virtual":
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
	bus.ejecutar("reportar_tp1_0", "teclado")
	bus.ejecutar("reportar_tp2_5", "teclado")
	bus.ejecutar("diagnosticar_alimentacion", "teclado")
	if not bus.lateral.get_node("Siguiente").text.ends_with("cierra el conductor abierto en el banco físico."):
		return false
	bus.ejecutar("reconectar", "virtual")
	if not bus.flashcard.visible or not bus.motor.fin().is_empty() \
			or not bus.motor.mediciones.error_diagnostico.is_empty():
		return false
	bus.flashcard.ok.pressed.emit()
	bus.abrir_menu(bus.zona_activa.piezas.multimetro)
	bus.elegir_accion(bus.menu_pieza.entradas.size() - 1, "teclado")
	if bus.accion_pendiente != "reconectar":
		return false
	bus.recibir_banco(lineas[3], ahora)
	if bus.motor.fin() != "resuelto" or bus.motor.puntaje() != 100 \
			or not bus.accion_pendiente.is_empty():
		return false
	var hud: Label = bus.lateral.get_node("Indicios")
	if hud.text != "\n".join(["[x] TP1 medido", "[x] TP2 medido",
			"[x] Lectura de TP1 reportada", "[x] Lectura de TP2 reportada",
			"[x] Diagnóstico registrado", "[x] Falla resuelta"]):
		return false
	var decisiones: Array = bus.motor.resumen().linea_tiempo
	if decisiones.back().fuente_entrada != "banco" or decisiones.back().fuente_falla != "banco" \
			or decisiones[0].get("lectura-reportada") != "≈0 V":
		return false
	bus.reintentar()
	bus.fuente_banco.conexion.iniciar_fisica(ahora - 3000)
	bus._process(0.0)
	return bus.zona_activa.estado_banco.text.contains("Banco desconectado · falla virtual") \
		and bus.motor.mediciones.fuente == "virtual" and bus.motor.estado().s2_abierto \
		and not bus.pausa_visible and bus.motor.fin().is_empty()
