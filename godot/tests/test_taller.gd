extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Clic = preload("res://tests/test_zonas_flujo.gd")
const Acciones = preload("res://tests/acciones_taller.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Inventario = preload("res://logica/simulador/inventario.gd")
const Rutas = preload("res://logica/rutas_contenido.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/faros.json"
	bus.modo_captura = true
	visor.add_child(bus)
	bus.jugador.set_physics_process(false)
	var fallo := await comprobar(bus, arbol)
	visor.free()
	if not fallo.is_empty():
		printerr(fallo)
		return false
	return probar_motor(arbol)


static func comprobar(bus: Node3D, arbol: SceneTree) -> String:
	var taller: Node3D = bus.taller
	if not verificar_catalogo(taller):
		return "Hay un requisito sin objeto en el taller o con un catálogo inválido."
	await arbol.physics_frame
	var eventos: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary): eventos.append(decision))
	var caja: StaticBody3D = taller.caja_roja.piezas.caja_taller
	if not apuntar(bus, caja) or not await elegir(bus, "cajones", arbol):
		return "La caja roja no abrió desde el menú."
	await taller.animacion.finished
	await arbol.physics_frame
	for id in taller.objetos:
		if not apuntar(bus, taller.objetos[id]):
			return "No se puede apuntar a %s desde el pasillo. La mira alcanza %s." % [
				id, bus.alcance.get_collider().get("componente") if bus.alcance.is_colliding() else null]
	var foco: StaticBody3D = taller.objetos.foco
	var destornillador: StaticBody3D = taller.objetos.destornillador
	if not apuntar(bus, destornillador) or not await elegir(bus, "tomar", arbol):
		return "No se puede tomar el destornillador por el menú."
	if not eventos.is_empty() or taller.mano != "destornillador" or bus.jugador.id_mano != "destornillador":
		return "Tomar alteró las decisiones o no seleccionó la herramienta."
	var faro: StaticBody3D = bus.zona_activa.piezas.faro_izquierdo
	bus.ejecutar("inspeccionar", "teclado")
	bus.ejecutar("medir_continuidad", "teclado")
	bus.mostrar_estado(true)
	var puntaje: int = bus.motor.puntaje()
	bus.abrir_menu(faro)
	if not await elegir(bus, "cambiar_foco_correcto", arbol):
		return "Falta la opción de cambiar el foco."
	if bus.accion_pendiente != "" or eventos.size() != 2 or bus.motor.puntaje() != puntaje \
			or not bus.resultado.visible or not bus.resultado.text.begins_with("Necesitas: Foco de repuesto") \
			or not bus.resultado.text.contains("estantería de piezas"):
		return "El rechazo por inventario no explicó el faltante o afectó la orden."
	if taller.objetivo != "foco" or not taller.baliza.visible \
			or not is_equal_approx(taller.baliza.global_position.x, taller.estanteria.global_position.x):
		return "La guía del foco no apunta a la estantería."
	taller.caducidad.timeout.emit()
	if taller.baliza.visible or not taller.objetivo.is_empty():
		return "La baliza no se apagó al vencer."
	var guia := InputEventKey.new()
	guia.keycode = KEY_G
	guia.pressed = true
	bus._input(guia)
	if taller.objetivo != "foco" or taller.caducidad.wait_time != 30.0:
		return "G no volvió a emitir la guía."
	bus.jugador.camara.rotate_y(PI)
	await arbol.process_frame
	await arbol.process_frame
	if not taller.flecha.visible:
		return "La guía no muestra la flecha fuera de cuadro."
	if not apuntar(bus, foco) or not await elegir(bus, "tomar", arbol) or taller.baliza.visible:
		return "Tomar el foco no apagó la baliza."
	var elegir_mano := InputEventJoypadButton.new()
	elegir_mano.button_index = JOY_BUTTON_LEFT_SHOULDER
	elegir_mano.pressed = true
	bus._input(elegir_mano)
	if taller.mano != "destornillador":
		return "L no seleccionó el objeto anterior."
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_DOWN
	rueda.pressed = true
	bus._input(rueda)
	if taller.mano != "foco" or not taller.hud.text.contains("Cinturón 2/4"):
		return "La rueda no seleccionó el foco o el HUD mostró una carga incorrecta."
	var mesa: StaticBody3D = taller.mesa.piezas.mesa_taller
	if not apuntar(bus, mesa) or not await elegir(bus, "dejar", arbol):
		return "No se pudo dejar el foco en la mesa."
	await arbol.physics_frame
	if foco.zona != taller.mesa or not apuntar(bus, foco) or not await elegir(bus, "tomar", arbol):
		return "No se pudo volver a tomar el foco de la mesa."
	bus.abrir_menu(faro)
	if not await elegir(bus, "cambiar_foco_correcto", arbol) or bus.accion_pendiente != "cambiar_foco_correcto":
		return "La acción equipada no pidió confirmación."
	bus.panel.emitir("confirmar", 1)
	if not bus.motor.estado().foco_repuesto or eventos.size() != 3 \
			or "foco" in taller.inventario.cinturon or "destornillador" not in taller.inventario.cinturon \
			or foco.zona != taller.estanteria:
		return "El panel no consumió la pieza y conservó la herramienta."
	return ""


