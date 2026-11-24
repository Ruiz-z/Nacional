extends RefCounted

const Resumen = preload("res://tests/test_resumen.gd")
const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")
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
	bus.flashcard.confirmar()
	bus.jugador.set_physics_process(false)
	var fallo := await comprobar(bus, arbol)
	visor.free()
	if not fallo.is_empty():
		printerr(fallo)
		return false
	return await probar_carga(arbol) and probar_motor(arbol) and Base.con_base(probar_cierres)


static func probar_carga(arbol: SceneTree) -> bool:
	var tamano := arbol.root.size
	arbol.root.size = Vector2i(1280, 720)
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/fuga_suspension_neumatica.json"
	bus.modo_captura = true
	arbol.root.add_child(bus)
	bus.flashcard.confirmar()
	bus.jugador.set_physics_process(false)
	var fallo := await comprobar_carga(bus, arbol)
	bus.free()
	arbol.root.size = tamano
	if not fallo.is_empty():
		printerr(fallo)
	return fallo.is_empty()


static func comprobar_carga(bus: Node3D, arbol: SceneTree) -> String:
	var taller: Node3D = bus.taller
	var caja: StaticBody3D = taller.pieza_cajon(0)
	var mesa: StaticBody3D = taller.mesa.piezas.mesa_taller
	var carrito: StaticBody3D = taller.carrito.piezas.carrito_taller
	var bolsa: StaticBody3D = taller.objetos.bolsa_aire
	await arbol.physics_frame
	for id in ["calzas", "manometro", "lampara"]:
		var fila: int = taller.fila_cajon(id)
		if fila >= 0 and not await abrir_cajon_con_clic(bus, fila, arbol):
			return "No se abrió el cajón de %s con clic." % id
		if not await usar_menu(bus, taller.objetos[id], "tomar", arbol) or taller.mano != id:
			return "No se tomó %s con clic." % id
	var elevador: Node3D = bus.get_node("Elevador")
	elevador.colocar_calzas()
	elevador.mover(true, true)
	for soporte in elevador.trabas:
		elevador.cambiar_traba(soporte, true)
	var carrito_original: Vector3 = taller.carrito.position
	taller.carrito.position += Vector3.RIGHT * 12
	if not await usar_menu(bus, bolsa, "tomar", arbol):
		return "No se abrió el menú de la bolsa."
	var texto: String = bus.flashcard.cuerpo.text
	if bus.flashcard.titulo.text != "No cabe en el cinturón" \
			or not texto.begins_with("La Bolsa de aire ocupa 2 espacios y en el cinturón te queda 1.") \
			or not texto.contains("Lámpara o Calzas") or not texto.contains("a menos de 3 m") \
			or taller.hud.get_child(0).get_child(0).text != "Cinturón 3/4" \
			or taller.hud.get_child(1).get_child(0).text != "Carrito 0/4 · lejos":
		return "El aviso o el HUD no explicaron la carga: " + texto
	await arbol.process_frame
	await arbol.process_frame
	Clic.clic(arbol.root, bus.flashcard.ok.get_global_rect().get_center())
	Acciones.tecla(bus, 3)
	if not await usar_menu(bus, mesa, "dejar", arbol) \
			or taller.hud.get_child(0).get_child(0).text != "Cinturón 2/4" \
			or taller.mano != "" or not bus.flashcard.cola.is_empty():
		return "Dejar la lámpara en la mesa no liberó un espacio al instante."
	if not await usar_menu(bus, bolsa, "tomar", arbol) or taller.mano != "bolsa_aire" \
			or taller.espacios_hud[2].text != "3 Bolsa de aire ×2" \
			or taller.espacios_hud[3].text != "" \
			or taller.hud.get_child(0).get_child(0).text != "Cinturón 4/4":
		return "La bolsa no ocupó sus dos casillas tras liberar espacio."
	if not await usar_menu(bus, mesa, "dejar", arbol):
		return "No se dejó la bolsa en la mesa."
	Acciones.tecla(bus, 1)
	if not await abrir_cajon_con_clic(bus, 0, arbol) or not await usar_menu(bus, caja, "dejar", arbol) or "calzas" in taller.inventario.cinturon:
		return "La caja roja no liberó espacio."
	taller.carrito.position = carrito_original
	await arbol.physics_frame
	Acciones.tecla(bus, 1)
	bus.jugador.ubicar(taller.carrito.global_position + Vector3.BACK * 3.1)
	bus.apuntar_jugador(carrito.global_position)
	Clic.clic(arbol.root, arbol.root.get_visible_rect().get_center())
	if bus.carrito_cerca() or bus.menu_pieza.visible or taller.mano != "manometro":
		return "El carrito lejano respondió a Dejar o cambió el objeto en mano."
	if not await usar_menu(bus, carrito, "dejar", arbol, 1) \
			or not taller.inventario.cinturon.is_empty() or "manometro" not in taller.objetos_en(taller.carrito):
		return "No se dejó la herramienta en el carrito con la tecla del menú."
	await arbol.physics_frame
	if not await usar_menu(bus, carrito, "tomar", arbol) or taller.mano != "manometro":
		return "No se volvió a tomar la herramienta desde el carrito."
	if not await usar_menu(bus, taller.objetos.calzas, "tomar", arbol) or taller.mano != "calzas":
		return "No se recuperaron las calzas de la caja roja."
	if not await usar_menu(bus, mesa, "tomar", arbol) or taller.mano != "lampara":
		return "No se recuperó la lámpara de la mesa."
	var controles := {"elevador_seguro": true}
	for accion in ["medir_bolsa", "localizar_fuga"]:
		if not bus.motor.ejecutar(accion, "teclado", 0, controles).aplicada:
			return "No se preparó la misión de cambiar la bolsa."
	var llave: StaticBody3D = taller.objetos.llave_ajustable
	# La misión requiere la llave en la mano antes de pedir la bolsa.
	Acciones.tecla(bus, 2)
	# Con los cajones de uno en uno: se guarda en el cajón abierto y se abre el de la llave.
	if taller.cajon_abierto < 0 or not await usar_menu(bus, taller.pieza_cajon(taller.cajon_abierto), "dejar", arbol):
		return "No se guardó la herramienta en el cajón abierto."
	var fila_llave: int = taller.cajones.find(llave.get_parent())
	if not await abrir_cajon_con_clic(bus, fila_llave, arbol) \
			or not await usar_menu(bus, llave, "tomar", arbol):
		return "No se preparó la llave para cambiar la bolsa."
	taller.carrito.position += Vector3.RIGHT * 12
	bus.actualizar_mision()
	if taller.pieza_guia != mesa or not taller.baliza.visible \
			or not bus.hud_mision.filas.any(func(fila: Dictionary) -> bool:
				return fila.texto == "Toma la bolsa de aire en la mesa de trabajo (ocupa 2 espacios).") \
			or not bus.hud_mision.filas.any(func(fila: Dictionary) -> bool:
				return fila.texto == "Deja la lámpara en la mesa de trabajo."):
		return "La guía no indicó qué soltar para tomar la bolsa."
	Acciones.tecla(bus, taller.espacio_de("lampara"))
	if taller.mano != "lampara" or taller.pieza_guia != mesa:
		return "La guía dejó de marcar la mesa al seleccionar la lámpara."
	var bolsa_en_mesa: StaticBody3D = taller.objetos.bolsa_aire
	taller.carrito.global_position = bolsa_en_mesa.global_position + Vector3(1.5, -bolsa_en_mesa.global_position.y, 0.5)
	await arbol.physics_frame
	if not await usar_menu(bus, bolsa_en_mesa, "tomar", arbol) or not bus.carrito_cerca() \
			or taller.inventario.carrito != ["bolsa_aire"] or bus.flashcard.visible \
			or taller.titulos_hud[1].text != "Carrito 2/4":
		return "La bolsa no pasó sola al carrito cercano al faltar espacio."
	if not await usar_menu(bus, carrito, "dejar", arbol, 1) \
			or not taller.inventario.carrito.is_empty() or taller.titulos_hud[1].text != "Carrito 0/4":
		return "Dejar la bolsa en la superficie del carrito no liberó su carga."
	await arbol.physics_frame
	if not await usar_menu(bus, carrito, "tomar", arbol) or taller.mano != "bolsa_aire" \
			or not bus.flashcard.cola.is_empty() or taller.titulos_hud[1].text != "Carrito 2/4":
		return "Al retomar la bolsa del carrito quedó un aviso o una cuenta vieja."
	if not await usar_menu(bus, carrito, "dejar", arbol, 1):
		return "No se pudo preparar el caso de ambos almacenes llenos."
	for id in ["flexometro", "destornillador", "llave_torque", "multimetro", "tech_tool"]:
		if not Acciones.tomar(bus, id):
			return "No se pudieron llenar ambos almacenes."
	await arbol.physics_frame
	if not await usar_menu(bus, carrito, "tomar", arbol) \
			or not bus.flashcard.cuerpo.text.contains("te quedan 0. El cinturón y el carrito están llenos.") \
			or bus.flashcard.cuerpo.text.contains("Acércate al carrito") \
			or not bus.flashcard.cuerpo.text.contains("Flexómetro o Lámpara"):
		return "El aviso con ambos almacenes llenos mostró una cuenta o sugerencia incorrecta."
	return ""


