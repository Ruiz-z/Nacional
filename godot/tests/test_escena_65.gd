extends RefCounted

const Tablero = preload("res://escenas/tablero.tscn")
const Vista = preload("res://tests/test_escena_63.gd")

static func ejecutar() -> bool:
	var tablero := Tablero.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(tablero)
	tablero.get_node("Vistas/Ayuda").button_pressed = true
	var texto := Vista.leer(tablero)
	var correcto := texto.contains("Dominio =") and texto.contains("Retención simulada =")
	tablero.free()
	return correcto
