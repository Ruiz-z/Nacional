extends SceneTree

# Uso: godot --path godot -s ../tools/captura.gd -- escenas/bus.tscn ../build/capturas/bus.png
# Órdenes: godot --path godot -s ../tools/captura.gd -- ordenes salida.png 1280 720
# Menú: godot --path godot -s ../tools/captura.gd -- escenas/menu.tscn salida.png 1280 720
# Cabina: [ancho alto] cabina|interior [tablero|puerta] [menu] [--verificar]
# Otras zonas: [ancho alto] comunicacion|faros|motor [cerrado|abierto|animacion] [menu] [--verificar]
# Flashcard: [ancho alto] flashcard falta|aviso|error|critico [--verificar]
# Resumen y hallazgo del motor: [ancho alto] resumen|resumen-critico|exito [--verificar]
# Cierre: [ancho alto] cierre [correcto|incorrecto] [--verificar]
# Misiones: [ancho alto] mision [motor|faros|neumatico] [--verificar]
# Inventario: [ancho alto] inventario [--verificar]
# Taller: [ancho alto] taller|baliza|elevador|elevador-guia|bajos [--verificar]
# Banco: [ancho alto] banco-mesa|banco-puntas|hoja|orden [--verificar]
# Alias del banco: [ancho alto] banco [cerrado|midiendo] [menu] [--verificar]
# Gabinete: [ancho alto [x y z yaw [pitch]]] [entrada|cerrado|abierto|danado] [menu] [--verificar]
const Acciones = preload("res://tests/acciones_taller.gd")


func _initialize() -> void:
	call_deferred("capturar")


