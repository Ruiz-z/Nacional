extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Demo = preload("res://escenas/modo_demo.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var demo := Demo.instantiate()
	demo.base_real = base
	(Engine.get_main_loop() as SceneTree).root.add_child(demo)
	var correcto: bool = demo.perfil.base != base and demo.get_node("Estado").text.contains("+0 días")
	demo.get_node("Adelantar").pressed.emit()
	correcto = correcto and demo.get_node("Estado").text.contains("+7 días")
	demo.get_node("Restablecer").pressed.emit()
	correcto = correcto and demo.get_node("Estado").text.contains("+0 días")
	demo.free()
	return correcto and Base.consultar(base, "SELECT * FROM tecnico;").is_empty()
