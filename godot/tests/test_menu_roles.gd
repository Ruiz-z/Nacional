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
	var esperado := {"admin": ["tablero", "administracion"], "jefe": ["tablero"], "tecnico": Recorrido.PASOS}
	var correcto := true
	for rol in esperado:
		correcto = Pantallas.entrar(menu, rol + "01", "clave-de-prueba", rol) and correcto
		var visibles: Array = menu.botones.keys().filter(func(paso: String) -> bool: return menu.botones[paso].visible)
		correcto = correcto and visibles == esperado[rol] \
			and menu.columna.get_node("Destacados").visible == (rol == "tecnico")
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