func capturar() -> void:
	var args := OS.get_cmdline_user_args()
	var verificar := args.size() > 0 and args[-1] == "--verificar"
	if verificar:
		args.remove_at(args.size() - 1)
	var orden_mision := "motor"
	if args.size() > 3 and args[-2] == "mision":
		orden_mision = args[-1]
		if orden_mision not in ["motor", "faros", "neumatico"]:
			fallar("Usa mision [motor|faros|neumatico].")
			return
		args.remove_at(args.size() - 1)
	var tipo_flashcard := ""
	if args.size() >= 4 and args[-2] == "flashcard":
		tipo_flashcard = args[-1]
		if tipo_flashcard not in ["falta", "aviso", "error", "critico"]:
			fallar("Usa flashcard falta|aviso|error|critico.")
			return
		args.resize(args.size() - 2)
	var respuesta := ""
	if args.size() > 3 and args[-2] == "cierre" and args[-1] in ["correcto", "incorrecto"]:
		respuesta = args[-1]
		args.remove_at(args.size() - 1)
	var menu := args.size() > 2 and args[-1] == "menu"
	if menu:
		args.remove_at(args.size() - 1)
	var vista := ""
	if args.size() > 2 and args[-1] in ["entrada", "cerrado", "abierto", "animacion", "danado", "tablero", "puerta", "midiendo", "taller", "baliza", "elevador", "elevador-guia", "bajos", "inventario", "cierre", "resumen", "resumen-critico", "exito", "mision", "banco-mesa", "banco-puntas", "hoja", "orden"]:
		vista = args[-1]
		args.remove_at(args.size() - 1)
	var vista_taller := vista in ["taller", "baliza", "elevador", "elevador-guia", "bajos", "inventario", "cierre", "resumen", "resumen-critico", "exito", "mision"]
	var zona := ""
	if args.size() > 2 and args[-1] in ["cabina", "interior", "comunicacion", "faros", "motor", "banco"]:
		zona = args[-1]
		args.remove_at(args.size() - 1)
		if zona == "comunicacion":
			zona = "cabina"
			if vista == "abierto":
				vista = "tablero"
		if zona in ["cabina", "interior"]:
			if vista.is_empty():
				vista = "tablero" if zona == "cabina" else "puerta"
			if vista not in ["tablero", "puerta"]:
				fallar("Usa cabina|interior [tablero|puerta].")
				return
		elif zona == "banco":
			if vista.is_empty():
				vista = "cerrado"
			if vista not in ["cerrado", "midiendo"]:
				fallar("Usa banco [cerrado|midiendo].")
				return
		elif vista.is_empty():
			vista = "cerrado"
		elif vista not in ["cerrado", "abierto", "animacion"]:
			fallar("Usa faros|motor [cerrado|abierto|animacion].")
			return
		if args.size() not in [2, 4]:
			fallar("Indica la zona después de las dimensiones opcionales.")
			return
	if vista in ["banco-mesa", "banco-puntas", "hoja", "orden"]:
		zona = "banco"
	if vista == "midiendo" and zona != "banco":
		fallar("Usa banco para la vista midiendo.")
		return
	if vista == "animacion" and (zona.is_empty() or menu):
		fallar("Usa faros|motor para la vista animacion, con el menú cerrado.")
		return
	if args.size() not in [2, 4, 8, 9]:
		fallar("Uso: -- <escena res://> <salida.png> [ancho alto [x y z yaw [pitch] [entrada|cerrado|abierto|danado]]] [menu] [--verificar]")
		return
	var tam := Vector2i(1280, 720)
	if args.size() >= 4:
		if not args[2].is_valid_int() or not args[3].is_valid_int():
			fallar("Las dimensiones deben ser enteras.")
			return
		tam = Vector2i(int(args[2]), int(args[3]))
		if tam.x < 1 or tam.y < 1:
			fallar("Las dimensiones deben ser positivas.")
			return
	for indice in range(4, args.size()):
		if not args[indice].is_valid_float() or not is_finite(float(args[indice])):
			fallar("La posición y los giros deben ser números finitos.")
			return
	if not verificar and DisplayServer.get_name() == "headless":
		fallar("La captura requiere un servidor gráfico. Usa --verificar para comprobar el estado sin generar PNG.")
		return
	var ruta := "escenas/ordenes.tscn" if args[0] == "ordenes" else args[0]
	var paquete := load("res://" + ruta) as PackedScene
	if paquete == null:
		fallar("No se pudo cargar la escena.")
		return
	var vp := SubViewport.new()
	vp.size = tam
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var escena := paquete.instantiate()
	var sector := escena.get_node_or_null("Sector")
	if not vista.is_empty():
		if sector == null or not escena.has_method("mostrar_estado"):
			escena.free()
			fallar("La escena no tiene un gabinete de servicio.")
			return
		escena.modo_captura = true
	if vista in ["elevador", "elevador-guia", "bajos"]:
		escena.archivo = "escenarios/neumatico_pinchado.json"
	elif vista == "mision":
		var archivo := "neumatico_pinchado" if orden_mision == "neumatico" else orden_mision
		escena.archivo = "escenarios/%s.json" % archivo
	elif vista in ["baliza", "cierre", "resumen"]:
		escena.archivo = "escenarios/faros.json"
	elif vista in ["inventario", "exito"]:
		escena.archivo = "escenarios/motor.json"
	if not zona.is_empty():
		if zona != "interior":
			escena.archivo = "escenarios/%s.json" % {"cabina": "comunicacion", "banco": "modulo_auxiliar"}.get(zona, zona)
		escena.get_node("Jugador").set_physics_process(false)
	vp.add_child(escena)
	if vista != "orden" and escena.get_node_or_null("Flashcard") != null:
		escena.flashcard.confirmar()

	if not vista.is_empty():
		if escena.motor == null:
			fallar("El simulador no se inicializó.")
			return
		if vista in ["elevador", "elevador-guia", "bajos"]:
			if not preparar_elevador(escena, vista):
				fallar("El elevador o su encuadre no corresponde a la vista.")
				return
		elif vista == "mision":
			if not preparar_mision(escena, orden_mision):
				fallar("No se pudo preparar la misión.")
				return
		elif vista in ["cierre", "inventario", "resumen", "resumen-critico", "exito"]:
			if not preparar_orden(escena, vista, respuesta):
				fallar("La orden no corresponde a la vista solicitada.")
				return
		elif vista_taller:
			if not preparar_taller(escena, vista):
				fallar("El taller no corresponde a la vista solicitada.")
				return
		if vista in ["abierto", "animacion", "danado"]:
			sector = escena.zona_activa
			if not Acciones.equipar(escena, "inspeccionar"):
				fallar("No se pudo empuñar el destornillador.")
				return
			escena.ubicar_jugador(sector.acceso)
			await physics_frame
			await physics_frame
			if not comprobar_pieza(escena, sector.acceso):
				fallar("La mira no alcanza la tapa antes de abrir.")
				return
			escena.recibir_accion(escena.panel.entrada.traducir("teclado", "clic", 1))
			var indice: int = escena.menu_pieza.entradas.find_custom(
				func(entrada: Dictionary) -> bool: return entrada.id == "inspeccionar")
			if not escena.menu_pieza.visible or indice < 0:
				fallar("Inspeccionar no aparece en el menú de la tapa.")
				return
			escena.menu_pieza.botones[indice].pressed.emit()
			if not is_instance_valid(sector.animacion) or not sector.animacion.is_running():
				fallar("Inspeccionar no inició la animación.")
				return
			if vista == "animacion":
				await create_timer(0.21).timeout
				sector.animacion.pause()
			else:
				await sector.animacion.finished
			Acciones.cerrar_exitos(escena)
		if vista == "danado":
			if not Acciones.equipar(escena, "forzar_pieza"):
				fallar("No se pudo empuñar la llave ajustable.")
				return
			escena.ejecutar("forzar_pieza", "teclado")
		if zona in ["cabina", "interior"]:
			sector = escena.interior
			var objetivo := "monitor"
			if vista == "puerta":
				if menu:
					objetivo = "puerta_salida"
					escena.ubicar_interior(sector.ENTRADA, objetivo)
				else:
					escena.ubicar_interior(sector.ENTRADA, "cables")
					escena.apuntar_jugador(sector.to_global(Vector3(0, 1.32, 4.6)))
			else:
				escena.ubicar_interior(sector.CABINA, objetivo)
			await physics_frame
			await physics_frame
			if sector.falla_red != (zona == "cabina") \
					or ((vista == "tablero" or menu) and not comprobar_pieza(escena, objetivo)):
				fallar("El estado o encuadre del interior no corresponde a la vista.")
				return
		elif zona == "banco":
			sector = escena.zona_activa
			var midiendo := vista in ["midiendo", "banco-puntas"]
			var objetivo := "tp0" if midiendo else "multimetro"
			escena.ubicar_jugador(objetivo)
			await physics_frame
			await physics_frame
			if midiendo:
				if not Acciones.equipar(escena, "medir_tp1"):
					fallar("No se pudo empuñar el multímetro.")
					return
				for punto in ["tp0", "tp1"]:
					escena.apuntar_jugador(sector.piezas[punto].global_position)
					if not comprobar_pieza(escena, punto):
						fallar("La mira no alcanza %s." % punto.to_upper())
						return
					escena.recibir_accion(escena.panel.entrada.traducir("teclado", "clic", 1))
					Acciones.cerrar_exitos(escena)
				if escena.jugador.pantalla_multimetro.text != "0.0 V" \
						or not sector.pinzas.tp0.visible or not sector.pinzas.tp1.visible:
					fallar("Falta la lectura en la mano o una pinza.")
					return
			elif vista == "hoja":
				escena.apuntar_jugador(sector.piezas.hoja_diagnostico.global_position)
				escena.abrir_menu(sector.piezas.hoja_diagnostico)
				if not escena.hoja.visible:
					fallar("La hoja de diagnóstico no se abrió.")
					return
			elif vista == "orden":
				if not escena.flashcard.visible or escena.flashcard.chip.text != "ORDEN DE TRABAJO":
					fallar("No se mostró la tarjeta de orden.")
					return
			elif not sector.piezas.multimetro.visible or not comprobar_pieza(escena, objetivo):
				fallar("El multímetro no aparece sobre la mesa.")
				return
		elif not zona.is_empty():
			sector = escena.zona_activa
			var objetivo: String = sector.acceso
			if vista == "abierto":
				objetivo = {"faros": "conector_faros", "motor": "monitor_temperatura"}[zona]
			if vista != "animacion":
				escena.ubicar_jugador(objetivo)
			await physics_frame
			await physics_frame
			var giro: Vector3 = sector.bisagra.rotation_degrees
			var destino: Vector3 = sector.giro_abierto
			var giro_correcto := (not giro.is_zero_approx() and not giro.is_equal_approx(destino)) \
				if vista == "animacion" else giro.is_equal_approx(destino if vista == "abierto" else Vector3.ZERO)
			if sector.abierta != (vista != "cerrado") or not giro_correcto \
					or (vista != "animacion" and not comprobar_pieza(escena, objetivo)):
				fallar("El estado o el encuadre de la zona no corresponde a la vista %s." % vista)
				return
		elif not vista_taller and not comprobar_estado(escena, sector, vista):
			fallar("El estado del gabinete no corresponde a la vista %s." % vista)
			return
		if not vista_taller and zona.is_empty() and args.size() < 8 and vista != "entrada":
			escena.get_node("Jugador").set_physics_process(false)
			escena.ubicar_jugador(pieza_gabinete(vista, menu))
		if vista == "entrada":
			escena.get_node("Interfaz").hide()
			escena.get_node("PistaControles").hide()
			escena.get_node("AlineacionPanel").hide()
			escena.get_node("AlternarPanel").hide()
			escena.set_process(false)
		var triangulos := 0
		for nodo in escena.find_children("*", "MeshInstance3D", true, false):
			if nodo.mesh != null:
				triangulos += int(nodo.mesh.get_faces().size() / 3.0)
		print("Triángulos de malla (incluidas herramientas ocultas): ", triangulos)
		if triangulos >= 120000:
			fallar("La escena supera el presupuesto de triángulos.")
			return
	if args.size() >= 8:
		var jugador := escena.get_node_or_null("Jugador") as CharacterBody3D
		if jugador == null:
			fallar("La escena no tiene un nodo Jugador.")
			return
		jugador.set_physics_process(false)
		jugador.position = Vector3(float(args[4]), float(args[5]), float(args[6]))
		jugador.rotation_degrees.y = float(args[7])
		var camara: Camera3D = jugador.get_node("Camara")
		if args.size() == 9:
			camara.rotation_degrees.x = float(args[8])
		elif vista in ["cerrado", "abierto", "danado"]:
			var id := pieza_gabinete(vista, menu)
			camara.rotation = Vector3.ZERO
			var objetivo: Vector3 = camara.to_local(sector.piezas[id].global_position)
			camara.rotation.x = atan2(objetivo.y, -objetivo.z)
		print("Cámara ", camara.global_position, ", giro ", args[7], "°, inclinación ", camara.rotation_degrees.x, "°")
	if not vista_taller and zona.is_empty() and not vista.is_empty():
		await physics_frame
		await physics_frame
		if not comprobar_encuadre(escena, vista, menu):
			fallar("El encuadre no corresponde a la vista %s." % vista)
			return
	if menu:
		if sector == null or not escena.has_method("abrir_menu"):
			fallar("La escena no tiene un menú de piezas.")
			return
		await physics_frame
		await physics_frame
		escena.alcance.force_raycast_update()
		var pieza := escena.alcance.get_collider() as StaticBody3D
		if pieza == null or pieza.get("componente") == null:
			fallar("La mira no está sobre una pieza. Ajusta la posición y el giro de la cámara.")
			return
		escena.abrir_menu(pieza)
		if not escena.menu_pieza.visible:
			fallar("No se pudo abrir el menú de la pieza.")
			return
		await process_frame
		await process_frame
		var tarjeta: Control = escena.menu_pieza.get_node("Centro/Tarjeta")
		if not vp.get_visible_rect().encloses(tarjeta.get_global_rect()) \
				or (escena.panel.visible and tarjeta.get_global_rect().intersects(escena.panel.get_global_rect())):
			fallar("El menú queda recortado o invade el panel virtual.")
			return
	if not tipo_flashcard.is_empty():
		if not escena.has_method("avisar"):
			fallar("Usa la escena del autobús para la vista flashcard.")
			return
		preparar_flashcard(escena, tipo_flashcard)
	await process_frame
	await process_frame
	if not tipo_flashcard.is_empty() and (not escena.flashcard.visible \
			or not vp.get_visible_rect().encloses(escena.flashcard.tarjeta.get_global_rect())):
		fallar("La tarjeta no se abrió o queda recortada.")
		return
	if vista in ["cierre", "exito", "orden"] and not vp.get_visible_rect().encloses(escena.flashcard.tarjeta.get_global_rect()):
		fallar("La tarjeta de la orden queda recortada.")
		return
	if vista in ["resumen", "resumen-critico"] and (not escena.resumen.visible \
			or not vp.get_visible_rect().encloses(escena.resumen.get_node("%Acciones").get_global_rect())):
		fallar("Las acciones del resumen quedan recortadas.")
		return
	if vista == "mision" and not vp.get_visible_rect().encloses(escena.hud_mision.get_global_rect()):
		fallar("La tarjeta de misión queda recortada.")
		return
	if vista == "hoja":
		var guardar: Button = escena.hoja.guardar
		if not vp.get_visible_rect().encloses(guardar.get_parent().get_global_rect()):
			fallar("Los botones de la hoja quedan recortados.")
			return
	if vista == "inventario":
		if not vp.get_visible_rect().encloses(escena.taller.hud.get_global_rect()):
			fallar("El inventario debe caber en el encuadre.")
			return
	if verificar:
		quit(0)
		return
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		fallar("El renderizador no produjo una imagen.")
		return
	var resultado := img.save_png(args[1])
	if resultado != OK:
		fallar("No se pudo guardar %s (%s)." % [args[1], error_string(resultado)])
		return
	print("Guardado ", args[1], " ", img.get_size())
	quit(0)


