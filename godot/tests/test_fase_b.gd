extends RefCounted

const Taller = preload("res://tests/acciones_taller.gd")

const Bus = preload("res://escenas/bus.tscn")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Elevador = preload("res://escenas/elevador.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const ORDENES := {"neumatico_pinchado": "FG7", "tuercas_rueda_flojas": "FG7",
	"fuga_suspension_neumatica": "FG7", "amortiguador_danado": "FG7", "freno_desgastado": "FG5"}


static func ejecutar() -> bool:
	for id in ORDENES:
		if not ruta_ideal(id):
			printerr("Ruta ideal de bajos: ", id)
			return false
	var arbol := Engine.get_main_loop() as SceneTree
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/neumatico_pinchado.json"
	arbol.root.add_child(bus)
	bus.jugador.set_physics_process(false)
	var correcto := await procedimiento(arbol, bus)
	bus.free()
	return correcto


static func ruta_ideal(id: String) -> bool:
	var carga := Escenario.cargar("escenarios/%s.json" % id)
	if not carga.errores.is_empty():
		return false
	var datos: Dictionary = carga.escenario
	if datos.grupo_funcion != ORDENES[id] or datos.zona != "bajos":
		return false
	var raiz := (Engine.get_main_loop() as SceneTree).root
	for variante in [false, true]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/%s.json" % id
		raiz.add_child(bus)
		var pasos: String = bus.lateral.get_node("Indicios").text
		var marca: Label = bus.lateral.get_node("Marca")
		if not pasos.ends_with("[ ] Cerrar la orden") or "Ejemplo didáctico" in pasos \
				or not marca.visible or marca.text != "Ejemplo didáctico":
			bus.free()
			return false
		if variante:
			var adaptado := datos.duplicate(true)
			adaptado.estado.merge(datos.variante.estado, true)
			bus.motor = Motor.new(adaptado)
		var correcto := recorrer_ideal(bus, datos)
		bus.free()
		if not correcto:
			return false
	return true


static func recorrer_ideal(bus: Node3D, datos: Dictionary) -> bool:
	var elevador: Node3D = bus.get_node("Elevador")
	if not Taller.equipar(bus, "colocar_calzas") 			or not elegir(bus, elevador.piezas[Elevador.CALZAS], "colocar_calzas"):
		return false
	elevador.mover(true, true)
	if not Taller.equipar(bus, "trabar_soporte"):
		return false
	for soporte in elevador.trabas:
		if not elegir(bus, elevador.piezas[soporte], "trabar_soporte"):
			return false
	bus.panel.get_node("Torque").value = 50
	for accion in datos.ruta_ideal:
		if accion == "cerrar_orden":
			if not Taller.equipar(bus, "destrabar_soporte"):
				return false
			for soporte in elevador.trabas:
				if not elegir(bus, elevador.piezas[soporte], "destrabar_soporte"):
					return false
			elevador.mover(false, true)
		if not Taller.equipar(bus, accion):
			return false
		var regla: Dictionary = datos.acciones[accion]
		bus.ejecutar(accion, "virtual" if regla.requiere_panel else "teclado")
		for pieza in regla.get("requiere", {}).get("piezas", []):
			if pieza in bus.taller.inventario.accesibles():
				return false
		if bus.motor.puntaje() != 100:
			return false
	return bus.motor.fin() == "resuelto" and Taller.cerrar_orden(bus)


