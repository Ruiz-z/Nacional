extends SceneTree

# Captura una escena a PNG: godot --path godot -s ../tools/captura.gd -- escenas/menu.tscn ../build/capturas/menu.png
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Uso: -- <escena res://> <salida.png>")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var paquete: PackedScene = load("res://" + args[0])
	root.add_child(paquete.instantiate())
	await create_timer(1.2).timeout
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(args[1])
	print("guardado ", args[1])
	quit(0)
