extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Taller = preload("res://tests/acciones_taller.gd")
const Menu = preload("res://escenas/menu.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var control := InputEventJoypadButton.new()
	control.button_index = JOY_BUTTON_A
	var correcto: bool = InputMap.event_is_action(control, "ui_accept")
	correcto = correcto and menu.botones.values().all(func(boton: Button) -> bool: return boton.disabled) \
		and menu.etapa == "primer-admin"
	correcto = Pantallas.entrar(menu, "tecnico73") and correcto
	correcto = correcto and not menu.botones.diagnostico.disabled and menu.botones.ruta.disabled
	correcto = correcto and menu.inicio.get_node("Siguiente").text.contains("Diagnóstico")
	menu._process(0.0)
	correcto = correcto and menu.barra.get_node("Entrada").text == "Panel virtual"
	menu.conexion.iniciar_panel(Time.get_ticks_msec() - 3000)
	menu._process(0.0)
	correcto = correcto and menu.barra.get_node("Entrada").text.contains("Panel desconectado")
	menu.cerrar_sesion()
	menu.demo_boton.pressed.emit()
	correcto = correcto and menu.pantalla != null and not menu.inicio.visible
	menu.pantalla.get_node("Tablero").pressed.emit()
	correcto = correcto and menu.pantalla.alias_actual.begins_with("[DEMO]")
	menu.get_node("Marco/Volver").pressed.emit()
	correcto = correcto and menu.inicio.visible and menu.perfil.is_empty()
	menu.usuario.text = "tecnico73"
	menu.clave.text = "clave-de-prueba"
	menu.enviar.pressed.emit()
	correcto = correcto and menu.perfil.get("alias") == "tecnico73"
	var raiz := menu.get_tree().root
	menu.abrir_bus(menu.perfil.merged({"base": base}))
	menu.pantalla.flashcard.confirmar()
	Taller.vestir(menu.pantalla)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	raiz.push_input(esc)
	correcto = correcto and is_instance_valid(menu.pantalla) and not menu.inicio.visible
	raiz.push_input(esc)
	correcto = correcto and menu.pantalla == null and menu.inicio.visible
	menu.conexion.reanudar()
	menu.abrir_bus(menu.perfil.merged({"base": base}))
	var bus: Node3D = menu.pantalla
	bus.flashcard.confirmar()
	Taller.vestir(bus)
	for id in bus.datos.ruta_ideal:
		if not Taller.equipar(bus, id):
			correcto = false
			break
		bus.ejecutar(id, "virtual")
	correcto = correcto and Taller.cerrar_orden(bus) and bus.resumen.visible
	raiz.push_input(esc)
	correcto = correcto and menu.pantalla == null and menu.inicio.visible
	menu.free()
	return correcto
