extends RefCounted

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
	bus.jugador.set_physics_process(false)
	var fallo := await comprobar(bus, arbol)
	visor.free()
	if not fallo.is_empty():
		printerr(fallo)
		return false
	return probar_motor(arbol) and Base.con_base(probar_cierres)


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
	if not Acciones.equipar(bus, "medir_continuidad"):
		return "No se pudo empuñar el multímetro."
	bus.ejecutar("medir_continuidad", "teclado")
	Acciones.tecla(bus, 2)
	if not apuntar(bus, caja) or not await elegir(bus, "dejar", arbol) 			or "multimetro" in taller.inventario.cinturon 			or taller.objetos.multimetro.get_parent() != taller.origenes.multimetro.padre 			or taller.objetos.multimetro.position != taller.origenes.multimetro.posicion:
		return "El multímetro no volvió a su cajón."
	Acciones.tecla(bus, 1)
	bus.mostrar_estado(true)
	var puntaje: int = bus.motor.puntaje()
	bus.abrir_menu(faro)
	if not await elegir(bus, "cambiar_foco_correcto", arbol):
		return "Falta la opción de cambiar el foco."
	if bus.accion_pendiente != "" or eventos.size() != 2 or bus.motor.puntaje() != puntaje \
			or not bus.flashcard.visible or bus.flashcard.titulo.text != "Te falta algo" \
			or bus.flashcard.cuerpo.text != "Necesitas: Foco de repuesto" \
			or bus.flashcard.donde.text != "Dónde está: la estantería de piezas, a la izquierda de la mesa":
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
		bus.abrir_menu(taller.objetos[id])
		if not Acciones.elegir(bus, "tomar"):
			return "No se pudo llenar el inventario."
	bus.abrir_menu(carrito)
	if not Acciones.elegir(bus, "tomar", "llave_torque") or taller.mano != "llave_torque":
		return "El menú del carrito no empuñó un objeto de la bandeja."
	for numero in range(1, 9):
		Acciones.tecla(bus, numero)
		if taller.mano != ids[numero - 1] or bus.jugador.id_mano != taller.mano 				or taller.espacios_hud[numero - 1].modulate != taller.GUIA:
			return "El número %d no empuñó o resaltó el objeto." % numero
	bus.jugador.ubicar(taller.carrito.global_position + Vector3.BACK * 3.1)
	bus.actualizar_inventario()
	Acciones.tecla(bus, 5)
	if not taller.mano.is_empty() or bus.resultado.text != "El carrito está lejos" 			or taller.espacios_hud[4].modulate == Color.WHITE:
		return "El carrito lejano sigue disponible en el HUD."
	Acciones.tecla(bus, 2)
	if taller.mano != "multimetro":
		return "El cinturón dejó de funcionar al alejarse."
	bus.abrir_menu(taller.caja_roja.piezas.caja_taller)
	Acciones.tecla(bus, 1)
	if taller.cajones_abiertos or bus.menu_pieza.visible or taller.mano != "multimetro":
		return "El número no eligió la acción del menú abierto."
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
	var correcto := probar_herramienta(bus) and ruta_motor(bus)
	bus.free()
	return correcto


static func probar_herramienta(bus: Node3D) -> bool:
	var antes: Dictionary = bus.motor.estado()
	var titulo: Label = bus.lateral.get_node("Estado")
	if titulo.autowrap_mode == TextServer.AUTOWRAP_OFF or titulo.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING 			or titulo.text != bus.datos.titulo.trim_prefix("[MUESTRA] "):
		return false
	bus.ejecutar("inspeccionar", "teclado")
	if not bus.flashcard.visible or bus.flashcard.cola[0].tipo != "falta" or bus.flashcard.donde.text.is_empty():
		return false
	bus.flashcard.confirmar()
	if not Acciones.equipar(bus, "inspeccionar"):
		return false
	Acciones.tecla(bus, 4)
	bus.ejecutar("inspeccionar", "teclado")
	if not bus.flashcard.visible or bus.flashcard.cola[0].tipo != "aviso" 			or bus.flashcard.cuerpo.text != "Toma la herramienta en la mano: presiona 1." 			or bus.motor.puntaje() != 100 or bus.motor.estado() != antes:
		return false
	bus.flashcard.confirmar()
	if not Acciones.equipar(bus, "revisar_refrigerante"):
		return false
	var errores: Array[Dictionary] = []
	bus.decision_tomada.connect(func(decision: Dictionary):
		if decision.tipo_error == "herramienta-equivocada":
			errores.append(decision))
	bus.ejecutar("inspeccionar", "teclado")
	if bus.flashcard.titulo.text != "Herramienta equivocada" 			or bus.flashcard.cuerpo.text != "Tienes en la mano: Lámpara. Para esto necesitas: Destornillador." 			or bus.motor.puntaje() != 96 or bus.motor.estado() != antes or errores.size() != 1 			or errores[0].aplicada or errores[0].criticidad != "leve":
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
	if bus.flashcard.titulo.text != caso[0].capitalize() 			or not bus.flashcard.cuerpo.text.contains("Causa real: Foco dañado") 			or not bus.flashcard.fuente.text.contains(bus.datos.fuente) or not bus.resultados_guardados:
		return false
	bus.flashcard.confirmar()
	if not bus.resumen.visible or not bus.resumen.get_node("Detalle").text.contains("Diagnóstico final: " + caso[0].capitalize()):
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
