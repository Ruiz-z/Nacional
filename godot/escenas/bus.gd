extends Node3D

signal decision_tomada(decision: Dictionary)

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")
const INDICIOS := {
	"inspeccionado": "Sector inspeccionado",
	"indicio_confirmado": "Indicio de aislamiento confirmado",
	"sintomas_revisados": "Síntomas de red revisados",
	"resuelto": "Falla resuelta",
}
const PROBLEMAS := {
	"tornillo_roto": "Pieza dañada",
	"sector_equivocado": "Sector equivocado",
	"indicio_descartado": "Indicio descartado",
}
const Escenario = preload("res://logica/simulador/escenario.gd")
const Practica = preload("res://logica/simulador/practica.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Interactuable = preload("res://escenas/interactuable.gd")

@export_file("*.json") var archivo := Escenario.AISLAMIENTO
var motor: RefCounted
var datos: Dictionary
var ultimo_ms: int
var componente := ""
var pieza_apuntada: Interactuable
var conexion_panel: RefCounted
var tecnico := {}
var resultados_guardados := false
var pausa_visible := false
var hud_colapsado := false
var panel_oculto := false
var modo_captura := false
@onready var jugador := $Jugador
@onready var alcance: RayCast3D = $Jugador/Camara/Alcance
@onready var resumen := $Interfaz/Lateral/Resumen
@onready var lateral := $Interfaz/Lateral
@onready var panel := $AlineacionPanel/PanelVirtual


func _ready() -> void:
	jugador.configurar(panel.entrada)
	jugador.activo = false
	$Interfaz.add_theme_stylebox_override("panel", lateral.get_theme_stylebox("panel", "PanelContainer"))
	FondoTarjeta.aplicar(panel, 16)
	lateral.get_node("AlternarHud").pressed.connect(func():
		hud_colapsado = not hud_colapsado
		actualizar_hud())
	$AlternarPanel.pressed.connect(func():
		panel_oculto = not panel_oculto
		actualizar_panel(Time.get_ticks_msec()))
	lateral.get_node("Accion").item_selected.connect(func(_indice: int):
		actualizar_accion_visible())
	if conexion_panel != null:
		panel.conexion = conexion_panel
		panel.conexion.protocolo.reiniciar_fuente("virtual")
	var carga := Escenario.cargar(archivo)
	datos = carga.get("escenario", {})
	if datos.is_empty():
		$Interfaz/Lateral/Estado.text = str(carga)
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	motor = Motor.new(datos)
	ultimo_ms = Time.get_ticks_msec()
	lateral.get_node("Causa").add_item("Marcar una causa")
	for causa in datos.causas:
		lateral.get_node("Causa").add_item(causa.replace("-", " ").capitalize())
	lateral.get_node("Causa").item_selected.connect(func(indice: int):
		motor.marcar_causa("" if indice == 0 else datos.causas[indice - 1]))
	lateral.get_node("Continuar").pressed.connect(func():
		panel.conexion.reanudar()
		ultimo_ms = Time.get_ticks_msec()
		actualizar_panel(ultimo_ms))
	lateral.get_node("ConfirmarAccion").pressed.connect(func():
		recibir_accion({"accion": "confirmar", "fuente_entrada": "teclado"}))
	panel.accion_recibida.connect(recibir_accion)
	resumen.reintento_solicitado.connect(reintentar)
	mostrar_estado()
	actualizar_panel(ultimo_ms)


func ejecutar(id: String, fuente: String) -> void:
	if motor == null or panel.conexion.pausado():
		return
	var ahora := Time.get_ticks_msec()
	var decision: Dictionary = motor.ejecutar(id, fuente, ahora - ultimo_ms)
	ultimo_ms = ahora
	var mensajes := PackedStringArray()
	if not decision.get("motivo", "").is_empty():
		mensajes.append(decision.motivo)
	for evento in decision.get("eventos", []):
		mensajes.append("Problema · %s" % PROBLEMAS.get(evento, datos.eventos[evento].descripcion))
	if not mensajes.is_empty() and not decision.get("fuente", "").is_empty():
		mensajes.append(decision.fuente)
	lateral.get_node("Aviso").text = "\n".join(mensajes)
	if not motor.fin().is_empty() and not tecnico.is_empty() and not resultados_guardados:
		resultados_guardados = Practica.guardar(tecnico.base, tecnico.id, tecnico.alias, motor,
			int(Time.get_unix_time_from_system()))
		if not resultados_guardados:
			lateral.get_node("Aviso").text += "\nNo se pudo guardar el resultado de la práctica."
	componente = ""
	mostrar_estado()
	if not motor.fin().is_empty() and resumen.get_node("Reflexion").visible:
		resumen.get_node("Reflexion").grab_focus()
	decision_tomada.emit(decision)


func mostrar_estado() -> void:
	var estado: Dictionary = motor.estado()
	var terminado: bool = not motor.fin().is_empty()
	jugador.activo = not terminado and not pausa_visible
	if terminado:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var lineas := PackedStringArray()
	for clave in INDICIOS:
		if estado.has(clave):
			lineas.append("%s %s" % ["✓" if estado[clave] else "—", INDICIOS[clave]])
	for clave in PROBLEMAS:
		if estado.get(clave, false):
			lineas.append("!  %s" % PROBLEMAS[clave])
	lateral.get_node("Estado").text = datos.titulo.trim_prefix("[MUESTRA] ")
	lateral.get_node("Objetivo").text = datos.descripcion.trim_prefix("[MUESTRA] ")
	lateral.get_node("Indicios").text = "\n".join(lineas)
	var falla: bool = motor.hay_problemas() or motor.fin() == "falta-critica"
	$Sector.reflejar_estado(estado, falla, modo_captura)
	panel.mostrar_leds({"energizado": estado.get("energizado"), "bloqueado": estado.get("bloqueo_puesto"),
		"falla": falla})
	actualizar_hud()
	mostrar_acciones()
	resumen.mostrar(motor)


func actualizar_hud() -> void:
	var terminado: bool = motor != null and not motor.fin().is_empty()
	var detalle := not terminado and not hud_colapsado
	$Interfaz.offset_right = 476.0 if terminado else 312.0
	lateral.get_node("AlternarHud").visible = not terminado
	lateral.get_node("AlternarHud").text = "Mostrar HUD" if hud_colapsado else "Ocultar HUD"
	for nombre in ["Estado", "Objetivo", "IndiciosTitulo", "Indicios", "Conexion"]:
		lateral.get_node(nombre).visible = detalle or (nombre == "Conexion" and pausa_visible)
	lateral.get_node("Muestra").visible = detalle and datos.get("muestra", false)
	lateral.get_node("Controles").visible = not terminado
	lateral.get_node("Aviso").visible = not lateral.get_node("Aviso").text.is_empty()


func reintentar() -> void:
	var nuevo: RefCounted = motor.reintentar()
	if nuevo == null:
		return
	motor = nuevo
	resultados_guardados = false
	lateral.get_node("Causa").select(0)
	componente = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	lateral.get_node("Aviso").text = ""
	ultimo_ms = Time.get_ticks_msec()
	mostrar_estado()


func abrir_menu(pieza: Interactuable) -> void:
	componente = pieza.componente
	lateral.get_node("Pieza").text = pieza.nombre
	mostrar_acciones()


func cerrar_menu() -> void:
	componente = ""
	mostrar_acciones()


func mostrar_acciones() -> void:
	var lista: OptionButton = lateral.get_node("Accion")
	var causa: OptionButton = lateral.get_node("Causa")
	causa.visible = motor.estado().get("inspeccionado", true) and motor.fin().is_empty()
	lista.visible = not componente.is_empty() and motor.fin().is_empty()
	lateral.get_node("Pieza").visible = lista.visible
	var lectura: String = $Sector.lectura_pieza(componente)
	lateral.get_node("LecturaPieza").text = lectura
	lateral.get_node("LecturaPieza").visible = lista.visible and not lectura.is_empty()
	lateral.get_node("ConfirmarAccion").visible = lista.visible
	lista.clear()
	lista.add_item("Elegir acción")
	lista.select(0)
	var opciones := Practica.opciones(motor, datos, componente)
	for id in opciones:
		var regla: Dictionary = opciones[id]
		var texto: String = regla.descripcion.trim_prefix("[MUESTRA] ")
		if regla.has("costo"):
			texto += " · costo %s · tiempo %s · riesgo %s" % [regla.costo.trim_prefix("[MUESTRA] "),
				regla.tiempo.trim_prefix("[MUESTRA] "), regla.riesgo.trim_prefix("[MUESTRA] ")]
		lista.add_item("%d. %s" % [lista.item_count, texto])
		var indice := lista.item_count - 1
		lista.set_item_metadata(indice, id)
		lista.get_popup().set_item_tooltip(indice, texto)
	if lista.visible and opciones.is_empty():
		lista.set_item_text(0, "Sin acciones disponibles")
	actualizar_accion_visible()


func actualizar_accion_visible() -> void:
	var lista: OptionButton = lateral.get_node("Accion")
	var detalle: Label = lateral.get_node("DetalleAccion")
	detalle.text = lista.get_item_text(lista.selected) if lista.selected > 0 else ""
	jugador.mostrar_herramienta(str(lista.get_selected_metadata()) if lista.visible and lista.selected > 0 and not pausa_visible else "")
	detalle.visible = lista.visible and not detalle.text.is_empty()
	lateral.get_node("ConfirmarAccion").disabled = pausa_visible or lista.selected <= 0


func recibir_accion(accion: Dictionary) -> void:
	if panel.conexion.pausado() or motor == null or not motor.fin().is_empty():
		return
	var lista: OptionButton = lateral.get_node("Accion")
	match accion.accion:
		"inspeccionar":
			if is_instance_valid(pieza_apuntada):
				abrir_menu(pieza_apuntada)
		"elegir-accion":
			if lista.visible and int(accion.valor) in range(lista.item_count):
				lista.select(int(accion.valor))
				actualizar_accion_visible()
		"cancelar":
			cerrar_menu()
		"confirmar":
			if lista.visible and lista.selected > 0:
				ejecutar(lista.get_selected_metadata(), accion.fuente_entrada)


func _process(_delta: float) -> void:
	actualizar_panel(Time.get_ticks_msec())


func _physics_process(_delta: float) -> void:
	var caminando: bool = jugador.activo and (modo_captura or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	var objetivo := alcance.get_collider() as Interactuable if caminando else null
	if objetivo != pieza_apuntada:
		if is_instance_valid(pieza_apuntada):
			pieza_apuntada.resaltar(false)
		pieza_apuntada = objetivo
		if objetivo != null:
			objetivo.resaltar(true)
	$Mira.visible = caminando
	$Apuntado.visible = objetivo != null
	$Apuntado/Fondo/Nombre.text = "Clic / A · %s" % objetivo.nombre if objetivo != null else ""


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func actualizar_panel(ahora: int) -> void:
	panel.conexion.actualizar(ahora)
	lateral.get_node("Conexion").text = panel.conexion.etiqueta()
	var pausa: bool = panel.conexion.pausado()
	if pausa != pausa_visible:
		pausa_visible = pausa
		jugador.activo = not pausa and motor != null and motor.fin().is_empty()
		if pausa:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var continuar: Button = lateral.get_node("Continuar")
		continuar.visible = pausa
		for nombre in ["Causa", "Accion"]:
			lateral.get_node(nombre).disabled = pausa
		actualizar_accion_visible()
		actualizar_hud()
		if pausa:
			continuar.grab_focus()
	$AlternarPanel.visible = panel.conexion.fuente_panel() == "virtual" and not pausa \
		and motor != null and motor.fin().is_empty()
	$AlternarPanel.text = "Mostrar panel virtual" if panel_oculto else "Ocultar panel virtual"
	panel.visible = $AlternarPanel.visible and not panel_oculto


func _input(evento: InputEvent) -> void:
	if motor == null or not motor.fin().is_empty() or not evento.is_pressed() or evento.is_echo():
		return
	var capturado := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var accion := {}
	if evento is InputEventKey:
		if evento.keycode == KEY_TAB and not pausa_visible:
			var foco := get_viewport().gui_get_focus_owner()
			if not capturado and foco != null:
				foco.release_focus()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if capturado else Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		var tecla := OS.get_keycode_string(evento.keycode)
		accion = panel.entrada.traducir("teclado", tecla, 1)
		if accion.get("accion") not in ["elegir-accion", "confirmar", "cancelar"]:
			return
		if tecla == "Enter" and not capturado and get_viewport().gui_get_focus_owner() != null:
			return
	elif capturado and evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		accion = panel.entrada.traducir("teclado", "clic", 1)
	elif capturado and evento is InputEventJoypadButton:
		var lista: OptionButton = lateral.get_node("Accion")
		match evento.button_index:
			JOY_BUTTON_A:
				accion = panel.entrada.traducir("control", "A", 1)
			JOY_BUTTON_X:
				accion = panel.entrada.traducir("control", "X", 1)
			JOY_BUTTON_B:
				accion = panel.entrada.traducir("control", "B", 1)
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				var paso := 1 if evento.button_index == JOY_BUTTON_DPAD_DOWN else -1
				accion = panel.entrada.traducir("control", "dpad",
					posmod(lista.selected + paso, lista.item_count))
	if not accion.is_empty():
		recibir_accion(accion)
		get_viewport().set_input_as_handled()