static func abrir_cajon_con_clic(bus: Node3D, fila: int, arbol: SceneTree) -> bool:
	# Si el cajón ya está abierto no hay nada que abrir.
	if bus.taller.cajon_abierto == fila:
		return true
	if not apuntar(bus, bus.taller.pieza_cajon(fila)):
		return false
	bus.recibir_accion(bus.panel.entrada.traducir("teclado", "clic", 1))
	if bus.menu_pieza.visible or bus.taller.cajon_abierto != fila:
		return false
	if bus.taller.animacion != null and bus.taller.animacion.is_valid():
		await bus.taller.animacion.finished
	await arbol.physics_frame
	return true


static func usar_menu(bus: Node3D, pieza: StaticBody3D, id: String, arbol: SceneTree, tecla := 0) -> bool:
	if not apuntar(bus, pieza):
		return false
	Clic.clic(arbol.root, arbol.root.get_visible_rect().get_center())
	if not bus.menu_pieza.visible:
		return false
	if tecla > 0:
		if bus.menu_pieza.entradas[tecla - 1].id != id:
			return false
		Acciones.tecla(bus, tecla)
		return not bus.menu_pieza.visible
	return await elegir(bus, id, arbol) and not bus.menu_pieza.visible


static func comprobar(bus: Node3D, arbol: SceneTree) -> String:
	var taller: Node3D = bus.taller
	if not verificar_catalogo(taller):
		return "Hay un requisito sin objeto en el taller o con un catálogo inválido."
	await arbol.physics_frame
	var eventos: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary): eventos.append(decision))
	for fila in [2, 0, 1]:
		if not await abrir_cajon_con_clic(bus, fila, arbol):
			return "El frente del cajón %d no abrió con clic." % fila
		for indice in taller.cajones.size():
			if (taller.cajones[indice].position.z > 0) != (indice == fila):
				return "El cajón anterior quedó abierto."
		for id in taller.objetos:
			var objeto: StaticBody3D = taller.objetos[id]
			var accesible: bool = objeto.zona != taller.caja_roja or objeto.get_parent() == taller.cajones[fila]
			if apuntar(bus, objeto) != accesible or objeto.visible != accesible:
				return "Acceso incorrecto a %s con el cajón %d abierto." % [id, fila]
		var calzas: StaticBody3D = taller.objetos.calzas
		if fila != 0:
			bus.abrir_menu(calzas)
			if bus.menu_pieza.visible or taller.tomar("calzas", false).is_empty():
				return "Las calzas se pueden tomar con el cajón de abajo cerrado."
	var medio: StaticBody3D = taller.pieza_cajon(1)
	if not apuntar(bus, medio) or not await elegir(bus, "cerrar_cajon", arbol):
		return "El frente abierto no ofrece cerrar el cajón."
	await taller.animacion.finished
	if taller.cajon_abierto != -1 or not taller.objetos_en(taller.caja_roja).is_empty():
		return "Cerrar dejó un cajón accesible."
	if not await abrir_cajon_con_clic(bus, 1, arbol):
		return "El cajón del medio no volvió a abrir."
	var foco: StaticBody3D = taller.objetos.foco
	var destornillador: StaticBody3D = taller.objetos.destornillador
	if not apuntar(bus, destornillador) or not await elegir(bus, "tomar", arbol):
		return "No se puede tomar el destornillador por el menú."
	if not eventos.is_empty() or taller.mano != "destornillador" or bus.jugador.id_mano != "destornillador":
		return "Tomar alteró las decisiones o no seleccionó la herramienta."
	var faro: StaticBody3D = bus.zona_activa.piezas.faro_izquierdo
	bus.ejecutar("inspeccionar", "teclado")
	if not Acciones.equipar(bus, "medir_continuidad"):
		return "No se pudo empuñar el multímetro."
	bus.ejecutar("medir_continuidad", "teclado")
	Acciones.cerrar_exitos(bus)
	Acciones.tecla(bus, 2)
	if not await abrir_cajon_con_clic(bus, 1, arbol):
		return "No se pudo abrir el cajón del medio para guardar el multímetro."
	if not apuntar(bus, medio) or not await elegir(bus, "dejar", arbol):
		return "El cajón del medio no ofreció guardar el multímetro."
	if taller.cajon_abierto != 2 or "multimetro" in taller.inventario.cinturon \
			or taller.objetos.multimetro.get_parent() != taller.origenes.multimetro.padre \
			or taller.objetos.multimetro.position != taller.origenes.multimetro.posicion:
		return "El multímetro no volvió a su cajón."
	Acciones.tecla(bus, 1)
	bus.mostrar_estado(true)
	var puntaje: int = bus.motor.puntaje()
	bus.abrir_menu(faro)
	if not await elegir(bus, "cambiar_foco_correcto", arbol):
		return "Falta la opción de cambiar el foco."
	if bus.accion_pendiente != "" or eventos.size() != 2 or bus.motor.puntaje() != puntaje \
			or not bus.flashcard.visible or bus.flashcard.titulo.text != "Te falta algo" \
			or bus.flashcard.cuerpo.text != "Toma el foco de repuesto en la estantería de repuestos, junto a la mesa de trabajo." \
			or bus.flashcard.donde.text != "Dónde está: la estantería de repuestos, junto a la mesa de trabajo":
		return "El rechazo por inventario no explicó el faltante o afectó la orden."
	if taller.baliza.visible:
		return "La guía se encendió antes de cerrar la tarjeta."
	await arbol.process_frame
	await arbol.process_frame
	Clic.clic(bus.get_viewport(), bus.flashcard.ok.get_global_rect().get_center())
	if bus.flashcard.visible or taller.objetivo != "foco" or not taller.baliza.visible \
			or not is_equal_approx(taller.baliza.global_position.x, taller.estanteria.global_position.x):
		return "La guía del foco no apunta a la estantería."
	taller.caducidad.timeout.emit()
	if taller.baliza.visible or not taller.objetivo.is_empty():
		return "La baliza no se apagó al vencer."
	var guia := InputEventKey.new()
	guia.keycode = KEY_G
	guia.pressed = true
	bus._input(guia)
	bus.flashcard.ok.pressed.emit()
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
	if taller.mano != "foco" or taller.espacios_hud[1].text != "2 Foco de repuesto":
		return "La rueda no seleccionó el foco o el HUD mostró una carga incorrecta."
	var mesa: StaticBody3D = taller.mesa.piezas.mesa_taller
	if not apuntar(bus, mesa) or not await elegir(bus, "dejar", arbol):
		return "No se pudo dejar el foco en la mesa."
	await arbol.physics_frame
	if foco.zona != taller.mesa or not apuntar(bus, foco) or not await elegir(bus, "tomar", arbol):
		return "No se pudo volver a tomar el foco de la mesa."
	Acciones.tecla(bus, 1)
	bus.abrir_menu(faro)
	if not await elegir(bus, "cambiar_foco_correcto", arbol) or bus.accion_pendiente != "cambiar_foco_correcto":
		return "La acción equipada no pidió confirmación."
	bus.panel.emitir("confirmar", 1)
	if not bus.motor.estado().foco_repuesto or eventos.size() != 3 \
			or "foco" in taller.inventario.cinturon or "destornillador" not in taller.inventario.cinturon \
			or foco.zona != taller.estanteria:
		return "El panel no consumió la pieza y conservó la herramienta."
	Acciones.cerrar_exitos(bus)
	return await probar_carrito(bus, arbol, eventos)


