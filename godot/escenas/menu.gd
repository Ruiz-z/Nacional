extends Control

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal paso_solicitado(paso: String, perfil: Dictionary)

const Banco = preload("res://logica/competencias/banco.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Esquema = preload("res://logica/datos/esquema.gd")
const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const Tablero = preload("res://escenas/tablero.tscn")
const Ordenes = preload("res://escenas/ordenes.tscn")
const Bus = preload("res://escenas/bus.tscn")
const Demo = preload("res://escenas/modo_demo.tscn")
const Diagnostico = preload("res://escenas/diagnostico.tscn")
const Ruta = preload("res://escenas/ruta.tscn")
const Evaluacion = preload("res://escenas/evaluacion.tscn")
const NOMBRES := {"alias": "Elegir alias", "diagnostico": "Diagnóstico", "ruta": "Ruta de aprendizaje",
	"escenario": "Práctica", "post": "Evaluación", "retest": "Repetir la evaluación", "tablero": "Tablero"}

var base := "user://nacional.sqlite"
var perfil := {}
var banco_aprendizaje := {}
var conexion := Conexion.new()
var pantalla: Node
var ruta_en_pausa: Control
var inicio_practica_mapa := 0
var botones := {}
var destacados := {}
@onready var entrada_inicio: ScrollContainer = $Marco/EntradaInicio
@onready var columna := $Marco/EntradaInicio/Columna
@onready var barra := columna.get_node("Barra/Margen/Fila")
@onready var texto_hero := columna.get_node("Hero/Margen/Fila/Texto")
@onready var inicio := columna.get_node("Hero/Margen/Fila/Tarjeta/Inicio")
@onready var recorrido := columna.get_node("Recorrido/Margen/Contenido")


func _ready() -> void:
	if "--verificar-contenido" in OS.get_cmdline_user_args():
		verificar_contenido()
		return
	var disponible := Esquema.crear(base)
	inicio.get_node("Alta").disabled = not disponible
	inicio.get_node("Elegir").disabled = not disponible
	inicio.get_node("Alta").pressed.connect(func(): seleccionar_alias(true))
	inicio.get_node("Elegir").pressed.connect(func(): seleccionar_alias(false))
	inicio.get_node("Alias").placeholder_text = "Ejemplo: T-0001"
	inicio.get_node("Alias").text_submitted.connect(func(_texto: String): seleccionar_alias(false))
	$Marco/Volver.pressed.connect(volver)
	preparar_inicio(disponible)
	actualizar()
	enfocar_inicio()
	if not disponible:
		inicio.get_node("Aviso").text = "No se pudo abrir tu progreso. Cierra el juego y ábrelo de nuevo."


func preparar_inicio(disponible: bool) -> void:
	var foto := "res://assets/ui/hero.png"
	if ResourceLoader.exists(foto, "Texture2D"):
		columna.get_node("Hero/Foto").texture = load(foto)
	var logo: Control = barra.get_node("Logo")
	logo.draw.connect(dibujar_icono.bind(logo, "logo"))
	var acciones := texto_hero.get_node("Acciones")
	acciones.get_node("IrAlias").disabled = not disponible
	acciones.get_node("IrAlias").pressed.connect(entrar_desde_hero)
	acciones.get_node("DemoHero").pressed.connect(abrir_demo)
	recorrido.get_node("Demo").pressed.connect(abrir_demo)
	var fichas := columna.get_node("Destacados/Tarjetas")
	for datos in [
		["diagnostico", "Diagnóstico", "Contesta preguntas para saber qué necesitas practicar."],
		["ruta", "Ruta de aprendizaje", "Repasa los temas que te faltan según tu diagnóstico."],
		["escenario", "Práctica en el taller", "Resuelve fallas en el autobús eléctrico."]
	]:
		var tarjeta := crear_tarjeta(datos[0], datos[1], datos[2], true)
		fichas.add_child(tarjeta)
		destacados[datos[0]] = tarjeta
	for indice in Recorrido.PASOS.size():
		var paso: String = Recorrido.PASOS[indice]
		var boton := crear_tarjeta(paso, NOMBRES[paso], "", false)
		recorrido.get_node("Pasos").add_child(boton)
		boton.get_node("Contenido/Insignia").text = "%02d" % (indice + 1)
		botones[paso] = boton
	entrada_inicio.resized.connect(ajustar_margenes)
	texto_hero.resized.connect(ajustar_titulo)
	ajustar_margenes()


func entrar_desde_hero() -> void:
	var campo: LineEdit = inicio.get_node("Alias")
	if campo.text.strip_edges().is_empty():
		campo.grab_focus()
	else:
		seleccionar_alias(false)


func ajustar_margenes() -> void:
	var margen := maxi(24, int((entrada_inicio.size.x - 1160.0) / 2.0))
	for ruta in ["Barra/Margen", "Hero/Margen", "Destacados", "Recorrido/Margen"]:
		var contenedor: MarginContainer = columna.get_node(ruta)
		contenedor.add_theme_constant_override("margin_left", margen)
		contenedor.add_theme_constant_override("margin_right", margen)


func ajustar_titulo() -> void:
	for nombre in ["Titulo", "Acento"]:
		var etiqueta: Label = texto_hero.get_node(nombre)
		var fuente := etiqueta.get_theme_font("font")
		var ancho := fuente.get_string_size(etiqueta.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 56).x
		etiqueta.add_theme_font_size_override("font_size",
			clampi(int(56.0 * texto_hero.size.x / ancho), 34, 56))


func crear_tarjeta(paso: String, titulo: String, detalle: String, destacada: bool) -> Button:
	var boton := Button.new()
	boton.name = paso
	boton.theme_type_variation = &"BotonPetroleo" if destacada else &"BotonClaro"
	boton.accessibility_name = titulo
	boton.custom_minimum_size.y = 148 if destacada else 122
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.pressed.connect(abrir_paso.bind(paso))
	var contenido := VBoxContainer.new()
	contenido.name = "Contenido"
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(contenido)
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenido.offset_left = 16
	contenido.offset_top = 12
	contenido.offset_right = -16
	if destacada:
		var icono := Control.new()
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.custom_minimum_size = Vector2(38, 38)
		icono.draw.connect(dibujar_icono.bind(icono, paso))
		contenido.add_child(icono)
	else:
		var insignia := Label.new()
		insignia.name = "Insignia"
		insignia.theme_type_variation = &"Insignia"
		insignia.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		contenido.add_child(insignia)
	var encabezado := Label.new()
	encabezado.theme_type_variation = &"Seccion"
	encabezado.text = titulo
	encabezado.add_theme_font_size_override("font_size", 20)
	if not destacada:
		encabezado.add_theme_color_override("font_color", Color("#1A2327"))
	contenido.add_child(encabezado)
	var descripcion := Label.new()
	descripcion.name = "Estado"
	descripcion.theme_type_variation = &"Secundario" if destacada else &"DetalleClaro"
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descripcion.text = detalle
	contenido.add_child(descripcion)
	return boton


func dibujar_icono(icono: Control, paso: String) -> void:
	var tinta := Color("#0E1A22")
	var turquesa := Color("#1AA7A6")
	var centro := Vector2(19, 19)
	if paso == "logo":
		var caja := StyleBoxFlat.new()
		caja.bg_color = turquesa
		caja.set_corner_radius_all(7)
		icono.draw_style_box(caja, Rect2(Vector2.ZERO, Vector2(38, 38)))
		for indice in 8:
			var radio := Vector2.RIGHT.rotated(indice * TAU / 8.0)
			icono.draw_line(centro + radio * 8, centro + radio * 13, tinta, 4, true)
		icono.draw_arc(centro, 8, 0, TAU, 24, tinta, 4, true)
		return
	icono.draw_circle(centro, 19, turquesa, true, -1.0, true)
	match paso:
		"diagnostico":
			icono.draw_polyline(PackedVector2Array([Vector2(7, 19), Vector2(13, 19),
				Vector2(17, 11), Vector2(22, 27), Vector2(25, 19), Vector2(31, 19)]), tinta, 2, true)
		"ruta":
			icono.draw_polyline(PackedVector2Array([Vector2(11, 26), Vector2(11, 16),
				Vector2(26, 16), Vector2(26, 10)]), tinta, 2, true)
			icono.draw_circle(Vector2(11, 26), 3, tinta)
			icono.draw_circle(Vector2(26, 10), 3, tinta)
		"escenario":
			icono.draw_line(Vector2(11, 27), Vector2(23, 15), tinta, 5, true)
			icono.draw_arc(Vector2(23, 15), 6, 0, PI * 1.5, 16, tinta, 3, true)


func verificar_contenido() -> void:
	var banco := Banco.cargar()
	var escenario := Escenario.cargar(Escenario.AISLAMIENTO)
	if not banco.errores.is_empty() or banco.items.is_empty() or not escenario.errores.is_empty():
		printerr("No se pudo verificar el contenido. Banco: ", banco.errores,
			" · Escenario: ", escenario.errores)
		get_tree().quit(1)
		return
	print("OK: banco (", banco.items.size(), " ítems) y escenario ", escenario.escenario.id)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	conexion.actualizar(Time.get_ticks_msec())
	barra.get_node("Entrada").text = conexion.etiqueta()


func seleccionar_alias(alta: bool) -> void:
	var entrada: String = inicio.get_node("Alias").text
	var seleccion := Alias.alta(base, entrada) if alta else Alias.elegir(base, entrada)
	if seleccion.ok:
		perfil = seleccion
		actualizar()
		enfocar_inicio()
	else:
		inicio.get_node("Aviso").text = seleccion.mensaje


func actualizar() -> void:
	var estado := Recorrido.estado(base, perfil.get("id", 0), int(Time.get_unix_time_from_system()))
	var siguiente: String = estado.get("siguiente", "alias")
	barra.get_node("Perfil").text = "Técnico · %s" % TextoLimpio.linea(perfil.get("alias", "Sin alias"))
	inicio.get_node("Siguiente").text = "Siguiente paso · %s" % NOMBRES[siguiente]
	var razon: String = estado.get("aviso", "")
	inicio.get_node("Aviso").text = razon if not razon.is_empty() else (
		"Entra con tu alias para empezar el diagnóstico." if perfil.is_empty()
		else "Sigue con esta actividad: %s. También puedes abrir una práctica libre." % NOMBRES[siguiente]
			if siguiente != "escenario" else "Sigue con esta actividad: %s." % NOMBRES[siguiente])
	for paso in botones:
		var boton: Button = botones[paso]
		boton.disabled = paso not in estado.get("habilitados", []) \
			and not (paso == "retest" and siguiente == "retest") \
			and not (paso == "escenario" and not perfil.is_empty())
		var estado_paso := "Bloqueado"
		if not boton.disabled:
			if paso == siguiente:
				estado_paso = "Siguiente"
			elif paso == "escenario":
				estado_paso = "Práctica libre"
			else:
				estado_paso = "Disponible"
		boton.get_node("Contenido/Estado").text = estado_paso
		boton.accessibility_description = estado_paso
		boton.get_node("Contenido").modulate.a = 0.76 if boton.disabled else 1.0
		if destacados.has(paso):
			destacados[paso].disabled = boton.disabled
			destacados[paso].get_node("Contenido").modulate.a = 0.72 if boton.disabled else 1.0
		boton.tooltip_text = ("Selecciona un alias para empezar." if perfil.is_empty() else
			"Completa el paso anterior para abrir esta actividad.") if boton.disabled else razon


func enfocar_inicio() -> void:
	var siguiente: String = Recorrido.estado(base, perfil.get("id", 0),
		int(Time.get_unix_time_from_system())).get("siguiente", "alias")
	var boton: Control = botones.get(siguiente, inicio.get_node("Alias"))
	if not (boton is Button and boton.disabled):
		boton.grab_focus()
	# Enfocar un control desplaza el scroll; la barra superior debe verse al entrar.
	var desplazable := get_node_or_null("Marco/EntradaInicio") as ScrollContainer
	if desplazable != null:
		desplazable.set_deferred("scroll_vertical", 0)


func abrir_paso(paso: String) -> void:
	if not botones.has(paso) or botones[paso].disabled:
		return
	match paso:
		"escenario":
			abrir_ordenes(perfil.merged({"base": base}))
		"tablero":
			abrir_tablero({"base": base, "alias": perfil.alias, "rol": perfil.get("rol", "")})
		"diagnostico", "ruta", "post", "retest":
			paso_solicitado.emit(paso, perfil.duplicate())
			var recurso := {"diagnostico": Diagnostico, "ruta": Ruta}.get(paso, Evaluacion) as PackedScene
			var actividad := recurso.instantiate()
			actividad.actividad.base = base
			actividad.actividad.perfil = perfil
			actividad.actividad.paso = paso
			actividad.banco = banco_aprendizaje
			if paso in ["post", "retest"]:
				actividad.titulo_preparado = NOMBRES[paso]
			actividad.finalizada.connect($Marco/Volver.grab_focus)
			actividad.ruta_cerrada.connect(volver)
			actividad.practica_mapa_solicitada.connect(practicar_desde_ruta)
			abrir(actividad)
			if actividad.item.is_empty():
				$Marco/Volver.grab_focus()


func abrir_demo() -> void:
	var demo := Demo.instantiate()
	demo.base_real = base
	demo.tablero_solicitado.connect(abrir_tablero)
	demo.escenario_solicitado.connect(abrir_ordenes)
	abrir(demo)


func abrir_tablero(tecnico: Dictionary) -> void:
	var tablero := Tablero.instantiate()
	tablero.base = tecnico.base
	tablero.alias_actual = tecnico.alias
	tablero.rol = tecnico.get("rol", "")
	abrir(tablero)


func practicar_desde_ruta(accion: Dictionary) -> void:
	ruta_en_pausa = pantalla
	inicio_practica_mapa = Time.get_ticks_msec()
	ruta_en_pausa.hide()
	pantalla = null
	var tecnico := perfil.merged({"base": base})
	var archivo: String = accion.get("archivo", "")
	if archivo.is_empty():
		abrir_ordenes(tecnico, accion.get("competencia", ""))
	else:
		abrir_bus(tecnico, archivo)


func abrir_ordenes(tecnico: Dictionary, competencia: String = "") -> void:
	var ordenes := Ordenes.instantiate()
	ordenes.tecnico = tecnico
	ordenes.competencia_filtro = competencia
	ordenes.orden_elegida.connect(func(archivo: String): abrir_bus(tecnico, archivo))
	abrir(ordenes)


func abrir_bus(tecnico: Dictionary, archivo: String = Escenario.AISLAMIENTO) -> void:
	var bus := Bus.instantiate()
	bus.archivo = archivo
	if tecnico.base == base:
		bus.resultados_registrados.connect(func():
			var cierre := Recorrido.cerrar_escenario(base, tecnico.id, bus.motor.fin(),
				int(Time.get_unix_time_from_system()))
			if not cierre.is_empty():
				if not cierre.guardado:
					bus.lateral.get_node("Aviso").text += "\nNo se guardó tu avance. Vuelve a intentar la práctica."
				elif not cierre.respaldo:
					bus.lateral.get_node("Aviso").text += "\nSe guardó el avance, pero falta el respaldo.")
	bus.conexion_panel = conexion
	bus.tecnico = tecnico
	abrir(bus)
	bus.salida_solicitada.connect(volver)
	$Marco/Volver.hide()


func abrir(nueva: Node) -> void:
	if is_instance_valid(pantalla):
		$Marco.remove_child(pantalla)
		pantalla.queue_free()
	entrada_inicio.hide()
	ajustar_marco(true)
	inicio.hide()
	pantalla = nueva
	$Marco/Volver.show()
	if nueva is Control:
		nueva.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$Marco.add_child(nueva)


func volver() -> void:
	if is_instance_valid(pantalla):
		$Marco.remove_child(pantalla)
		pantalla.queue_free()
		pantalla = null
	$Marco.show()
	if is_instance_valid(ruta_en_pausa):
		pantalla = ruta_en_pausa
		ruta_en_pausa = null
		pantalla.inicio_ms += Time.get_ticks_msec() - inicio_practica_mapa
		pantalla.show()
		pantalla.panel_detalle_mapa.cerrar()
		$Marco/Volver.show()
		return
	$Marco/Volver.hide()
	ajustar_marco(false)
	entrada_inicio.show()
	inicio.show()
	actualizar()
	enfocar_inicio()


func ajustar_marco(actividad: bool) -> void:
	$Marco.offset_left = 24 if actividad else 0
	$Marco.offset_right = -24 if actividad else 0
	$Marco.offset_top = 16 if actividad else 0
	$Marco.offset_bottom = -16 if actividad else 0
