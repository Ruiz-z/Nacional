extends RefCounted

const Menu = preload("res://escenas/menu.tscn")
const Alias = preload("res://logica/flujo/alias.gd")
const Base = preload("res://tests/base_tablero.gd")


static func ejecutar() -> bool:
	var base := OS.get_temp_dir().path_join("nacional-menu-%s.sqlite" % Time.get_ticks_usec())
	var correcto := true
	for tamano in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		correcto = await comprobar(tamano, base) and correcto
	DirAccess.remove_absolute(base)
	return correcto


static func comprobar(tamano: Vector2i, base: String) -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var vista := SubViewport.new()
	vista.size = tamano
	arbol.root.add_child(vista)
	var menu := Menu.instantiate()
	menu.base = base
	vista.add_child(menu)
	await arbol.process_frame
	await arbol.process_frame
	var scroll: ScrollContainer = menu.entrada_inicio
	var barra := scroll.get_v_scroll_bar()
	var heroe: Control = menu.columna.get_node("Hero/Margen/Fila")
	var correcto: bool = scroll.size == Vector2(tamano) 		and heroe.size.x <= 1160 and heroe.size.x >= 1100 		and vista.get_visible_rect().encloses(menu.inicio.get_global_rect()) 		and barra.max_value > barra.page
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_DOWN
	rueda.pressed = true
	rueda.position = Vector2(28, 300)
	vista.push_input(rueda, true)
	correcto = correcto and scroll.scroll_vertical > 0
	menu.recorrido.get_node("Demo").grab_focus()
	await arbol.process_frame
	correcto = correcto and scroll.get_v_scroll_bar().value > 0
	var alias := "T-%s" % tamano.x
	var alta := Alias.alta(base, alias, Base.consultar)
	menu.inicio.get_node("Alias").text = alias
	var entrar: Button = menu.inicio.get_node("Elegir")
	entrar.grab_focus()
	await arbol.process_frame
	await arbol.process_frame
	var aceptar := InputEventJoypadButton.new()
	aceptar.button_index = JOY_BUTTON_A
	aceptar.pressed = true
	vista.push_input(aceptar)
	aceptar.pressed = false
	vista.push_input(aceptar)
	correcto = correcto and alta.ok and menu.perfil.get("alias") == alias 		and not menu.botones.diagnostico.disabled
	if not correcto:
		printerr("Menú %s: área %s, héroe %s, scroll %.0f/%.0f, alias %s" % [
			tamano, scroll.size, heroe.size, barra.value, barra.max_value - barra.page, menu.perfil])
	vista.free()
	return correcto