static func probar_carrito(bus: Node3D, arbol: SceneTree, eventos: Array[Dictionary]) -> String:
	var taller: Node3D = bus.taller
	var carrito: StaticBody3D = taller.carrito.piezas.carrito_taller
	var mesa: StaticBody3D = taller.mesa.piezas.mesa_taller
	Acciones.tecla(bus, 1)
	for mueble in [mesa, carrito]:
		await arbol.physics_frame
		if not apuntar(bus, mueble):
			return "La mira no alcanza el mueble."
		bus.recibir_accion(bus.panel.entrada.traducir("teclado", "clic", 1))
		if bus.menu_pieza.entradas.any(func(entrada: Dictionary) -> bool: return entrada.id == "tomar"):
			return "Un mueble vacío ofrece una opción Tomar."
		if not await elegir(bus, "dejar", arbol) or taller.objetos.destornillador.zona != mueble.zona:
			return "El objeto no quedó sobre el mueble elegido."
		await arbol.physics_frame
		if not apuntar(bus, mueble) or not await elegir(bus, "tomar", arbol) or taller.mano != "destornillador":
			return "El menú del mueble no recuperó el objeto."
	if eventos.size() != 3:
		return "Usar los muebles alteró las decisiones de la orden."
	var ids := ["destornillador", "multimetro", "flexometro", "lampara",
		"llave_torque", "llave_ajustable", "tech_tool", "calzas"]
	for id in ids.slice(1):
		if not Acciones.tomar(bus, id):
			return "No se pudo llenar el inventario."
	bus.abrir_menu(carrito)
	if not Acciones.elegir(bus, "tomar", "llave_torque") or taller.mano != "llave_torque":
		return "El menú del carrito no empuñó un objeto de la bandeja."
	for numero in range(1, 9):
		Acciones.tecla(bus, numero)
		if taller.mano != ids[numero - 1] or bus.jugador.id_mano != taller.mano 				or taller.espacios_hud[numero - 1].modulate != taller.COLOR_MANO:
			return "El número %d no empuñó o resaltó el objeto." % numero
	bus.jugador.ubicar(taller.carrito.global_position + Vector3.BACK * 3.1)
	bus.actualizar_inventario()
	Acciones.tecla(bus, 5)
	if not taller.mano.is_empty() or bus.flashcard.cuerpo.text != "El carrito está lejos. Acércate para tomar lo que necesitas." 			or taller.espacios_hud[4].modulate == Color.WHITE:
		return "El carrito lejano sigue disponible en el HUD."
	bus.flashcard.confirmar()
	Acciones.tecla(bus, 2)
	if taller.mano != "multimetro":
		return "El cinturón dejó de funcionar al alejarse."
	bus.abrir_menu(taller.pieza_cajon(taller.cajon_abierto))
	Acciones.tecla(bus, 1)
	if taller.cajon_abierto != -1 or bus.menu_pieza.visible or taller.mano != "multimetro":
		return "El número no eligió la acción del menú abierto."
	return ""



