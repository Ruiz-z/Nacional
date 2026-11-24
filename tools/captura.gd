extends SceneTree

# Uso: godot --path godot -s ../tools/captura.gd -- escenas/bus.tscn ../build/capturas/bus.png
# Argumentos opcionales: [ancho alto [x y z yaw [pitch] [entrada|cerrado|abierto|danado]]] [menu] [--verificar]
func _initialize() -> void:
	call_deferred("capturar")


func capturar() -> void:
	var args := OS.get_cmdline_user_args()
	var verificar := args.size() > 0 and args[-1] == "--verificar"
	if verificar:
		args.remove_at(args.size() - 1)
	var menu := args.size() > 2 and args[-1] == "menu"
	if menu:
		args.remove_at(args.size() - 1)
	var vista := ""
	if args.size() >= 9 and args[-1] in ["entrada", "cerrado", "abierto", "danado"]:
		vista = args[-1]
		args.remove_at(args.size() - 1)
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
	var paquete := load("res://" + args[0]) as PackedScene
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
	vp.add_child(escena)

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
			var id := "compuerta" if vista == "cerrado" else "monitor"
			var objetivo: Vector3 = camara.to_local(sector.piezas[id].global_position)
			camara.rotation.x = atan2(objetivo.y, -objetivo.z)
		print("Cámara ", camara.global_position, ", giro ", args[7], "°, inclinación ", camara.rotation_degrees.x, "°")
	if not vista.is_empty():
		if escena.motor == null:
			fallar("El simulador no se inicializó.")
			return
		if vista in ["abierto", "danado"]:
			escena.ejecutar("inspeccionar", "teclado")
		if vista == "danado":
			escena.ejecutar("forzar_pieza", "teclado")
		if not comprobar_estado(escena, sector, vista):
			fallar("El estado del gabinete no corresponde a la vista %s." % vista)
			return
		if vista == "entrada":
			escena.get_node("Interfaz").hide()
			escena.get_node("AlineacionPanel").hide()
			escena.get_node("AlternarPanel").hide()
			escena.set_process(false)
		await physics_frame
		await physics_frame
		if not comprobar_encuadre(escena, vista):
			fallar("El encuadre no corresponde a la vista %s." % vista)
			return
		var triangulos := 0
		for nodo in escena.find_children("*", "MeshInstance3D", true, false):
			if nodo.mesh != null:
				triangulos += int(nodo.mesh.get_faces().size() / 3.0)
		print("Triángulos de malla (incluidas herramientas ocultas): ", triangulos)
		if triangulos >= 80000:
			fallar("La escena supera el presupuesto de triángulos.")
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


func comprobar_encuadre(escena: Node3D, vista: String) -> bool:
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
	var alcance: RayCast3D = escena.alcance
	alcance.force_raycast_update()
	var pieza := alcance.get_collider() as StaticBody3D
	var esperado := "compuerta" if vista == "cerrado" else "monitor"
	if pieza == null or pieza.get("componente") != esperado:
		print("La mira alcanza ", pieza)
		return false
	var impacto := alcance.get_collision_point()
	print("Mira sobre ", pieza.get("nombre"), " en ", impacto,
		", distancia ", camara.global_position.distance_to(impacto), " m")
	return true


func fallar(mensaje: String) -> void:
	printerr(mensaje)
	quit(1)
