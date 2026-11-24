extends SceneTree

# Uso: godot --path godot -s ../tools/captura.gd -- escenas/bus.tscn ../build/capturas/bus.png
# Argumentos opcionales: [ancho alto [x y z yaw_grados [abierto|danado]]]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [2, 4, 8, 9]:
		fallar("Uso: -- <escena res://> <salida.png> [ancho alto [x y z yaw_grados [abierto|danado]]]")
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
	if args.size() >= 8:
		for indice in range(4, 8):
			if not args[indice].is_valid_float() or not is_finite(float(args[indice])):
				fallar("La posición y el giro deben ser números finitos.")
				return
	if args.size() == 9 and args[8] not in ["abierto", "danado"]:
		fallar("El estado debe ser abierto o danado.")
		return
	if DisplayServer.get_name() == "headless":
		fallar("La captura requiere un servidor gráfico.")
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
	vp.add_child(escena)
	if args.size() >= 8:
		var jugador := escena.get_node_or_null("Jugador") as CharacterBody3D
		if jugador == null:
			fallar("La escena no tiene un nodo Jugador.")
			return
		jugador.set_physics_process(false)
		jugador.position = Vector3(float(args[4]), float(args[5]), float(args[6]))
		jugador.rotation_degrees.y = float(args[7])
		if args.size() == 9:
			escena.ejecutar("inspeccionar", "teclado")
			if args[8] == "danado":
				escena.ejecutar("forzar_pieza", "teclado")
	await create_timer(1.5).timeout
	await process_frame
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		fallar("El renderizador no produjo una imagen.")
		return
	var resultado := img.save_png(args[1])
	if resultado != OK:
		fallar("No se pudo guardar %s (%s)." % [args[1], error_string(resultado)])
		return
	print("guardado ", args[1], " ", img.get_size())
	quit(0)


func fallar(mensaje: String) -> void:
	printerr(mensaje)
	quit(1)
