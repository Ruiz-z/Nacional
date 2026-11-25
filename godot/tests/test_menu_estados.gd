extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Menu = preload("res://escenas/menu.tscn")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func estado_de(menu: Node, paso: String) -> String:
	return menu.botones[paso].get_node("Contenido/Estado").text


# Los pasos que ya hiciste dicen «Completado», el que sigue «Siguiente» y los demás «Bloqueado».
static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var correcto := Pantallas.entrar(menu, "tecnico90", "clave-de-prueba", "tecnico")
	var ahora := int(Time.get_unix_time_from_system())
	correcto = correcto and estado_de(menu, "diagnostico") == "Siguiente" and estado_de(menu, "ruta") == "Bloqueado" \
		and estado_de(menu, "post") == "Bloqueado"
	var id: int = menu.perfil.id
	for paso in ["diagnostico", "ruta"]:
		correcto = correcto and Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", id, paso, [], 0, ahora).guardado
	menu.actualizar()
	correcto = correcto and estado_de(menu, "diagnostico") == "Completado" and estado_de(menu, "ruta") == "Completado" \
		and menu.botones.ruta.tooltip_text == "Ya completaste este paso." \
		and estado_de(menu, "escenario") == "Siguiente" and estado_de(menu, "post") == "Bloqueado" \
		and estado_de(menu, "retest") == "Bloqueado" and estado_de(menu, "tablero") == "Disponible"
	menu.free()
	return correcto