func preparar_mision(escena: Node3D, orden: String) -> bool:
	escena.jugador.set_physics_process(false)
	var previas := {"motor": 3, "faros": 2, "neumatico": 0}
	for id in escena.datos.ruta_ideal.slice(0, previas[orden]):
		if not Acciones.equipar(escena, id):
			return false
		escena.ejecutar(id, "virtual")
		Acciones.cerrar_exitos(escena)
	if orden == "neumatico":
		var elevador := escena.get_node("Elevador")
		elevador.colocar_calzas()
		elevador.mover(true, true)
		for soporte in elevador.trabas:
			elevador.cambiar_traba(soporte, true)
	var id: String = escena.datos.ruta_ideal[previas[orden]]
	if not Acciones.equipar(escena, id):
		return false
	escena.mostrar_estado(true)
	escena.ubicar_jugador(escena.datos.acciones[id].componente)
	return escena.hud_mision.indice == previas[orden] and not escena.flashcard.visible


func preparar_orden(escena: Node3D, vista: String, respuesta: String) -> bool:
	escena.jugador.set_physics_process(false)
	escena.ubicar_jugador(escena.zona_activa.acceso)
	if vista == "exito":
		for id in escena.datos.ruta_ideal.slice(0, 3):
			if not Acciones.equipar(escena, id):
				return false
			escena.ejecutar(id, "virtual")
		return escena.flashcard.visible and escena.flashcard.cola[0].tipo == "exito"
	if vista in ["resumen", "resumen-critico"]:
		return preparar_resumen(escena, vista == "resumen-critico")
	if vista == "cierre":
		for id in escena.datos.ruta_ideal:
			if not Acciones.equipar(escena, id):
				return false
			escena.ejecutar(id, "virtual")
		Acciones.cerrar_exitos(escena)
		if not escena.flashcard.visible or escena.flashcard.opciones.size() != 2:
			return false
		if not respuesta.is_empty():
			escena.flashcard.opciones[0 if respuesta == "correcto" else 1].pressed.emit()
			return escena.flashcard.titulo.text == respuesta.capitalize()
		return true
	var taller: Node3D = escena.taller
	escena.jugador.ubicar(taller.carrito.global_position + Vector3.BACK * 1.6)
	escena.apuntar_jugador(taller.carrito.global_position + Vector3.UP * 0.8)
	taller.cambiar_cajones(true, true)
	for id in ["destornillador", "multimetro", "lampara", "llave_ajustable", "tech_tool", "llave_torque"]:
		escena.abrir_menu(taller.objetos[id])
		if not Acciones.elegir(escena, "tomar"):
			return false
	Acciones.tecla(escena, 1)
	return taller.mano == "destornillador" and taller.espacios_hud.size() == 8 and escena.carrito_cerca()