static func apuntar(bus: Node3D, pieza: StaticBody3D) -> bool:
	var taller: Node3D = bus.taller
	var frente := Vector3.BACK.rotated(Vector3.UP, pieza.zona.rotation.y)
	var distancia := 1.20
	if pieza.zona == taller.caja_roja and taller.objetos.get(pieza.componente) == pieza:
		distancia = 0.48
	var blanco := pieza.global_position
	var origen := blanco + frente * distancia
	if pieza.componente.begins_with("cajon_taller_"):
		blanco.x += 0.45
		origen.x += 1.25
	bus.jugador.ubicar(Vector3(origen.x, 0, origen.z))
	bus.apuntar_jugador(blanco)
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
					for objeto in ([requiere[tipo]] if tipo == "herramienta" else requiere[tipo]):
						if Inventario.objeto(objeto).is_empty() or not taller.objetos.has(objeto) \
								or not taller.ubicaciones.has(taller.objetos[objeto].zona):
							return false
	var alterado: Dictionary = Escenario.cargar("escenarios/faros.json").escenario
	var original: String = alterado.causa_correcta
	alterado.causa_correcta = "desconocida"
	if Escenario.campo_invalido(alterado) != "causa_correcta":
		return false
	alterado.causa_correcta = original
	var explicacion: String = alterado.explicacion_causa[original]
	alterado.explicacion_causa[original] = ""
	if Escenario.campo_invalido(alterado) != "explicacion_causa." + original:
		return false
	alterado.explicacion_causa[original] = explicacion
	for requiere in [[], {"piezas": ["multimetro"]}, {"piezas": ["desconocido"]},
			{"herramienta": "foco"}, {"herramienta": "desconocida"}, {"herramienta": ["destornillador"]},
			{"herramientas": ["destornillador", "destornillador"]}]:
		alterado.acciones.cambiar_foco_correcto.requiere = requiere
		if Escenario.campo_invalido(alterado) != "acciones.cambiar_foco_correcto.requiere":
			return false
	return true