static func procedimiento(arbol: SceneTree, bus: Node3D) -> bool:
	var elevador: Node3D = bus.get_node("Elevador")
	var bajos: Node3D = bus.get_node("Bajos")
	var consola: StaticBody3D = elevador.piezas[Elevador.CONSOLA]
	var rueda: StaticBody3D = bajos.piezas.neumatico_delantero_derecho
	var decisiones: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary) -> void: decisiones.append(decision))
	if not comprobar_guia(bus, "calzas"):
		return false
	bus.taller.apagar_guia()
	for pieza in bajos.piezas.values():
		if pieza.collision_layer != 0:
			return false
	bus.abrir_menu(rueda)
	if bus.menu_pieza.visible or not elegir(bus, consola, "elevar_bus") \
			or elevador.en_movimiento() or not bus.flashcard.visible or bus.taller.baliza.visible:
		return false
	bus.flashcard.ok.pressed.emit()
	if bus.taller.objetivo != "calzas":
		return false
	bus.taller.cambiar_cajones(true, true)
	if not elegir(bus, bus.taller.objetos.calzas, "tomar"):
		return false
	if not comprobar_guia(bus, Elevador.CALZAS, true):
		return false
	if not elegir(bus, elevador.piezas[Elevador.CALZAS], "colocar_calzas") or not elevador.calzas_colocadas:
		return false
	if not comprobar_guia(bus, Elevador.CONSOLA):
		return false
	bus.jugador.ubicar(Vector3.ZERO)
	if not elegir(bus, consola, "elevar_bus") or elevador.en_movimiento():
		return false
	bus.flashcard.ok.pressed.emit()
	bus.jugador.ubicar(Vector3(-4, 0, 0))
	if not await mover(bus, consola, elevador, "elevar_bus"):
		return false
	if not elevador.arriba or elevador.seguro() or rueda.collision_layer != 2:
		return false
	for i in range(elevador.carga.size()):
		if not elevador.carga[i].position.is_equal_approx(elevador.bases[i] + Vector3.UP * Elevador.ALTURA):
			return false
	# La cápsula cruza el casco elevado y conserva el contacto con el suelo del taller.
	bus.jugador.ubicar(Vector3(-1.7, 0.02, 0))
	await arbol.physics_frame
	await arbol.physics_frame
	if bus.jugador.move_and_collide(Vector3(3.4, 0, 0)) != null \
			or bus.jugador.move_and_collide(Vector3.DOWN * 0.10) == null:
		return false
	bus.jugador.ubicar(Vector3(0.2, 0, 2.3))
	await arbol.physics_frame
	bus.apuntar_jugador(rueda.global_position + Vector3(0, 0, -0.35))
	bus.alcance.force_raycast_update()
	if bus.alcance.get_collider() != rueda:
		return false
	if not elegir(bus, rueda, "medir_presion") or bus.motor.fin() != "falta-critica" or decisiones.size() != 1:
		return false
	var falta: Dictionary = bus.motor.faltas()[0]
	if falta.tipo_error != "accion-insegura" or falta.criticidad != "critica" \
			or falta.fuente != Motor.FUENTE_ELEVADOR or not falta.motivo.contains("soportes"):
		return false
	if not bus.flashcard.visible or bus.flashcard.titulo.text != "Falta crítica" \
			or bus.flashcard.fuente.text != "Fuente: ejemplo didáctico, sin fuente oficial" or bus.resumen.visible:
		return false
	bus.flashcard.ok.pressed.emit()
	if not bus.resumen.visible or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return false
	bus.reintentar()
	decisiones.clear()
	if elevador.arriba or elevador.calzas_colocadas or rueda.collision_layer != 0 \
			or not bus.taller.inventario.accesibles().is_empty():
		return false
	bus.taller.tomar("calzas", false)
	if not await mover(bus, consola, elevador, "elevar_bus"):
		return false
	if not Taller.equipar(bus, "trabar_soporte"):
		return false
	for soporte in elevador.trabas:
		if not comprobar_guia(bus, soporte) or not elegir(bus, elevador.piezas[soporte], "trabar_soporte"):
			return false
	if not elevador.seguro() or not decisiones.is_empty() or bus.motor.puntaje() != 100:
		return false
	if not elegir(bus, rueda, "medir_presion") or not decisiones.is_empty() or not bus.flashcard.visible:
		return false
	bus.flashcard.ok.pressed.emit()
	if bus.taller.objetivo != "manometro":
		return false
	bus.taller.tomar("manometro", false)
	if not elegir(bus, rueda, "medir_presion") or not Taller.equipar(bus, "localizar_pinchazo") \
			or not elegir(bus, rueda, "localizar_pinchazo"):
		return false
	bus.taller.dejar("manometro", false)
	if not Taller.equipar(bus, "cambiar_rueda"):
		return false
	if not elegir(bus, rueda, "cambiar_rueda") or bus.accion_pendiente != "cambiar_rueda":
		return false
	bus.panel.get_node("Confirmar").pressed.emit()
	var primer_envio := Time.get_ticks_msec()
	Taller.cerrar_exitos(bus)
	if "neumatico" in bus.taller.inventario.accesibles():
		return false
	bus.taller.tomar("llave_torque", false)
	var tuerca: StaticBody3D = bajos.piezas.tuerca_delantero_derecho_1
	if not elegir(bus, tuerca, "apretar_tuerca_1"):
		return false
	bus.flashcard.ok.pressed.emit()
	bus.panel.get_node("Torque").value = 85
	bus.panel.get_node("AplicarTorque").pressed.emit()
	var primer_torque := Time.get_ticks_msec()
	if decisiones[-1].tipo_error != "valor-fuera-de-rango" or decisiones[-1].torque_simulado != 85 \
			or not bus.motor.hay_problemas() or bus.motor.estado().apretar_tuerca_1:
		return false
	if not bus.flashcard.visible or bus.flashcard.titulo.text != "Valor fuera de rango":
		return false
	bus.flashcard.ok.pressed.emit()
	if not Taller.equipar(bus, "reponer_tuerca_1"):
		return false
	if not elegir(bus, tuerca, "reponer_tuerca_1"):
		return false
	while Time.get_ticks_msec() - primer_envio < 60:
		await arbol.process_frame
	bus.panel.get_node("Confirmar").pressed.emit()
	if bus.motor.hay_problemas() or not Taller.equipar(bus, "apretar_tuerca_1") \
			or not elegir(bus, tuerca, "apretar_tuerca_1"):
		return false
	while Time.get_ticks_msec() - primer_torque < 60:
		await arbol.process_frame
	bus.flashcard.ok.pressed.emit()
	bus.panel.get_node("Torque").value = 50
	bus.panel.get_node("AplicarTorque").pressed.emit()
	if not decisiones[-1].tipo_error.is_empty() or not bus.motor.estado().apretar_tuerca_1:
		return false
	for numero in [3, 5, 2, 4]:
		Taller.cerrar_exitos(bus)
		var id := "apretar_tuerca_%d" % numero
		if not elegir(bus, bajos.piezas["tuerca_delantero_derecho_%d" % numero], id):
			return false
		bus.flashcard.ok.pressed.emit()
		bus.recibir_accion({"accion": "confirmar", "fuente_entrada": "virtual", "valor": 1})
		if not bus.motor.estado()[id]:
			return false
	Taller.cerrar_exitos(bus)
	if not elegir(bus, consola, "descender_bus") or elevador.en_movimiento():
		return false
	bus.flashcard.ok.pressed.emit()
	if not Taller.equipar(bus, "destrabar_soporte"):
		return false
	for soporte in elevador.trabas:
		if not comprobar_guia(bus, soporte) or not elegir(bus, elevador.piezas[soporte], "destrabar_soporte"):
			return false
	if not comprobar_guia(bus, Elevador.CONSOLA):
		return false
	bus.jugador.ubicar(Vector3.ZERO)
	Taller.cerrar_exitos(bus)
	if not elegir(bus, consola, "descender_bus") or elevador.en_movimiento():
		return false
	bus.jugador.ubicar(Vector3(-4, 0, 0))
	bus.flashcard.ok.pressed.emit()
	if not await mover(bus, consola, elevador, "descender_bus"):
		return false
	if not bus.flashcard.visible or bus.taller.baliza.visible \
			or bus.flashcard.chip.text != "BIEN HECHO" \
			or bus.flashcard.cuerpo.text != "Solo falta cerrar la orden. Hazlo en la consola del elevador.":
		return false
	bus.flashcard.ok.pressed.emit()
	if bus.taller.objetivo != Elevador.CONSOLA or not comprobar_guia(bus, Elevador.CONSOLA, true) \
			or not bus.lateral.get_node("Siguiente").text.ends_with("Hazlo en la consola del elevador."):
		return false
	await arbol.physics_frame
	await arbol.physics_frame
	bus.jugador.ubicar(Vector3(-1.7, 0.02, 0))
	if bus.jugador.move_and_collide(Vector3(3.4, 0, 0)) == null:
		return false
	for pieza in bajos.piezas.values():
		if pieza.collision_layer != 0:
			return false
	bus.jugador.ubicar(Vector3(-4, 0, 0))
	return not elevador.arriba and decisiones.size() == 10 \
		and elegir(bus, consola, "cerrar_orden") and bus.motor.fin() == "resuelto"


static func elegir(bus: Node3D, pieza: StaticBody3D, id: String) -> bool:
	bus.abrir_menu(pieza)
	for i in range(bus.menu_pieza.entradas.size()):
		if bus.menu_pieza.entradas[i].id == id:
			bus.menu_pieza.botones[i].pressed.emit()
			return true
	return false


static func mover(bus: Node3D, consola: StaticBody3D, elevador: Node3D, id: String) -> bool:
	if not elegir(bus, consola, id) or not elevador.en_movimiento():
		return false
	await elevador.recorrido.finished
	return true


static func comprobar_guia(bus: Node3D, objetivo: String, control := false) -> bool:
	if control:
		var evento := InputEventJoypadButton.new()
		evento.button_index = JOY_BUTTON_Y
		evento.pressed = true
		bus.get_viewport().push_input(evento, true)
	else:
		var evento := InputEventKey.new()
		evento.keycode = KEY_G
		evento.pressed = true
		bus.get_viewport().push_input(evento, true)
	var elevador := bus.get_node("Elevador")
	return bus.taller.baliza.visible and bus.taller.objetivo == objetivo \
		and (not elevador.piezas.has(objetivo) or bus.taller.pieza_guia == elevador.piezas[objetivo])
