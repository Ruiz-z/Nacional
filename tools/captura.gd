extends SceneTree

# Captura una escena a PNG con tamaño fijo (por defecto 1280x720):
# godot --path godot -s ../tools/captura.gd -- escenas/menu.tscn ../build/capturas/menu.png [ancho alto]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Uso: -- <escena res://> <salida.png> [ancho alto]")
		quit(1)
		return
	var tam := Vector2i(1280, 720)
	if args.size() >= 4:
		tam = Vector2i(int(args[2]), int(args[3]))
	var vp := SubViewport.new()
	vp.size = tam
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var paquete: PackedScene = load("res://" + args[0])
	vp.add_child(paquete.instantiate())
	await create_timer(1.5).timeout
	await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(args[1])
	print("guardado ", args[1], " ", img.get_size())
	quit(0)
