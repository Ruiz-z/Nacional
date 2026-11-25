extends Control

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal paso_solicitado(paso: String, perfil: Dictionary)

const Banco = preload("res://logica/competencias/banco.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const UI = preload("res://escenas/cuenta_ui.gd")
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
const NOMBRES := {"administracion": "Administración", "diagnostico": "Diagnóstico", "ruta": "Ruta de aprendizaje",
	"escenario": "Práctica", "post": "Evaluación", "retest": "Repetir la evaluación", "tablero": "Tablero"}

var base := "user://nacional.sqlite"
var perfil := {}
var banco_aprendizaje := {}
var conexion := Conexion.new()
var pantalla: Node
var volver_al_tablero := false
var ruta_en_pausa: Control
var inicio_practica_mapa := 0
var botones := {}
var disponible := false
var pendiente := {}
var etapa := ""
var espera_hasta := 0
var inicio: VBoxContainer
var barra: HBoxContainer
var usuario: LineEdit
var clave: LineEdit
var repeticion: LineEdit
var enviar: Button
var demo_boton: Button
var espera: Label
var aviso: AcceptDialog
@onready var entrada_inicio: ScrollContainer = $Marco/EntradaInicio


func _ready() -> void:
	if "--verificar-contenido" in OS.get_cmdline_user_args():
		verificar_contenido()
		return
	disponible = Esquema.crear(base)
	$Marco/Volver.pressed.connect(volver)
	mostrar_ingreso()


func renovar_inicio(centrado: bool) -> void:
	for hijo in entrada_inicio.get_children():
		entrada_inicio.remove_child(hijo)
		hijo.queue_free()
	var marco := MarginContainer.new()
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 32)
	entrada_inicio.add_child(marco)
	var centro := CenterContainer.new()
	marco.add_child(centro)
	inicio = VBoxContainer.new()
	inicio.custom_minimum_size.x = 420 if centrado else 780
	inicio.add_theme_constant_override("separation", 10)
	centro.add_child(inicio)
	entrada_inicio.set_deferred("scroll_vertical", 0)


func mostrar_ingreso() -> void:
	renovar_inicio(true)
	etapa = "cambio" if not pendiente.is_empty() else (
		"ingreso" if not disponible or Cuentas.hay_admin(base) else "primer-admin")
	var titulo: String = {"ingreso": "Entrar al taller", "primer-admin": "Crea la cuenta de administración",
		"cambio": "Cambia tu contraseña"}[etapa]
	inicio.add_child(UI.etiqueta(titulo, &"Titulo"))
	if etapa == "cambio":
		inicio.add_child(UI.etiqueta("Antes de seguir, reemplaza tu contraseña temporal.", &"Secundario"))
	else:
		usuario = UI.campo(inicio, "Usuario")
		if etapa == "primer-admin":
			inicio.add_child(UI.etiqueta("Usa de 3 a 24 caracteres. Evita tu nombre real.", &"Secundario"))
	clave = UI.campo(inicio, "Contraseña" if etapa == "ingreso" else "Nueva contraseña", true)
	if etapa != "ingreso":
		repeticion = UI.campo(inicio, "Repite la contraseña", true)
		inicio.add_child(UI.etiqueta("Usa al menos 8 caracteres.", &"Secundario"))
	var revelar := UI.boton("Mostrar contraseña")
	revelar.toggle_mode = true
	revelar.toggled.connect(func(visible_clave: bool):
		clave.secret = not visible_clave
		if etapa != "ingreso":
			repeticion.secret = not visible_clave
		revelar.text = "Ocultar contraseña" if visible_clave else "Mostrar contraseña")
	inicio.add_child(revelar)
	var texto: String = {"ingreso": "Entrar", "primer-admin": "Crear cuenta", "cambio": "Guardar contraseña"}[etapa]
	enviar = UI.boton(texto, true)
	enviar.pressed.connect(enviar_ingreso)
	inicio.add_child(enviar)
	if etapa != "cambio":
		usuario.text_submitted.connect(func(_texto: String): enviar_ingreso())
	clave.text_submitted.connect(func(_texto: String): enviar_ingreso())
	if etapa != "ingreso":
		repeticion.text_submitted.connect(func(_texto: String): enviar_ingreso())
	espera = UI.etiqueta("", &"Aviso")
	inicio.add_child(espera)
	if etapa == "ingreso":
		demo_boton = UI.boton("Modo demo")
		demo_boton.pressed.connect(abrir_demo)
		inicio.add_child(demo_boton)
	elif etapa == "cambio":
		var cancelar := UI.boton("Cerrar sesión")
		cancelar.pressed.connect(cerrar_sesion)
		inicio.add_child(cancelar)
	if not disponible:
		espera.text = "No se pudo abrir el progreso. Cierra el juego y ábrelo de nuevo."
	actualizar_espera()
	if etapa == "cambio":
		clave.grab_focus()
	else:
		usuario.grab_focus()


func actualizar_espera() -> void:
	var segundos := maxi(0, ceili((espera_hasta - Time.get_ticks_msec()) / 1000.0))
	enviar.disabled = not disponible or (etapa == "ingreso" and segundos > 0)
	if disponible:
		espera.text = "Puedes volver a intentar en %d s." % segundos if segundos > 0 else ""
	espera.visible = not espera.text.is_empty()


