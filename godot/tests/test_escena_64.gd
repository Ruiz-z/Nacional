extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Demo = preload("res://logica/tablero/demo.gd")
const Tablero = preload("res://escenas/tablero.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if not Demo.precargar(base, Base.consultar) or Base.consultar(base,
			"INSERT INTO tecnico(alias, clave_hash) VALUES ('A-01', 'x');
			INSERT INTO intento(tecnico, competencia, item, formato, dificultad, respuesta, valor, peso,
				resultado, tipo_error, tiempo_ms, fuente_entrada, momento, reloj_sim, version_contenido)
			SELECT id, 'seguridad-alto-voltaje', 'aislar', 'escenario', 'media', 'aislar',
				0, 3, 'incorrecto', 'falta-critica', 1, 'virtual', 'practica', '2026-01-10', '1'
			FROM tecnico WHERE alias = 'A-01';") == null:
		return false
	var tablero := Tablero.instantiate()
	tablero.base = base
	tablero.rol = "jefe"
	(Engine.get_main_loop() as SceneTree).root.add_child(tablero)
	var jefe: Button = tablero.get_node("Vistas/JefeDirecto")
	var texto_lista := leer(tablero.datos)
	var correcto: bool = not jefe.visible and tablero.jefe_directo and tablero.botones_tecnicos.keys() == ["A-01", Demo.ALIAS] \
		and texto_lista.contains("Con falta crítica") and texto_lista.contains("Última actividad")
	tablero.botones_tecnicos[Demo.ALIAS].pressed.emit()
	var historial: CheckButton = tablero.datos.get_node("AbrirHistorial")
	historial.button_pressed = true
	var texto_ficha := leer(tablero.datos)
	correcto = correcto and tablero.get_node("Vistas/Exportar").visible \
		and texto_ficha.contains("3 respuestas") and texto_ficha.contains("1 error en 3 oportunidades") \
		and texto_ficha.contains("La decisión de avance es del jefe directo.") \
		and texto_ficha.contains("Retest simulado 100") and texto_ficha.contains("Línea de tiempo") \
		and texto_ficha.contains("Pregunta bateria-muestra-01") and texto_ficha.contains("Versión 1")
	var destino := base + ".json"
	tablero.exportar(destino)
	var archivo: Variant = JSON.parse_string(FileAccess.get_file_as_string(destino))
	correcto = correcto and archivo is Dictionary and archivo.tecnicos.size() == 1 \
		and archivo.tecnicos[0].alias == Demo.ALIAS
	tablero.get_node("AvisoExportacion").hide()
	tablero.get_node("Vistas/VolverLista").pressed.emit()
	correcto = correcto and tablero.botones_tecnicos.has(Demo.ALIAS) \
		and tablero.botones_tecnicos[Demo.ALIAS].has_focus()
	tablero.free()
	return correcto


static func leer(nodo: Node) -> String:
	if nodo is Control and not nodo.visible:
		return ""
	var texto: String = nodo.text if nodo is Label else ""
	for hijo in nodo.get_children():
		texto += "\n" + leer(hijo)
	return texto