func preparar_resumen(escena: Node3D, critico: bool) -> bool:
	var motor: RefCounted = escena.motor
	if critico:
		motor.ejecutar("inspeccionar", "virtual", 27000)
		motor.ejecutar("ignorar_aviso_seguridad", "virtual", 13500)
		escena.mostrar_estado()
		return motor.fin() == "falta-critica"
	# Fija la referencia y los tiempos para que las capturas sean reproducibles.
	motor._intento_anterior = {"puntaje": 80, "errores": 3, "tiempo_ms": 312000}
	motor.marcar_causa("fusible-abierto")
	for paso in [["inspeccionar", 35000], ["inspeccionar", 26000], ["medir_continuidad", 60000],
			["confirmar_solucion", 70000], ["cambiar_foco_correcto", 15000], ["confirmar_solucion", 45595]]:
		motor.ejecutar(paso[0], "virtual", paso[1])
	if motor.registrar_diagnostico("foco-danado", "virtual", 12000).is_empty():
		return false
	if not motor.registrar_reflexion("Comprobaría el foco antes de confirmar la solución."):
		return false
	escena.mostrar_estado()
	return motor.metricas().puntaje == 92 and not motor.brechas().is_empty()


func preparar_flashcard(escena: Node3D, tipo: String) -> void:
	match tipo:
		"falta":
			escena.avisar("Necesitas: Foco de repuesto", tipo, "Te falta algo", escena.taller.ubicacion("foco"))
		"aviso":
			escena.avisar("Falta: Foco izquierdo repuesto", tipo, "Aún no puedes hacerlo")
		"error":
			escena.avisar("Revisa las lecturas reportadas y compáralas con el multímetro.",
				tipo, "Valor fuera de rango", "", "Banco de diagnóstico · lecturas reportadas")
		"critico":
			escena.avisar("Intentaste trabajar en los bajos sin ambos soportes trabados.",
				tipo, "Falta crítica", "", "Procedimiento de seguridad del elevador")