static func probar_motor(arbol: SceneTree) -> bool:
	var bus := Bus.instantiate()
	bus.archivo = "escenarios/motor.json"
	arbol.root.add_child(bus)
	bus.flashcard.confirmar()
	var correcto := probar_herramienta(bus) and ruta_motor(bus)
	bus.free()
	return correcto


static func probar_herramienta(bus: Node3D) -> bool:
	var antes: Dictionary = bus.motor.estado()
	var titulo: Label = bus.hud_mision.titulo
	if titulo.autowrap_mode == TextServer.AUTOWRAP_OFF or titulo.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING 			or titulo.text != "Inspecciona la tapa del motor":
		return false
	bus.ejecutar("inspeccionar", "teclado")
	if not bus.flashcard.visible or bus.flashcard.cola[0].tipo != "falta" or bus.flashcard.donde.text.is_empty():
		return false
	bus.flashcard.confirmar()
	if not Acciones.equipar(bus, "inspeccionar"):
		return false
	Acciones.tecla(bus, 4)
	bus.ejecutar("inspeccionar", "teclado")
	if not bus.flashcard.visible or bus.flashcard.cola[0].tipo != "aviso" 			or bus.flashcard.cuerpo.text != "Pulsa 1 para tener el destornillador en la mano." 			or bus.motor.puntaje() != 100 or bus.motor.estado() != antes:
		return false
	bus.flashcard.confirmar()
	if not Acciones.equipar(bus, "revisar_refrigerante"):
		return false
	var errores: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary):
		if decision.tipo_error == "herramienta-equivocada":
			errores.append(decision))
	bus.ejecutar("inspeccionar", "teclado")
	if bus.flashcard.titulo.text != "Herramienta equivocada" 			or bus.flashcard.cuerpo.text != "Traes la lámpara. Cámbiala por el destornillador." 			or bus.motor.puntaje() != 96 or bus.motor.estado() != antes or errores.size() != 1 			or errores[0].aplicada or errores[0].criticidad != "leve":
		return false
	bus.flashcard.confirmar()
	return true


