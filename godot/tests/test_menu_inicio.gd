extends RefCounted

const Menu = preload("res://escenas/menu.tscn")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")


static func ejecutar() -> bool:
	var correcto := true
	for tamano in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		correcto = await comprobar(tamano) and correcto
	return correcto


static func comprobar(tamano: Vector2i) -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var vista := SubViewport.new()
	vista.size = tamano
	arbol.root.add_child(vista)
	var menu := Menu.instantiate()
	menu.base = OS.get_temp_dir().path_join("nacional-menu-%s.sqlite" % Time.get_ticks_usec())
	vista.add_child(menu)
	var alta := Pantallas.preparar_cuenta(menu, "tecnico01", "clave-de-prueba", "tecnico")
	await arbol.process_frame
	await arbol.process_frame
	var formulario: Rect2 = menu.inicio.get_global_rect()
	var correcto: bool = alta.ok and menu.entrada_inicio.size == Vector2(tamano) \
		and formulario.size.x >= 300 and formulario.position.x >= 0 and formulario.end.x <= tamano.x \
		and menu.usuario.has_focus() and menu.usuario.get_global_rect().size.x > 200
	menu.enviar.grab_focus()
	var aceptar := InputEventJoypadButton.new()
	aceptar.button_index = JOY_BUTTON_A
	aceptar.pressed = true
	vista.push_input(aceptar)
	aceptar.pressed = false
	vista.push_input(aceptar)
	correcto = correcto and menu.perfil.get("alias") == "tecnico01" and not menu.botones.diagnostico.disabled
	DirAccess.remove_absolute(menu.base)
	vista.free()
	return correcto