func preparar_elevador(escena: Node3D, vista: String) -> bool:
	var elevador := escena.get_node("Elevador")
	var bajos := escena.get_node("Bajos")
	escena.jugador.set_physics_process(false)
	escena.set_process(false)
	escena.set_physics_process(false)
	for ruta in ["Interfaz", "PistaControles", "AlineacionPanel", "AlternarPanel", "Mira", "Apuntado"]:
		escena.get_node(ruta).hide()
	for brazo in escena.jugador.camara.get_children():
		if brazo is Node3D and not brazo is RayCast3D:
			brazo.hide()
	elevador.colocar_calzas()
	elevador.mover(true, true)
	for soporte in elevador.trabas:
		elevador.cambiar_traba(soporte, true)
	if vista == "elevador-guia":
		escena.senalar_guia("consola_elevador")
		if not escena.taller.baliza.visible:
			return false
	if vista in ["elevador", "elevador-guia"]:
		escena.jugador.ubicar(Vector3(-10.7, 0.10, 6.9))
		escena.apuntar_jugador(Vector3(0, 2.54, 0.10))
	else:
		escena.jugador.ubicar(Vector3(-0.84, -1.05, -0.69))
		escena.apuntar_jugador(Vector3(0.46, 1.66, -2.78))
	var camara: Camera3D = escena.jugador.camara
	var puntos := [elevador.piezas.consola_elevador.global_position, Vector3(0, 3.8, 0)]
	if vista == "elevador-guia":
		puntos.append(escena.taller.baliza.global_position)
	if vista == "bajos":
		puntos = [bajos.piezas.neumatico_trasero_derecho.global_position,
			bajos.piezas.bolsa_trasero_derecho.global_position,
			bajos.piezas.amortiguador_trasero_derecho.global_position]
	for punto in puntos:
		if camara.is_position_behind(punto) or not camara.get_viewport().get_visible_rect().has_point(
				camara.unproject_position(punto)):
			return false
	return elevador.seguro() and bajos.visible


