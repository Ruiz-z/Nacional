extends Node3D

signal decision_tomada(decision: Dictionary)

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")
const INDICIOS := {
	"inspeccionado": "Sector inspeccionado",
	"continuidad_medida": "Continuidad medida",
	"refrigerante_revisado": "Circuito de refrigerante revisado",
	"temperatura_medida": "Temperatura medida",
	"indicio_confirmado": "Indicio de aislamiento confirmado",
	"sintomas_revisados": "Síntomas de red revisados",
	"resuelto": "Falla resuelta",
}
const PROBLEMAS := {
	"tornillo_roto": "Pieza dañada",
	"fusible_quemado": "Fusible quemado",
	"pieza_danada": "Abrazadera dañada",
	"alerta_temperatura": "Alerta de temperatura",
	"sector_equivocado": "Sector equivocado",
	"indicio_descartado": "Indicio descartado",
}
const RESULTADOS := {
	"inspeccionar": "Compuerta abierta",
	"evaluar_indicio": "Indicio de aislamiento confirmado",
	"revisar_sintomas": "Síntomas de la red revisados",
	"confirmar_solucion": "Falla resuelta",
	"confirmar_diagnostico": "Diagnóstico confirmado",
	"reponer_pieza": "Tornillo repuesto",
	"volver_al_sector": "Sector correcto recuperado",
	"recuperar_indicio": "Indicio recuperado",
}
const Escenario = preload("res://logica/simulador/escenario.gd")
const Practica = preload("res://logica/simulador/practica.gd")
const MenuPieza = preload("res://logica/simulador/menu_pieza.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Interactuable = preload("res://escenas/interactuable.gd")

@export_file("*.json") var archivo := Escenario.AISLAMIENTO
var motor: RefCounted
var datos: Dictionary
var ultimo_ms: int
var accion_pendiente := ""
var causa_marcada := ""
var pieza_apuntada: Interactuable
var conexion_panel: RefCounted
var tecnico := {}
var resultados_guardados := false
var pausa_visible := false
var hud_colapsado := false
var panel_oculto := false
var modo_captura := false
var zona_activa: Node3D
var seguridad_panel := {}
var fuente_seguridad := ""
@onready var zonas := {"gabinete": $Sector, "cabina": $Sector, "faros": $Faros, "motor": $Motor}
@onready var jugador := $Jugador
@onready var alcance: RayCast3D = $Jugador/Camara/Alcance
@onready var resumen := $Interfaz/Lateral/Resumen
@onready var lateral := $Interfaz/Lateral
@onready var menu_pieza := $MenuPieza
@onready var resultado: Label = $AvisoCentral/Resultado
@onready var duracion_aviso: Timer = $AvisoCentral/Duracion
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
	menu_pieza.elegida.connect(elegir_accion)
	menu_pieza.cierre_solicitado.connect(cerrar_menu)
	menu_pieza.causa_marcada.connect(func(causa: String):
		if motor.marcar_causa(causa):
			causa_marcada = causa)
	duracion_aviso.timeout.connect(resultado.hide)
	zona_activa = zonas[datos.zona]
	for zona in [$Faros, $Motor]:
		if zona != zona_activa:
			zona.reflejar_estado({}, false, true)
	if not modo_captura:
		ubicar_jugador("monitor" if datos.zona == "cabina" else zona_activa.acceso)
	lateral.get_node("Continuar").pressed.connect(func():
		panel.conexion.reanudar()
		ultimo_ms = Time.get_ticks_msec()
		actualizar_panel(ultimo_ms))
	panel.accion_recibida.connect(recibir_accion)
	if datos.zona == "motor":
		panel.get_node("Bloqueo").toggled.connect(func(_activo: bool): actualizar_leds())
	resumen.reintento_solicitado.connect(reintentar)
	mostrar_estado(true)
	actualizar_panel(ultimo_ms)


func ubicar_jugador(componente: String) -> void:
	var objetivo: Node3D = zona_activa.piezas[componente]
	var origen := zona_activa.to_global(Vector3(1.8, 0, 0))
	jugador.global_position = Vector3(origen.x, 0, origen.z)
	if zona_activa == $Sector:
		jugador.global_position.z = objetivo.global_position.z
	jugador.look_at(Vector3(objetivo.global_position.x, jugador.global_position.y, objetivo.global_position.z))
	jugador.camara.look_at(objetivo.global_position)


func ejecutar(id: String, fuente: String) -> void:
	if motor == null or panel.conexion.pausado():
		return
	var ahora := Time.get_ticks_msec()
	sincronizar_fuente_seguridad()
	var decision: Dictionary = motor.ejecutar(id, fuente, ahora - ultimo_ms, controles_seguridad())
	ultimo_ms = ahora
	mostrar_resultado(decision)
	jugador.mostrar_herramienta(id if decision.get("aplicada", false) else "")
	if not motor.fin().is_empty() and not tecnico.is_empty() and not resultados_guardados:
		resultados_guardados = Practica.guardar(tecnico.base, tecnico.id, tecnico.alias, motor,
			int(Time.get_unix_time_from_system()))
		if not resultados_guardados:
			lateral.get_node("Aviso").text += "\nNo se pudo guardar el resultado de la práctica."
	mostrar_estado()
	if not motor.fin().is_empty() and resumen.get_node("Reflexion").visible:
		resumen.get_node("Reflexion").grab_focus()
	decision_tomada.emit(decision)


func mostrar_resultado(decision: Dictionary) -> void:
	var texto: String = decision.get("motivo", "").trim_prefix("[MUESTRA] ")
	if "tornillo_roto" in decision.get("eventos", []):
		texto = "Pieza dañada: tornillo roto"
	elif not decision.get("eventos", []).is_empty():
		var evento: String = decision.eventos[0]
		texto = PROBLEMAS.get(evento, datos.eventos[evento].descripcion.trim_prefix("[MUESTRA] "))
	elif not decision.get("aplicada", false) and texto.begins_with("Se requiere "):
		texto = "Acción no aplicada. Revisa los indicios y completa los pasos previos."
	elif texto.is_empty():
		var id: String = decision.get("accion", "")
		if id == "inspeccionar" and zona_activa != $Sector:
			texto = "%s abierta" % zona_activa.piezas[zona_activa.acceso].nombre
		else:
			texto = RESULTADOS.get(id, "Acción completada")
	avisar(texto)


func avisar(texto: String) -> void:
	resultado.text = texto
	resultado.show()
	duracion_aviso.start()


func mostrar_estado(inmediato := false) -> void:
	var estado: Dictionary = motor.estado()
	var terminado: bool = not motor.fin().is_empty()
	jugador.activo = not terminado and not pausa_visible and not menu_pieza.visible
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
	zona_activa.reflejar_estado(estado, falla, inmediato or modo_captura)
	actualizar_leds()
	actualizar_hud()
	resumen.mostrar(motor)


func actualizar_leds() -> void:
	var estado: Dictionary = motor.estado()
	var bloqueado: Variant = estado.get("bloqueo_puesto")
	if datos.zona == "motor":
		bloqueado = controles_seguridad().get("bloqueo", false)
	panel.mostrar_leds({"energizado": estado.get("energizado"), "bloqueado": bloqueado,
		"falla": motor.hay_problemas() or motor.fin() == "falta-critica"})


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
	causa_marcada = ""
	cerrar_menu()
	duracion_aviso.stop()
	resultado.hide()
	lateral.get_node("Aviso").text = ""
	ultimo_ms = Time.get_ticks_msec()
	mostrar_estado()


func abrir_menu(pieza: Interactuable) -> void:
	if motor == null or not motor.fin().is_empty() or pausa_visible or not accion_pendiente.is_empty():
		return
	var opciones: Array[Dictionary] = []
	var causas: Array = []
	var lectura := "[MUESTRA] Sin falla en esta orden"
	if pieza.zona == zona_activa:
		opciones = MenuPieza.entradas(motor, datos, pieza.componente)
		if zona_activa != $Sector or not opciones.is_empty():
			lectura = zona_activa.lectura_pieza(pieza.componente)
		if motor.estado().get("inspeccionado", motor.estado().get("sintomas_revisados", false)):
			causas = datos.causas
	menu_pieza.abrir(pieza.nombre, lectura, opciones, causas, causa_marcada)
	jugador.activo = false
	$Apuntado.hide()


func cerrar_menu() -> void:
	accion_pendiente = ""
	menu_pieza.cerrar()
	jugador.mostrar_herramienta("")
	if not pausa_visible and motor != null and motor.fin().is_empty():
		jugador.activo = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func elegir_accion(indice: int, fuente: String) -> void:
	if not menu_pieza.visible or not accion_pendiente.is_empty() or panel.conexion.pausado() \
			or indice < 0 or indice >= menu_pieza.entradas.size():
		return
	var entrada: Dictionary = menu_pieza.entradas[indice]
	if entrada.requiere_panel:
		accion_pendiente = entrada.id
		if panel.conexion.fuente_panel() == "virtual":
			panel_oculto = false
			actualizar_panel(Time.get_ticks_msec())
		menu_pieza.esperar_panel(entrada.texto)
		jugador.mostrar_herramienta(entrada.id)
	else:
		cerrar_menu()
		ejecutar(entrada.id, fuente)


func recibir_accion(accion: Dictionary) -> void:
	if panel.conexion.pausado() or motor == null or not motor.fin().is_empty():
		return
	match accion.accion:
		"bloqueo", "etiquetado":
			sincronizar_fuente_seguridad()
			if accion.fuente_entrada == "panel" and fuente_seguridad == "panel":
				seguridad_panel[accion.accion] = accion.valor == 1
				if datos.zona == "motor":
					actualizar_leds()
		"inspeccionar":
			if not menu_pieza.visible and is_instance_valid(pieza_apuntada):
				abrir_menu(pieza_apuntada)
		"elegir-accion":
			elegir_accion(int(accion.valor) - 1, accion.get("fuente_entrada", "teclado"))
		"cancelar":
			if menu_pieza.visible:
				cerrar_menu()
		"confirmar":
			if not accion_pendiente.is_empty():
				var id := accion_pendiente
				cerrar_menu()
				ejecutar(id, accion.fuente_entrada)


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
	sincronizar_fuente_seguridad()
	lateral.get_node("Conexion").text = panel.conexion.etiqueta()
	var pausa: bool = panel.conexion.pausado()
	if pausa != pausa_visible:
		pausa_visible = pausa
		jugador.activo = not pausa and motor != null and motor.fin().is_empty()
		if pausa:
			cerrar_menu()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var continuar: Button = lateral.get_node("Continuar")
		continuar.visible = pausa
		actualizar_hud()
		if pausa:
			continuar.grab_focus()
	$AlternarPanel.visible = panel.conexion.fuente_panel() == "virtual" and not pausa \
		and motor != null and motor.fin().is_empty()
	$AlternarPanel.text = "Mostrar panel virtual" if panel_oculto else "Ocultar panel virtual"
	panel.visible = $AlternarPanel.visible and not panel_oculto


func controles_seguridad() -> Dictionary:
	if fuente_seguridad == "virtual":
		return {"bloqueo": panel.get_node("Bloqueo").button_pressed,
			"etiquetado": panel.get_node("Etiquetado").button_pressed}
	return seguridad_panel


func sincronizar_fuente_seguridad() -> void:
	var fuente: String = panel.conexion.fuente_panel()
	if fuente == fuente_seguridad:
		return
	fuente_seguridad = fuente
	seguridad_panel.clear()
	if fuente == "virtual":
		panel.get_node("Bloqueo").set_pressed_no_signal(false)
		panel.get_node("Etiquetado").set_pressed_no_signal(false)


func _unhandled_input(evento: InputEvent) -> void:
	# Un clic en la escena (fuera de los paneles) recupera el ratón si la ventana no lo tenía capturado.
	if motor != null and motor.fin().is_empty() and not pausa_visible and not menu_pieza.visible \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _input(evento: InputEvent) -> void:
	if motor == null or not motor.fin().is_empty() or not evento.is_pressed() or evento.is_echo():
		return
	var capturado := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var accion := {}
	if evento is InputEventKey:
		if evento.keycode == KEY_TAB and not pausa_visible and not menu_pieza.visible:
			var foco := get_viewport().gui_get_focus_owner()
			if not capturado and foco != null:
				foco.release_focus()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if capturado else Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		var tecla := "Enter" if evento.keycode == KEY_KP_ENTER else OS.get_keycode_string(evento.keycode)
		accion = panel.entrada.traducir("teclado", tecla, 1)
		if accion.get("accion") not in ["elegir-accion", "confirmar", "cancelar"]:
			return
		if not menu_pieza.visible or (accion.accion == "confirmar" and accion_pendiente.is_empty()):
			return
	elif capturado and evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		accion = panel.entrada.traducir("teclado", "clic", 1)
	elif evento is InputEventJoypadButton:
		match evento.button_index:
			JOY_BUTTON_A:
				if menu_pieza.visible and not menu_pieza.causa.get_popup().visible \
						and menu_pieza.elegir_con_control():
					get_viewport().set_input_as_handled()
					return
				if capturado:
					accion = panel.entrada.traducir("control", "A", 1)
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				if menu_pieza.visible and not menu_pieza.causa.get_popup().visible:
					menu_pieza.mover_foco(1 if evento.button_index == JOY_BUTTON_DPAD_DOWN else -1)
					get_viewport().set_input_as_handled()
					return
			JOY_BUTTON_X:
				accion = panel.entrada.traducir("control", "X", 1)
			JOY_BUTTON_B:
				accion = panel.entrada.traducir("control", "B", 1)
	if not accion.is_empty():
		recibir_accion(accion)
		get_viewport().set_input_as_handled()
