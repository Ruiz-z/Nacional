extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Texto = preload("res://tests/test_escena_64.gd")


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	Base.consultar(base, "INSERT INTO tecnico (alias, rol, clave_hash) VALUES
		('tecnico01', 'tecnico', 'x'), ('tecnico02', 'tecnico', 'x'),
		('jefe01', 'jefe', 'x'), ('admin01', 'admin', 'x');")
	var arbol := Engine.get_main_loop() as SceneTree
	var correcto := true
	for rol in ["tecnico", "jefe", "admin"]:
		var tablero := Tablero.instantiate()
		tablero.base = base
		tablero.rol = rol
		tablero.alias_actual = rol + "01"
		arbol.root.add_child(tablero)
		var exportar: Button = tablero.get_node("Vistas/Exportar")
		correcto = correcto and tablero.vista == rol and not exportar.visible
		match rol:
			"tecnico":
				tablero.cambiar_a("jefe")
				tablero.abrir_ficha("tecnico02")
				var texto := Texto.leer(tablero.datos)
				correcto = correcto and tablero.vista == rol and tablero.alias_ficha.is_empty() \
					and texto.contains("tecnico01") and not texto.contains("tecnico02") \
					and tablero.botones_tecnicos.is_empty() and not tablero.get_node("Vistas/JefeDirecto").visible
				tablero.exportar(base + ".json")
				correcto = correcto and not FileAccess.file_exists(base + ".json")
			"jefe":
				correcto = correcto and tablero.botones_tecnicos.keys() == ["tecnico01", "tecnico02"]
				tablero.abrir_ficha("tecnico02")
				correcto = correcto and exportar.visible and tablero.get_node("Vistas/Administracion").text == "Nuevo técnico"
			"admin":
				var texto := Texto.leer(tablero.datos)
				correcto = correcto and texto.contains("sin revisar por Volvo") and texto.contains("Sin respaldo") \
					and texto.contains("Servicio de IA sin configurar") and texto.contains("tecnico02")
				tablero.get_node("Vistas/Tecnico").pressed.emit()
				correcto = correcto and tablero.vista == "tecnico" and not exportar.visible
				tablero.get_node("Vistas/JefeDirecto").pressed.emit()
				tablero.abrir_ficha("tecnico02")
				correcto = correcto and tablero.vista == "jefe" and not exportar.visible
		tablero.free()
	return correcto
