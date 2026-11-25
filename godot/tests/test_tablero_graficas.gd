extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Demo = preload("res://logica/tablero/demo.gd")
const Texto = preload("res://tests/test_escena_64.gd")


static func ejecutar() -> bool:
	var directorio := OS.get_temp_dir().path_join("nacional-graficas-" + Crypto.new().generate_random_bytes(8).hex_encode())
	if DirAccess.make_dir_absolute(directorio) != OK:
		return false
	var base := directorio.path_join("datos.sqlite")
	var correcto := false
	if Base.Esquema.crear(base, Base.consultar) and Demo.precargar(base, Base.consultar):
		correcto = await comprobar(base)
	for archivo in DirAccess.get_files_at(directorio):
		DirAccess.remove_absolute(directorio.path_join(archivo))
	DirAccess.remove_absolute(directorio)
	return correcto


static func comprobar(base: String) -> bool:
	if Base.consultar(base, """
		INSERT INTO tecnico (alias, rol, clave_hash) VALUES
			('Técnico sin sesiones', 'tecnico', 'x'), ('Jefatura', 'jefe', 'x'), ('Admin', 'admin', 'x');
	""") == null:
		return false

	var arbol := Engine.get_main_loop() as SceneTree
	var ventana := SubViewport.new()
	ventana.size = Vector2i(1280, 720)
	arbol.root.add_child(ventana)
	var correcto := true
	for caso in [["tecnico", Demo.ALIAS, 4], ["tecnico", "Técnico sin sesiones", 4],
			["jefe", "Jefatura", 3], ["admin", "Admin", 3]]:
		var escena := Tablero.instantiate()
		escena.base = base
		escena.rol = caso[0]
		escena.alias_actual = caso[1]
		ventana.add_child(escena)
		await arbol.process_frame
		await arbol.process_frame
		var dashboard: Control = escena.datos.get_node("Dashboard")
		correcto = correcto and dashboard.bloques.size() == caso[2]
		match caso[0]:
			"tecnico":
				correcto = correcto and not Texto.leer(dashboard).contains("Jefatura")
				if caso[1] == Demo.ALIAS:
					correcto = correcto and not Texto.leer(dashboard).contains("Técnico sin sesiones") \
						and comprobar_interaccion(dashboard.bloques[0])
					escena.abrir_ficha("Técnico sin sesiones")
					correcto = correcto and escena.alias_ficha.is_empty()
				else:
					correcto = correcto and dashboard.bloques[0].vacio.text == "Completa el diagnóstico para ver tu dominio." \
						and not dashboard.bloques[0].has("grafica")
			"jefe":
				correcto = correcto and dashboard.bloques[0].datos.tipo == "mapa" \
					and dashboard.bloques[0].datos.filas.size() == 2
				escena.abrir_ficha(Demo.ALIAS)
				var ficha: Control = escena.datos.get_node("Dashboard")
				correcto = correcto and ficha.bloques.size() == 4 and ficha.bloques[0].datos.tipo == "barras" \
					and escena.get_node("Vistas/Exportar").visible
			"admin":
				correcto = correcto and dashboard.bloques[0].datos.filas[0].nombre == "Técnico sin sesiones" \
					and dashboard.bloques[1].datos.tipo == "apilada" and dashboard.bloques[2].datos.tipo == "medidor"
		escena.free()
	ventana.free()
	return correcto


static func comprobar_interaccion(bloque: Dictionary) -> bool:
	var grafica: Control = bloque.grafica
	var boton: Button = bloque.boton
	var tabla: GridContainer = bloque.tabla
	var texto := "Eléctrico y batería · Dominio · 66.7 % · Básico"
	var coincide: bool = grafica.marcas.any(func(marca: Dictionary) -> bool:
		return grafica._get_tooltip(marca.rect.get_center()) == texto)
	if not coincide or grafica.focus_mode != Control.FOCUS_ALL \
			or not grafica.accessibility_description.contains("flechas"):
		return false
	grafica.grab_focus()
	var tecla := InputEventAction.new()
	tecla.action = "ui_right"
	tecla.pressed = true
	grafica._gui_input(tecla)
	if not grafica.has_focus() or grafica.accessibility_description != grafica.marcas[0].texto:
		return false
	boton.grab_focus()
	boton.button_pressed = true
	var en_tabla := tabla.is_visible_in_tree() and not grafica.is_visible_in_tree() \
		and Texto.leer(tabla).contains("66.7 %") and boton.text == "Ver gráfica"
	boton.button_pressed = false
	return en_tabla and grafica.is_visible_in_tree() and not tabla.visible