func enviar_ingreso() -> void:
	if enviar.disabled or (is_instance_valid(aviso) and aviso.visible):
		return
	var resultado: Dictionary
	if etapa != "ingreso" and clave.text != repeticion.text:
		UI.marcar_error(repeticion)
		aviso = UI.aviso(self, "Las contraseñas no coinciden. Escríbelas de nuevo.", repeticion)
		return
	match etapa:
		"primer-admin":
			if Cuentas.hay_admin(base):
				mostrar_ingreso()
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
			var instante := ahora()
			resultado = Cuentas.entrar(base, usuario.text, clave.text, instante)
			if resultado.get("mensaje", "") == Cuentas.MENSAJE_INVALIDO:
				# Cuentas registra el bloqueo al quinto fallo y comunica la espera al siguiente intento.
				var filas: Variant = Acceso.consultar(base,
					"SELECT bloqueado_hasta FROM tecnico WHERE alias = ? AND demo = 0;",
					[Cuentas.normalizar(usuario.text)])
				if filas is Array and not filas.is_empty() and int(filas[0].bloqueado_hasta) > instante:
					resultado = Cuentas.entrar(base, usuario.text, clave.text, instante)
	if not resultado.ok:
		if resultado.get("bloqueado", false):
			espera_hasta = Time.get_ticks_msec() + int(resultado.espera_s) * 1000
			actualizar_espera()
		var campo_error := clave
		if etapa == "primer-admin" and (not Cuentas.revisar_usuario(usuario.text).is_empty() \
				or resultado.mensaje.contains("usuario")):
			campo_error = usuario
		UI.marcar_error(campo_error)
		aviso = UI.aviso(self, resultado.mensaje, campo_error)
		return
	if etapa == "cambio":
		resultado = pendiente
	pendiente = {"ok": true, "id": resultado.id, "alias": resultado.alias, "rol": resultado.rol}
	if resultado.get("cambiar_clave", false):
		mostrar_ingreso()
		return
	perfil = pendiente
	pendiente = {}
	mostrar_menu()


func cerrar_sesion() -> void:
	perfil = {}
	pendiente = {}
	botones.clear()
	mostrar_ingreso()


func ahora() -> int:
	return int(Time.get_unix_time_from_system())


func actualizar() -> void:
	if not perfil.is_empty():
		mostrar_menu()


func mostrar_menu() -> void:
	renovar_inicio(false)
	etapa = "menu"
	barra = HBoxContainer.new()
	barra.add_theme_constant_override("separation", 16)
	inicio.add_child(barra)
	var identidad := UI.etiqueta("%s · %s" % [TextoLimpio.linea(perfil.alias), Cuentas.NOMBRES_ROL[perfil.rol]])
	identidad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(identidad)
	var entrada := UI.etiqueta(conexion.etiqueta(), &"Secundario")
	entrada.name = "Entrada"
	entrada.visible = perfil.rol == "tecnico"
	barra.add_child(entrada)
	var salir := UI.boton("Cerrar sesión")
	salir.pressed.connect(cerrar_sesion)
	barra.add_child(salir)
	inicio.add_child(HSeparator.new())
	inicio.add_child(UI.etiqueta("Menú del taller", &"Titulo"))
	botones.clear()
	var siguiente := "tablero"
	var estado := {}
	var pasos := ["tablero", "administracion"] if perfil.rol == "admin" else ["tablero"]
	if perfil.rol == "tecnico":
		estado = Recorrido.estado(base, perfil.id, ahora())
		siguiente = estado.get("siguiente", "diagnostico")
		pasos = Recorrido.PASOS
		inicio.add_child(UI.etiqueta("Siguiente paso · %s" % NOMBRES.get(siguiente, "Diagnóstico"), &"Secundario"))
		if not estado.get("aviso", "").is_empty():
			inicio.add_child(UI.etiqueta(estado.aviso, &"Aviso"))
	for paso in pasos:
		var boton := UI.boton(NOMBRES[paso], paso == siguiente)
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.disabled = perfil.rol == "tecnico" and paso not in ["escenario", "tablero"] \
			and paso not in estado.get("habilitados", []) and not (paso == "retest" and siguiente == "retest")
		boton.tooltip_text = "Completa el paso anterior para abrir esta actividad." if boton.disabled else ""
		boton.pressed.connect(abrir_paso.bind(paso))
		inicio.add_child(boton)
		botones[paso] = boton
	var foco: Button = botones.get(siguiente, botones.tablero)
	if foco.disabled:
		foco = botones.tablero
	foco.grab_focus()


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
	if etapa == "menu" and is_instance_valid(barra):
		barra.get_node("Entrada").text = conexion.etiqueta()
	elif etapa == "ingreso" and espera_hasta > 0:
		actualizar_espera()
		if Time.get_ticks_msec() >= espera_hasta:
			espera_hasta = 0


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
	if etapa == "cambio":
		return
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
		$Marco/Volver.text = "Volver al tablero"


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
	$Marco/Volver.text = "Volver"
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
	if perfil.is_empty():
		mostrar_ingreso()
	else:
		mostrar_menu()


func ajustar_marco(actividad: bool) -> void:
	$Marco.offset_left = 24 if actividad else 0
	$Marco.offset_right = -24 if actividad else 0
	$Marco.offset_top = 16 if actividad else 0
	$Marco.offset_bottom = -16 if actividad else 0