static func apuntar(bus: Node3D, pieza: StaticBody3D) -> bool:
	var taller: Node3D = bus.taller
	var frente := Vector3.BACK.rotated(Vector3.UP, pieza.zona.rotation.y)
	var distancia := 1.20
	if pieza.zona == taller.caja_roja and pieza.componente != "caja_taller":
		distancia = 0.48
	var origen := pieza.global_position + frente * distancia
	bus.jugador.ubicar(Vector3(origen.x, 0, origen.z))
	bus.apuntar_jugador(pieza.global_position)
	bus.alcance.force_raycast_update()
	return bus.alcance.get_collider() == pieza


static func elegir(bus: Node3D, id: String, arbol: SceneTree) -> bool:
	if not bus.menu_pieza.visible:
		bus.recibir_accion(bus.panel.entrada.traducir("teclado", "clic", 1))
	var indice: int = bus.menu_pieza.entradas.find_custom(func(entrada: Dictionary) -> bool:
		return entrada.id == id)
	if not bus.menu_pieza.visible or indice < 0:
		return false
	await arbol.process_frame
	await arbol.process_frame
	var boton: Button = bus.menu_pieza.botones[indice]
	Clic.clic(bus.get_viewport(), boton.get_global_rect().get_center())
	return true


static func verificar_catalogo(taller: Node3D) -> bool:
	if taller.objetos.size() != Inventario.CATALOGO.size():
		return false
	var carro: Vector3 = taller.carrito.global_position
	if taller.cerca(carro + Vector3.RIGHT * 3.0) or not taller.cerca(carro + Vector3.RIGHT * 2.99):
		return false
	for archivo in DirAccess.get_files_at(Rutas.resolver("escenarios", true)):
		if not archivo.ends_with(".json"):
			continue
		var ruta := "escenarios/" + archivo
		var carga := Escenario.cargar(ruta)
		if not carga.errores.is_empty():
			return false
		var datos: Dictionary = carga.escenario
		for grupo in ["acciones", "recuperaciones"]:
			for id in datos[grupo]:
				var requiere: Dictionary = datos[grupo][id].get("requiere", {})
				for tipo in requiere:
					for objeto in requiere[tipo]:
						if Inventario.objeto(objeto).is_empty() or not taller.objetos.has(objeto) \
								or not taller.ubicaciones.has(taller.objetos[objeto].zona):
							return false
	var alterado: Dictionary = Escenario.cargar("escenarios/faros.json").escenario
	for requiere in [[], {"piezas": ["multimetro"]}, {"piezas": ["desconocido"]},
			{"herramientas": ["destornillador", "destornillador"]}]:
		alterado.acciones.cambiar_foco_correcto.requiere = requiere
		if Escenario.campo_invalido(alterado) != "acciones.cambiar_foco_correcto.requiere":
			return false
	return true


static func probar_motor(arbol: SceneTree) -> bool:
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/motor.json"
	arbol.root.add_child(bus)
	var correcto := ruta_motor(bus)
	bus.free()
	return correcto


static func ruta_motor(bus: Node3D) -> bool:
	if not Acciones.equipar(bus, "ajustar_abrazadera"):
		return false
	var abrazadera: StaticBody3D = bus.taller.objetos.abrazadera
	bus.ejecutar("ajustar_abrazadera", "virtual")
	if abrazadera.visible or "abrazadera" not in bus.taller.inventario.cinturon:
		return false
	bus.panel.get_node("Bloqueo").button_pressed = true
	bus.panel.get_node("Etiquetado").button_pressed = true
	for id in bus.datos.ruta_ideal:
		if not Acciones.equipar(bus, id):
			return false
		bus.ejecutar(id, "virtual")
	return bus.motor.fin() == "resuelto" and abrazadera.visible \
		and "abrazadera" not in bus.taller.inventario.cinturon \
		and "llave_torque" in bus.taller.inventario.cinturon
