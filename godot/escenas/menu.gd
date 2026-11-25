extends Control

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal paso_solicitado(paso: String, perfil: Dictionary)

const Banco = preload("res://logica/competencias/banco.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const UI = preload("res://escenas/cuenta_ui.gd")
const Materiales = preload("res://logica/flujo/materiales.gd")
const Administracion = preload("res://escenas/administracion.tscn")
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
const NOMBRES := {"alias": "Iniciar sesión", "administracion": "Administración", "materiales": "Materiales de estudio", "diagnostico": "Diagnóstico", "ruta": "Ruta de aprendizaje",
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
var disponible := false
var pendiente := {}
var etapa := "ingreso"
var espera_hasta := 0
var volver_al_tablero := false
var aviso: AcceptDialog
# Abre la página de materiales (servidor local + navegador). Las pruebas lo sustituyen para no lanzar procesos.
var lanzar_materiales: Callable = abrir_pagina_materiales
@onready var entrada_inicio: ScrollContainer = $Marco/EntradaInicio
@onready var columna := $Marco/EntradaInicio/Columna
@onready var barra := columna.get_node("Barra/Margen/Fila")
@onready var texto_hero := columna.get_node("Hero/Margen/Fila/Texto")
@onready var inicio := columna.get_node("Hero/Margen/Fila/Tarjeta/Inicio")
@onready var usuario: LineEdit = inicio.get_node("Alias")
@onready var clave: LineEdit = inicio.get_node("Clave")
@onready var repeticion: LineEdit = inicio.get_node("Repetir")
@onready var enviar: Button = inicio.get_node("Elegir")
@onready var demo_boton: Button = inicio.get_node("DemoTarjeta")
@onready var espera: Label = inicio.get_node("Aviso")
@onready var recorrido := columna.get_node("Recorrido/Margen/Contenido")


func _ready() -> void:
	if "--verificar-contenido" in OS.get_cmdline_user_args():
		verificar_contenido()
		return
	disponible = Esquema.crear(base)
	inicio.get_node("Elegir").disabled = not disponible
	inicio.get_node("Elegir").pressed.connect(enviar_ingreso)
	inicio.get_node("Alta").toggled.connect(mostrar_claves)
	for campo in [usuario, clave, repeticion]:
		campo.text_submitted.connect(func(_texto: String): enviar_ingreso())
	barra.get_node("Salir").pressed.connect(cerrar_sesion)
	$Marco/Volver.pressed.connect(volver)
	preparar_inicio(disponible)
	etapa = "ingreso" if not disponible or Cuentas.hay_admin(base) else "primer-admin"
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
	inicio.get_node("DemoTarjeta").pressed.connect(abrir_demo)
	entrada_inicio.resized.connect(ajustar_hero)
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
	var materiales := crear_tarjeta("materiales", NOMBRES.materiales, "", false)
	recorrido.get_node("Pasos").add_child(materiales)
	materiales.get_node("Contenido/Insignia").text = "WEB"
	botones["materiales"] = materiales
	var gestion := crear_tarjeta("administracion", NOMBRES.administracion, "", false)
	recorrido.get_node("Pasos").add_child(gestion)
	gestion.get_node("Contenido/Insignia").text = "AD"
	botones["administracion"] = gestion
	entrada_inicio.resized.connect(ajustar_margenes)
	texto_hero.resized.connect(ajustar_titulo)
	ajustar_margenes()


func entrar_desde_hero() -> void:
	if usuario.text.strip_edges().is_empty():
		usuario.grab_focus()
	else:
		enviar_ingreso()


# Sin sesión, el inicio es solo un ingreso: la foto del taller a pantalla completa y la tarjeta al centro.
func ajustar_hero() -> void:
	var hero: Control = columna.get_node("Hero")
	hero.custom_minimum_size.y = maxf(480.0, entrada_inicio.size.y - 72.0) if perfil.is_empty() else 0.0


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
	actualizar_espera()


# Tras el bloqueo por intentos, «Entrar» queda deshabilitado con la cuenta regresiva.
func actualizar_espera() -> void:
	if etapa != "ingreso" or espera_hasta <= 0:
		return
	var segundos := maxi(0, ceili((espera_hasta - Time.get_ticks_msec()) / 1000.0))
	enviar.disabled = segundos > 0 or not disponible
	enviar.text = "Entrar en %d s" % segundos if segundos > 0 else "Entrar"
	if segundos == 0:
		espera_hasta = 0


func mostrar_claves(visibles: bool) -> void:
	clave.secret = not visibles
	repeticion.secret = not visibles
	inicio.get_node("Alta").text = "Ocultar contraseña" if visibles else "Mostrar contraseña"


# Prepara la tarjeta según la etapa: ingreso, primer administrador o cambio obligatorio de contraseña.
func preparar_tarjeta() -> void:
	var tarjeta := etapa in ["ingreso", "primer-admin", "cambio"]
	for nombre in ["EtiquetaAlias", "Alias"]:
		inicio.get_node(nombre).visible = tarjeta and etapa != "cambio"
	var con_repeticion := etapa in ["primer-admin", "cambio"]
	inicio.get_node("EtiquetaRepetir").visible = con_repeticion
	repeticion.visible = con_repeticion
	inicio.get_node("EtiquetaClave").text = "Nueva contraseña" if etapa == "cambio" else "Contraseña"
	inicio.get_node("Cabecera/Titulo").text = {"ingreso": "Entrar al taller", "primer-admin": "Crea la administración",
		"cambio": "Cambia tu contraseña"}.get(etapa, "Tu cuenta")
	inicio.get_node("Elegir").text = {"ingreso": "Entrar", "primer-admin": "Crear cuenta",
		"cambio": "Guardar contraseña"}.get(etapa, "Entrar")
	inicio.get_node("Alta").visible = tarjeta
	for campo in [clave, repeticion]:
		campo.text = ""
		campo.secret = true
	inicio.get_node("Alta").set_pressed_no_signal(false)
	inicio.get_node("Alta").text = "Mostrar contraseña"


func enviar_ingreso() -> void:
	var boton: Button = inicio.get_node("Elegir")
	if boton.disabled or (is_instance_valid(aviso) and aviso.visible):
		return
	if etapa in ["primer-admin", "cambio"] and clave.text != repeticion.text:
		UI.marcar_error(repeticion)
		aviso = UI.aviso(self, "Las contraseñas no coinciden. Escríbelas de nuevo.", repeticion)
		return
	var resultado: Dictionary
	match etapa:
		"primer-admin":
			if Cuentas.hay_admin(base):
				etapa = "ingreso"
				actualizar()
				return
			resultado = Cuentas.crear(base, usuario.text, "admin", clave.text)
		"cambio":
			resultado = Cuentas.cambiar_clave(base, pendiente.id, clave.text)
		_:
			var error_usuario := Cuentas.revisar_usuario(usuario.text)
			if not error_usuario.is_empty():
				UI.marcar_error(usuario)
				aviso = UI.aviso(self, error_usuario, usuario)
				return
			if clave.text.is_empty():
				UI.marcar_error(clave)
				aviso = UI.aviso(self, "Escribe tu contraseña para entrar.", clave)
				return
			resultado = Cuentas.entrar(base, usuario.text, clave.text, ahora())
	if not resultado.ok:
		if resultado.get("bloqueado", false):
			espera_hasta = Time.get_ticks_msec() + int(resultado.espera_s) * 1000
		var campo_error := clave
		if etapa == "primer-admin" and resultado.mensaje.contains("usuario"):
			campo_error = usuario
		UI.marcar_error(campo_error)
		aviso = UI.aviso(self, resultado.mensaje, campo_error)
		actualizar()
		actualizar_espera()
		return
	if etapa == "cambio":
		resultado = pendiente
	pendiente = {"ok": true, "id": resultado.id, "alias": resultado.alias, "rol": resultado.rol}
	if resultado.get("cambiar_clave", false):
		etapa = "cambio"
		actualizar()
		return
	perfil = pendiente
	pendiente = {}
	usuario.text = ""
	etapa = "menu"
	actualizar()
	enfocar_inicio()


func mostrar_ingreso() -> void:
	etapa = "cambio" if not pendiente.is_empty() else (
		"ingreso" if not disponible or Cuentas.hay_admin(base) else "primer-admin")
	actualizar()
	enfocar_inicio()


func cerrar_sesion() -> void:
	perfil = {}
	pendiente = {}
	usuario.text = ""
	etapa = "ingreso" if Cuentas.hay_admin(base) else "primer-admin"
	if is_instance_valid(pantalla):
		volver()
	actualizar()
	enfocar_inicio()


func ahora() -> int:
	return int(Time.get_unix_time_from_system())


# Jefe directo y admin no hacen las actividades de formación; el admin además abre Administración.
func pasos_del_rol() -> Array:
	match perfil.get("rol", ""):
		"tecnico":
			return Recorrido.PASOS + ["materiales"]
		"jefe":
			return ["tablero", "materiales"]
		"admin":
			return ["tablero", "materiales", "administracion"]
	return []


func actualizar() -> void:
	if perfil.is_empty() and etapa == "menu":
		etapa = "ingreso" if Cuentas.hay_admin(base) else "primer-admin"
	var con_sesion := not perfil.is_empty()
	var rol: String = perfil.get("rol", "")
	var estado := Recorrido.estado(base, perfil.get("id", 0), ahora()) if rol == "tecnico" else {}
	var siguiente: String = estado.get("siguiente", "alias" if rol == "tecnico" or not con_sesion else "tablero")
	barra.get_node("Perfil").text = "%s · %s" % [Cuentas.NOMBRES_ROL.get(rol, ""),
		TextoLimpio.linea(perfil.get("alias", ""))] if con_sesion else "Sin sesión"
	barra.get_node("Salir").visible = con_sesion
	var tarjeta: Control = columna.get_node("Hero/Margen/Fila/Tarjeta")
	var solo_ingreso := perfil.is_empty()
	texto_hero.visible = not solo_ingreso
	columna.get_node("Recorrido").visible = not solo_ingreso
	for nombre in ["Perfil", "Entrada", "Salir"]:
		barra.get_node(nombre).visible = not solo_ingreso and (nombre != "Salir" or con_sesion)
	columna.get_node("Hero/Margen/Fila").alignment = BoxContainer.ALIGNMENT_CENTER if solo_ingreso else BoxContainer.ALIGNMENT_BEGIN
	tarjeta.custom_minimum_size.x = 400.0 if solo_ingreso else 342.0
	tarjeta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if solo_ingreso else Control.SIZE_FILL
	demo_boton.visible = solo_ingreso and etapa == "ingreso"
	ajustar_hero()
	var formulario := not con_sesion or etapa == "cambio"
	for nombre in ["EtiquetaAlias", "Alias", "EtiquetaClave", "Clave", "EtiquetaRepetir", "Repetir", "Elegir", "Alta"]:
		inicio.get_node(nombre).visible = formulario
	if formulario:
		preparar_tarjeta()
	else:
		inicio.get_node("Cabecera/Titulo").text = "Tu cuenta"
	texto_hero.get_node("Acciones/IrAlias").visible = false
	texto_hero.get_node("Acciones/IrAlias").disabled = not disponible
	inicio.get_node("Siguiente").visible = rol == "tecnico" and etapa != "cambio"
	inicio.get_node("Siguiente").text = "Siguiente paso · %s" % NOMBRES.get(siguiente, "Tablero")
	var razon: String = estado.get("aviso", "")
	inicio.get_node("Aviso").text = razon if not razon.is_empty() else (
		{"ingreso": "Entra con tu usuario y tu contraseña.",
		"primer-admin": "Aún no hay administración. Crea la primera cuenta: 3 a 24 caracteres, sin tu nombre real, y una contraseña de 8 o más.",
		"cambio": "Antes de seguir, reemplaza tu contraseña temporal."}.get(etapa,
			{"jefe": "Revisa el progreso del equipo y la recomendación para cada técnico en el tablero.",
			"admin": "Administra las cuentas y revisa el estado del taller."}.get(rol,
				"Sigue con esta actividad: %s." % NOMBRES.get(siguiente, "Tablero"))))
	columna.get_node("Destacados").visible = rol == "tecnico"
	recorrido.get_node("Titulo").text = "Tu recorrido" if rol == "tecnico" else "Tu panel"
	var permitidos := pasos_del_rol()
	for paso in botones:
		var boton: Button = botones[paso]
		boton.visible = not con_sesion or paso in permitidos
		boton.disabled = not con_sesion or (rol == "tecnico" and paso not in estado.get("habilitados", [])
			and not (paso == "retest" and siguiente == "retest") and paso not in ["escenario", "tablero", "materiales"])
		var estado_paso := "Bloqueado"
		if not boton.disabled:
			if paso == siguiente and rol == "tecnico":
				estado_paso = "Siguiente"
			elif paso == "escenario":
				estado_paso = "Práctica libre"
			else:
				estado_paso = "Disponible"
		boton.get_node("Contenido/Insignia").visible = rol == "tecnico" or not con_sesion
		boton.get_node("Contenido/Estado").text = estado_paso
		boton.accessibility_description = estado_paso
		boton.get_node("Contenido").modulate.a = 0.76 if boton.disabled else 1.0
		if destacados.has(paso):
			destacados[paso].disabled = boton.disabled
			destacados[paso].get_node("Contenido").modulate.a = 0.72 if boton.disabled else 1.0
		boton.tooltip_text = ("Entra con tu cuenta para empezar." if not con_sesion else
			"Completa el paso anterior para abrir esta actividad.") if boton.disabled else razon
	tarjeta.show()


func enfocar_inicio() -> void:
	var siguiente: String = "tablero"
	if perfil.get("rol", "") == "tecnico":
		siguiente = Recorrido.estado(base, perfil.get("id", 0), ahora()).get("siguiente", "diagnostico")
	var boton: Control = botones.get(siguiente, usuario if etapa != "cambio" else clave)
	if perfil.is_empty():
		boton = clave if etapa == "cambio" else usuario
	if boton.visible and not (boton is Button and boton.disabled):
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
			abrir_tablero(perfil.merged({"base": base}))
		"administracion":
			abrir_administracion()
		"materiales":
			abrir_materiales()
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


func abrir_materiales() -> void:
	lanzar_materiales.call(perfil.get("rol", ""))


# Levanta `python web/servidor.py` (si ya corre, el nuevo proceso termina solo) y abre el navegador. Jefe directo y
# admin entran con el permiso de autor que el servidor guarda en web/.token-autor; el técnico entra sin él.
func abrir_pagina_materiales(rol: String) -> void:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var servidor := raiz.path_join("web/servidor.py")
	if not FileAccess.file_exists(servidor):
		aviso = UI.aviso(self, "No se encontró la página de materiales en esta instalación.")
		return
	var python := "python" if OS.get_name() == "Windows" else "python3"
	if OS.create_process(python, [servidor, "--puerto", str(Materiales.PUERTO)]) < 0:
		aviso = UI.aviso(self, "No se pudo iniciar la página de materiales. Comprueba que Python 3 está instalado.")
		return
	var token := ""
	for _intento in range(10):
		await get_tree().create_timer(0.4).timeout
		token = Materiales.leer_token(raiz)
		if not token.is_empty() or rol not in Materiales.ROLES_AUTOR:
			break
	OS.shell_open(Materiales.url(rol, token))


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
	tablero.perfil = tecnico
	tablero.administracion_solicitada.connect(abrir_administracion)
	abrir(tablero)


func abrir_administracion() -> void:
	if not Cuentas.puede_crear(perfil.get("rol", ""), "tecnico"):
		return
	var gestion := Administracion.instantiate()
	gestion.base = base
	gestion.perfil = perfil
	var desde_tablero: bool = is_instance_valid(pantalla) and pantalla.has_signal("administracion_solicitada")
	abrir(gestion)
	volver_al_tablero = desde_tablero
	if volver_al_tablero:
		$Marco/Volver.text = "‹  Volver al tablero"


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
	volver_al_tablero = false
	$Marco/Volver.text = "‹  Volver al menú"
	$Marco/Volver.show()
	if nueva is Control:
		nueva.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$Marco.add_child(nueva)


func volver() -> void:
	if volver_al_tablero:
		abrir_tablero(perfil.merged({"base": base}))
		return
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
