extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Ordenes = preload("res://logica/simulador/ordenes.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Mapa = preload("res://logica/aprendizaje/mapa_ruta.gd")
const VistaMapa = preload("res://escenas/mapa_ruta.gd")


static func ejecutar() -> bool:
	var motivos := [
		{"competencia": "hecha"}, {"competencia": "pendiente", "refuerzo": "Practica la medición."},
		{"competencia": "critica"}, {"competencia": "posterior"}, {"competencia": "reciente"},
	]
	var instantanea := {"hecha": {"dominio": 70.0}, "critica": {"dominio": 82.0},
		"pendiente": {"dominio": 65.0}, "reciente": {"dominio": 90.0}}
	var historial := [
		{"competencia": "critica", "tipo_error": "falta-critica", "sesion": 3},
		{"competencia": "pendiente", "tipo_error": "paso-omitido", "sesion": 4},
		{"competencia": "pendiente", "tipo_error": "paso-omitido", "sesion": 4},
		{"competencia": "pendiente", "tipo_error": "orden-incorrecto", "sesion": 4},
		{"competencia": "pendiente", "resultado": "incorrecto", "sesion": 4},
		{"competencia": "reciente", "tipo_error": "falta-critica", "sesion": 2},
		{"competencia": "reciente", "resultado": "correcto", "sesion": 3},
	]
	var catalogo := [
		{"id": "a", "titulo": "Primera orden"}, {"id": "b", "titulo": "Segunda orden"},
		{"id": "c", "titulo": "Tercera orden", "competencia": "reciente"}, {"id": "d", "titulo": "Cuarta orden"},
	]
	var sugerencias := {"pendiente": {"ordenes": ["inexistente", "b", "b", "a", "c", "d"]},
		"posterior": {"ordenes": ["inexistente"]}}
	var mapa := Mapa.armar(motivos, instantanea, historial, catalogo, sugerencias,
		{"pendiente": true, "critica": true, "hecha": true})
	return probar_detalles() and probar_fichas(mapa.slice(0, 4)) and Base.con_base(probar_panel) and mapa.map(func(nodo: Dictionary) -> String: return nodo.estado) == [
			"Primero", "Hecho", "Hoy", "Después", "Después"] \
		and mapa[0].competencia == "critica" and mapa[0].dominio == 82 \
		and mapa[0].errores[0].nombre == "Falta crítica" and mapa[0].errores[0].conteo == 1 \
		and mapa[1].errores[0].nombre == "Sin errores" and mapa[1].errores[0].conteo == 0 \
		and mapa[2].errores.map(func(rama: Dictionary) -> Array: return [rama.tipo_error, rama.conteo]) \
			== [["paso-omitido", 2], ["orden-incorrecto", 1], ["respuesta-incorrecta", 1]] \
		and mapa[2].ordenes == [catalogo[1], catalogo[0], catalogo[2]] \
		and mapa[2].refuerzo == "Practica la medición." and mapa[3].ordenes.is_empty() \
		and mapa[4].ordenes == [catalogo[2]] and mapa[4].competencia == "reciente"


static func probar_fichas(nodos: Array) -> bool:
	var nodo: Dictionary = nodos[2].duplicate(true)
	nodos[2] = nodo
	nodo.errores.append({"nombre": "Falta crítica", "tipo_error": "falta-critica", "conteo": 3})
	nodo.ordenes[0].marca = "Ejemplo didáctico"
	nodo.temas = [{"titulo": "Medición", "fuente": "Manual.pdf"}, {"titulo": "Fusibles"}]

	var vista := VistaMapa.new()
	var arbol := Engine.get_main_loop() as SceneTree
	arbol.root.add_child(vista)
	vista.mostrar(nodos, "ia", ["ejemplo didáctico, sin fuente oficial"], {"pendiente": {}})
	var fila: Dictionary = vista.conexiones[2]
	var izquierda: Array = fila.izquierda.map(nombre_ficha)
	var derecha: Array = fila.derecha.map(nombre_ficha)
	var colores: Array[Color] = []
	for conexion in vista.conexiones:
		var boton: Button = conexion.centro.get_child(0)
		var estilo := boton.get_theme_stylebox("normal") as StyleBoxFlat
		colores.append(estilo.bg_color)
	var critica: Button = fila.izquierda[0].get_child(0)
	var estilo_critica := critica.get_theme_stylebox("normal") as StyleBoxFlat
	var borde_critico := estilo_critica.border_color == Color("#D64545")
	var selecciones: Array = []
	vista.nodo_activado.connect(func(datos: Dictionary, tipo: String, boton: Button):
		selecciones.append([datos.competencia, tipo, boton.accessibility_name]))
	for lado in [fila.izquierda, fila.derecha]:
		var mas: Button = lado.back().get_child(0)
		mas.pressed.emit()
	var textos: Array[Node] = vista.find_children("*", "Label", true, false)
	var limpio := textos.all(func(rotulo: Label) -> bool:
		var texto := rotulo.text.to_lower()
		return not texto.contains("ejemplo didáctico") and not texto.contains("fuente:") \
			and not texto.contains("practica la medición."))
	vista.free()
	return limpio and borde_critico and izquierda == ["Falta crítica · 3", "Omitir un paso · 2", "Alterar el orden de los pasos · 1", "+1 más"] \
		and derecha == ["Medición", "Fusibles", "Segunda orden", "+2 más"] \
		and selecciones == [["pendiente", "competencia", "+1 más"], ["pendiente", "competencia", "+2 más"]] \
		and colores == [Color("#F2B705"), Color("#3FAE6A"), Color("#1AA7A6"), Color("#ECFAFA")]


static func nombre_ficha(ficha: Control) -> String:
	var boton := ficha.get_child(0) as Button
	return boton.accessibility_name


static func probar_detalles() -> bool:
	var competencia := "diagnostico-fallas"
	var historial := [
		{"competencia": competencia, "resultado": "incorrecto", "item": "pregunta", "respuesta": "1"},
		{"competencia": competencia, "resultado": "incorrecto", "item": "pregunta"},
		{"competencia": competencia, "resultado": "incorrecto", "item": "retirada"},
		{"competencia": competencia, "resultado": "incorrecto", "respuesta": "Continuar"},
		{"competencia": "seguridad-alto-voltaje", "resultado": "incorrecto", "item": "pregunta"},
	]
	var items := [{"id": "pregunta", "formato": "opcion-multiple", "pregunta": "¿Qué revisarías?",
		"opciones": ["El fusible", "El foco"], "correcta": 0}]
	var tema := {"titulo": "Fusibles", "fuente": "Manual.pdf", "explicacion": "Revisa la protección del circuito."}
	var orden := {"id": "a", "titulo": "Revisar faros", "dificultad": "facil", "archivo": "faros.json",
		"competencia": "Diagnóstico de fallas", "marca": "Ejemplo didáctico"}
	var nodos := Mapa.armar([{"competencia": competencia, "motivo": "Repasa el diagnóstico.",
		"refuerzo": "Practica la revisión."}], {}, historial, [orden],
		{competencia: {"temas": [tema]}}, {competencia: true})
	var nodo: Dictionary = nodos[0]
	var centro: Dictionary = Mapa.detalle(nodo, "competencia", historial, items)
	var error: Dictionary = Mapa.detalle(nodo.errores[0], "error", historial, items)
	var tema_detalle: Dictionary = Mapa.detalle(tema, "tema", historial, items)
	var orden_detalle: Dictionary = Mapa.detalle(orden, "orden", historial, items)
	var tema_sin_texto := Mapa.detalle({"titulo": "Fusibles", "fuente": "Manual.pdf"}, "tema", [], [])
	for tipo in Mapa.Ruta.NOMBRES_ERROR.keys() + Mapa.OTROS_ERRORES.keys():
		var registrado := Mapa.detalle({"nombre": tipo, "conteo": 1,
			"tipo_error": tipo, "competencia": competencia}, "error", [], [])
		if registrado.parrafos.size() != 3:
			return false
	return centro.titulo == "Diagnóstico de fallas" and centro.acciones[0].competencia == competencia \
		and "Repasa el diagnóstico." in centro.parrafos and "Practica la revisión." in centro.parrafos \
		and error.preguntas == [{"enunciado": "¿Qué revisarías?", "respuesta": "El foco", "correcta": "El fusible"},
			{"enunciado": "¿Qué revisarías?", "correcta": "El fusible"}, {"respuesta": "Continuar"}] \
		and tema_sin_texto.parrafos == ["Fuente: Manual.pdf"] \
		and tema_detalle.parrafos == [tema.explicacion, "Fuente: Manual.pdf"] \
		and orden_detalle.parrafos == ["Fácil", "Diagnóstico de fallas", "Ejemplo didáctico"] \
		and orden_detalle.acciones[0].archivo == "faros.json"


static func probar_panel(base: String) -> bool:
	var menu := Pantallas.abrir(base)
	var avance := Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", menu.perfil.id,
		"diagnostico", [], 0, int(Time.get_unix_time_from_system()))
	menu.actualizar()
	menu.botones.ruta.pressed.emit()
	var ruta: Node = menu.pantalla
	if not avance.guardado or ruta == null:
		menu.free()
		return false
	var catalogo_real: Array = Ordenes.listar().ordenes
	var fila := {}
	for candidata in ruta.roadmap_caja.conexiones:
		var boton: Button = candidata.centro.get_child(0)
		if catalogo_real.any(func(orden: Dictionary) -> bool: return orden.competencia == boton.accessibility_name):
			fila = candidata
			break
	if fila.is_empty():
		menu.free()
		return false
	var error: Button = fila.izquierda[0].get_child(0)
	var competencia: Button = fila.centro.get_child(0)
	var panel: PanelContainer = ruta.panel_detalle_mapa
	error.pressed.emit()
	var estilo := panel.get_theme_stylebox("panel") as StyleBoxFlat
	var estado: String = fila.centro.get_child(0).accessibility_description.get_slice(" · ", 0)
	var correcto: bool = panel.visible and panel.titulo.text == "Sin errores" and panel.cerrar_boton.has_focus() \
		and estilo.border_width_left == 1 and panel.estado_visible.text == estado \
		and panel.estado_visible.get_theme_color("font_color") == VistaMapa.ESTADOS[estado]
	competencia.pressed.emit()
	correcto = correcto and panel.visible and panel.titulo.text != "Sin errores"
	pulsar(menu.get_viewport(), KEY_ESCAPE)
	correcto = correcto and not panel.visible and competencia.has_focus()
	for tecla in [KEY_ENTER, KEY_SPACE]:
		pulsar(menu.get_viewport(), tecla)
		correcto = correcto and panel.visible and panel.cerrar_boton.has_focus()
		panel.cerrar_boton.pressed.emit()
		correcto = correcto and not panel.visible and competencia.has_focus()
	competencia.pressed.emit()
	var practicar: Button = panel.contenido.get_child(-1)
	practicar.pressed.emit()
	var nombre: String = panel.titulo.text
	var catalogo: Node = menu.pantalla
	correcto = correcto and catalogo != ruta
	if catalogo != ruta:
		correcto = correcto and Mapa.Banco.COMPETENCIAS.get(catalogo.competencia_filtro) == nombre \
			and not catalogo.catalogo.is_empty() \
			and catalogo.catalogo.all(func(orden: Dictionary) -> bool: return orden.competencia == nombre)
		menu.volver()
		correcto = correcto and menu.pantalla == ruta and competencia.has_focus()
	if correcto:
		var orden: Button = fila.derecha[0].get_child(0)
		orden.pressed.emit()
		var esperada: String = panel.titulo.text
		var iniciar: Button = panel.contenido.get_child(-1)
		iniciar.pressed.emit()
		var bus: Node = menu.pantalla
		correcto = bus != ruta and catalogo_real.any(func(entrada: Dictionary) -> bool:
			return entrada.archivo == bus.archivo and entrada.titulo == esperada)
		if correcto:
			bus.salida_solicitada.emit()
			correcto = menu.pantalla == ruta and orden.has_focus()
	menu.free()
	return correcto


static func pulsar(ventana: Viewport, tecla: Key) -> void:
	for estado in [true, false]:
		var evento := InputEventKey.new()
		evento.keycode = tecla
		evento.pressed = estado
		ventana.push_input(evento)