func preparar_taller(escena: Node3D, vista: String) -> bool:
	var taller: Node3D = escena.taller
	escena.jugador.set_physics_process(false)
	escena.get_node("PistaControles").hide()
	escena.get_node("AlineacionPanel").hide()
	escena.get_node("AlternarPanel").hide()
	escena.set_process(false)
	escena.get_node("Interfaz").visible = vista == "baliza"
	taller.cambiar_cajones(true, true)
	var posicion := Vector3(-5.35, 0.35, -3.4)
	var foco := Vector3(-5.35, 1.24, -8.02)
	if vista == "baliza":
		posicion = Vector3(-6.0, 0.35, -4.85)
		foco = taller.estanteria.global_position + Vector3.UP * 1.85
		escena.abrir_menu(taller.objetos.destornillador)
		escena.menu_pieza.botones[0].pressed.emit()
		escena.ejecutar("cambiar_foco_correcto", "virtual")
		if not escena.flashcard.visible or taller.baliza.visible:
			return false
		escena.flashcard.ok.pressed.emit()
		if taller.objetivo != "foco" or not taller.baliza.visible:
			return false
	escena.jugador.ubicar(posicion)
	escena.apuntar_jugador(foco)
	var camara: Camera3D = escena.jugador.camara
	var encuadre := camara.get_viewport().get_visible_rect()
	var puntos: Array[Vector3] = []
	if vista == "taller":
		for mueble in [taller.mesa, taller.caja_roja, taller.estanteria, taller.carrito]:
			puntos.append(mueble.global_position + Vector3.UP * 0.8)
		for objeto in taller.objetos.values():
			puntos.append(objeto.global_position)
	else:
		puntos.append(taller.objetos.foco.global_position)
		puntos.append(taller.baliza.global_position + Vector3.UP)
	for punto in puntos:
		if camara.is_position_behind(punto) or not encuadre.has_point(camara.unproject_position(punto)):
			return false
	return taller.cajones_abiertos


