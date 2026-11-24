extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Demo = preload("res://logica/tablero/demo.gd")
const Tablero = preload("res://escenas/tablero.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if not Demo.precargar(base, Base.consultar):
		return false
	var tablero := Tablero.instantiate()
	tablero.base = base
	tablero.alias_actual = Demo.ALIAS
	(Engine.get_main_loop() as SceneTree).root.add_child(tablero)
	var correcto := false
	for fila in tablero.datos.get_children():
		if fila is ProgressBar and fila.value > 0:
			correcto = true
	var texto := leer(tablero)
	correcto = correcto and texto.contains("[DEMO]") and texto.contains("Retención simulada")
	tablero.free()
	return correcto


static func leer(tablero: Node) -> String:
	var lineas := PackedStringArray()
	for fila in tablero.datos.get_children():
		if fila is Label:
			lineas.append(fila.text)
	return "\n".join(lineas)