static func ruta_motor(bus: Node3D) -> bool:
	if not Acciones.equipar(bus, "ajustar_abrazadera"):
		return false
	var abrazadera: StaticBody3D = bus.taller.objetos.abrazadera
	bus.ejecutar("ajustar_abrazadera", "virtual")
	if not bus.flashcard.visible or abrazadera.visible or "abrazadera" not in bus.taller.inventario.cinturon:
		return false
	bus.flashcard.ok.pressed.emit()
	bus.panel.get_node("Bloqueo").button_pressed = true
	bus.panel.get_node("Etiquetado").button_pressed = true
	for id in bus.datos.ruta_ideal:
		if not Acciones.equipar(bus, id):
			return false
		bus.ejecutar(id, "virtual")
	return bus.motor.fin() == "resuelto" and Acciones.cerrar_orden(bus) and abrazadera.visible \
		and "abrazadera" not in bus.taller.inventario.cinturon \
		and "llave_torque" in bus.taller.inventario.cinturon


static func probar_cierres(base: String) -> bool:
	var raiz := (Engine.get_main_loop() as SceneTree).root
	for caso in [["correcto", 0, 100], ["incorrecto", 1, 0]]:
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/faros.json"
		bus.tecnico = Alias.alta(base, "T-613%d" % caso[1]).merged({"base": base})
		raiz.add_child(bus)
		bus.flashcard.confirmar()
		var correcto := comprobar_cierre(bus, base, caso)
		bus.free()
		if not correcto:
			return false
	return true


