extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Demo = preload("res://logica/tablero/demo.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Vista = preload("res://tests/test_escena_63.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if not Demo.precargar(base, Base.consultar):
		return false
	var tablero := Tablero.instantiate()
	tablero.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(tablero)
	tablero.get_node("Vistas/Instructor").pressed.emit()
	var texto := Vista.leer(tablero)
	var correcto: bool = tablero.lista.visible and tablero.lista.item_count == 1 \
		and texto.contains("Retest simulado 100") and texto.contains("Línea de tiempo") \
		and texto.contains("Ítem bateria-muestra-01") and texto.contains("Versión 1")
	tablero.free()
	return correcto