func comprobar_estado(escena: Node3D, sector: Node3D, vista: String) -> bool:
	var abierta := vista in ["abierto", "danado"]
	var dano := vista == "danado"
	var estado: Dictionary = escena.motor.estado()
	var angulo: float = sector.bisagra.rotation_degrees.y
	var led := sector.led.material_override as StandardMaterial3D
	print("Gabinete ", vista, ": bisagra=", sector.bisagra.global_position, " ángulo=", angulo,
		"° tornillo intacto=", sector.tornillo.visible, " fragmento=", sector.fragmento.visible,
		" chispa=", sector.chispa.visible, " LED=", sector.lectura, " ", led.emission)
	return estado.get("inspeccionado", false) == abierta and estado.get("tornillo_roto", false) == dano \
		and sector.abierta == abierta and is_equal_approx(angulo, 100.0 if abierta else 0.0) \
		and sector.tornillo.visible != dano and sector.fragmento.visible == dano and sector.chispa.visible == dano \
		and led.emission_enabled and (led.emission == sector.COLORES_LED.Rojo) == dano


func comprobar_encuadre(escena: Node3D, vista: String, menu: bool) -> bool:
	var camara: Camera3D = escena.jugador.camara
	if vista == "entrada":
		var cuadro := camara.get_viewport().get_visible_rect()
		for malla in escena.get_node("Autobus").find_children("*", "MeshInstance3D", true, false):
			for esquina in range(8):
				var punto: Vector3 = malla.global_transform * malla.get_aabb().get_endpoint(esquina)
				if camara.is_position_behind(punto) or not cuadro.has_point(camara.unproject_position(punto)):
					return false
		print("Autobús completo dentro de ", cuadro.size)
		return true
	return comprobar_pieza(escena, pieza_gabinete(vista, menu))


func pieza_gabinete(vista: String, menu: bool) -> String:
	if vista == "cerrado":
		return "compuerta"
	return "terminal" if menu and vista == "danado" else "monitor"


func comprobar_pieza(escena: Node3D, esperado: String) -> bool:
	var alcance: RayCast3D = escena.alcance
	alcance.force_raycast_update()
	var pieza := alcance.get_collider() as StaticBody3D
	if pieza == null or pieza.get("componente") != esperado:
		print("La mira alcanza ", pieza)
		return false
	var impacto := alcance.get_collision_point()
	print("Mira sobre ", pieza.get("nombre"), " en ", impacto,
		", distancia ", escena.jugador.camara.global_position.distance_to(impacto), " m")
	return true


func fallar(mensaje: String) -> void:
	printerr(mensaje)
	quit(1)