static func comprobar_cierre(bus: Node3D, base: String, caso: Array) -> bool:
	for accion in bus.datos.ruta_ideal:
		if not Acciones.equipar(bus, accion):
			return false
		bus.ejecutar(accion, "virtual")
	Acciones.cerrar_exitos(bus)
	Acciones.mostrar_siguiente_mision(bus)
	if not bus.flashcard.visible or bus.flashcard.titulo.text != "¿Qué causó la falla?" 			or bus.flashcard.opciones.size() != 2 or bus.resultados_guardados or bus.resumen.visible:
		return false
	if caso[1] == 0:
		bus.flashcard.opciones[0].pressed.emit()
	else:
		bus.flashcard.opciones[1].grab_focus()
		var evento := InputEventJoypadButton.new()
		evento.button_index = JOY_BUTTON_A
		evento.pressed = true
		bus.get_viewport().push_input(evento, true)
	if bus.flashcard.titulo.text != caso[0].capitalize() 			or not bus.flashcard.cuerpo.text.contains("Causa real: Foco dañado") 			or bus.flashcard.fuente.text != "Fuente: ejemplo didáctico, sin fuente oficial" or not bus.resultados_guardados:
		return false
	bus.flashcard.confirmar()
	var detalle := Resumen.textos_visibles(bus.resumen.get_node("%DiagnosticoContenido"))
	if not bus.resumen.visible or not detalle.contains("Tu respuesta: ") \
			or not detalle.contains("\n" + caso[0].capitalize() + "\n"):
		return false
	var intentos: Array = Base.consultar(base,
		"SELECT formato, valor, peso, tipo_error FROM intento WHERE tecnico = ? ORDER BY id;", [bus.tecnico.id])
	if intentos.size() != 2 or Dominio.calcular(intentos) != 100.0:
		return false
	var intento: Dictionary = intentos[1]
	var error: Variant = null if caso[1] == 0 else "causa-equivocada"
	var eventos: Array = Base.consultar(base,
		"SELECT json_extract(estado_despues, '$.causa_elegida') AS causa FROM evento WHERE tecnico = ? AND accion = 'diagnostico_final';",
		[bus.tecnico.id])
	return intento.valor == caso[2] and intento.tipo_error == error 		and eventos == [{"causa": bus.datos.causas[caso[1]]}]
