extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Menu = preload("res://escenas/menu.tscn")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var esperado := {"admin": ["tablero", "materiales", "administracion"], "jefe": ["tablero", "materiales"],
		"tecnico": Recorrido.PASOS + ["materiales"]}
	var correcto := true
	for rol in esperado:
		correcto = Pantallas.entrar(menu, rol + "01", "clave-de-prueba", rol) and correcto
		var visibles: Array = menu.botones.keys().filter(func(paso: String) -> bool: return menu.botones[paso].visible)
		correcto = correcto and visibles == esperado[rol] \
			and menu.columna.get_node("Destacados").visible == (rol == "tecnico")
		# La tarjeta de materiales abre la página local con la dirección del servidor, sin lanzar procesos en la prueba.
		var roles_enviados := []
		menu.lanzar_materiales = func(rol_actual: String, usuario: String): roles_enviados.append([rol_actual, usuario])
		menu.botones.materiales.pressed.emit()
		correcto = correcto and roles_enviados == [[rol, rol + "01"]] and not menu.botones.materiales.disabled
		menu.botones.tablero.pressed.emit()
		correcto = correcto and menu.pantalla != null and menu.pantalla.perfil.rol == rol
		if rol == "jefe" and menu.pantalla != null:
			menu.pantalla.get_node("Vistas/Administracion").pressed.emit()
			correcto = correcto and menu.pantalla.lista == null and menu.pantalla.roles.item_count == 1
			menu.volver()
		menu.volver()
		menu.cerrar_sesion()
	menu.free()
	return correcto
