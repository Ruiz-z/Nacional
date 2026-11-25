extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Ordenes = preload("res://logica/simulador/ordenes.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Mapa = preload("res://logica/aprendizaje/mapa_ruta.gd")


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
	return probar_detalles() and Base.con_base(probar_panel) and mapa.map(func(nodo: Dictionary) -> String: return nodo.estado) == [
			"Primero", "Hecho", "Hoy", "Después", "Después"] \
		and mapa[0].competencia == "critica" and mapa[0].dominio == 82 \
		and mapa[0].errores[0].nombre == "Falta crítica" and mapa[0].errores[0].conteo == 1 \
		and mapa[1].errores[0].nombre == "Sin errores" and mapa[1].errores[0].conteo == 0 \
		and mapa[2].errores.map(func(rama: Dictionary) -> Array: return [rama.tipo_error, rama.conteo]) \
			== [["paso-omitido", 2], ["orden-incorrecto", 1], ["respuesta-incorrecta", 1]] \
		and mapa[2].ordenes == [catalogo[1], catalogo[0], catalogo[2]] \
		and mapa[2].refuerzo == "Practica la medición." and mapa[3].ordenes.is_empty() \
		and mapa[4].ordenes == [catalogo[2]] and mapa[4].competencia == "reciente"


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
	var fila: HBoxContainer
	for candidata in ruta.roadmap_caja.filas.get_children().slice(1):
		var boton: Button = candidata.get_child(1).get_child(0).get_child(0)
		if catalogo_real.any(func(orden: Dictionary) -> bool: return orden.competencia == boton.accessibility_name):
			fila = candidata
			break
	if fila == null:
		menu.free()
		return false
	var error: Button = fila.get_child(0).get_child(0).get_child(0)
	var competencia: Button = fila.get_child(1).get_child(0).get_child(0)
	var panel: PanelContainer = ruta.panel_detalle_mapa
	error.pressed.emit()
	var correcto: bool = panel.visible and panel.titulo.text == "Sin errores" and panel.cerrar_boton.has_focus()
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
		var orden: Button = fila.get_child(2).get_child(0).get_child(0)
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
