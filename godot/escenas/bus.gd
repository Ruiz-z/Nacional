extends Node3D

signal decision_tomada(decision: Dictionary)
signal salida_solicitada

const ANCHO_HUD := 352.0
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
const FuenteBanco = preload("res://logica/simulador/fuente_banco.gd")
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
var fuente_banco := FuenteBanco.new()
var _udp_banco := PacketPeerUDP.new()
var tecnico := {}
var resultados_guardados := false
var pausa_visible := false
var hud_oculto := false
var salida_hasta := 0
var panel_oculto := false
var modo_captura := false
var zona_activa: Node3D
var navegando := false
var seguridad_panel := {}
var fuente_seguridad := ""
@onready var interior := $Interior
@onready var puerta_pasajeros: Interactuable = $PuertaPasajeros
@onready var negro: ColorRect = $Fundido/Negro
@onready var zonas := {"gabinete": $Sector, "cabina": interior, "faros": $Faros, "motor": $Motor, "banco": $Banco}
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
	var fondo := lateral.get_theme_stylebox("panel", "PanelContainer").duplicate() as StyleBoxFlat
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		fondo.set_content_margin(lado, 12)
	$Interfaz.add_theme_stylebox_override("panel", fondo)
	FondoTarjeta.aplicar(panel, 16)
	var pista := create_tween()
	pista.tween_property($PistaControles, "modulate:a", 0.0, 0.5).set_delay(7.5)
	pista.tween_callback($PistaControles.hide)
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
	if datos.zona == "banco":
		motor = Motor.new(datos, fuente_banco.leer)
		if "--banco-fisico" in OS.get_cmdline_user_args():
			if _udp_banco.bind(FuenteBanco.PUERTO_UDP, "127.0.0.1") != OK:
				lateral.get_node("Aviso").text = "No se pudo abrir el enlace del banco · falla virtual"
	else:
		motor = Motor.new(datos)
	ultimo_ms = Time.get_ticks_msec()
	menu_pieza.elegida.connect(elegir_accion)
	menu_pieza.cierre_solicitado.connect(cerrar_menu)
	menu_pieza.lectura_reportada.connect(ejecutar)
	menu_pieza.causa_marcada.connect(func(causa: String):
		if motor.marcar_causa(causa):
			causa_marcada = causa)
	duracion_aviso.timeout.connect(resultado.hide)
	zona_activa = zonas[datos.zona]
	puerta_pasajeros.componente = "puerta_pasajeros"
	puerta_pasajeros.nombre = "Puerta de pasajeros"
	if zona_activa != $Banco:
		$Banco.mostrar_multimetro("—", "Módulo disponible", "virtual")
	for zona in [$Faros, $Motor]:
		if zona != zona_activa:
			zona.reflejar_estado({}, false, true)
	if not modo_captura:
		ubicar_jugador(zona_activa.acceso)
	lateral.get_node("Continuar").pressed.connect(func():
		panel.conexion.reanudar()
		ultimo_ms = Time.get_ticks_msec()
		actualizar_panel(ultimo_ms))
	panel.accion_recibida.connect(recibir_accion)
	if datos.zona == "motor":
		panel.get_node("Bloqueo").toggled.connect(func(_activo: bool): actualizar_leds())
	resumen.reintento_solicitado.connect(reintentar)
	lateral.minimum_size_changed.connect(actualizar_hud)
	mostrar_estado(true)
	actualizar_panel(ultimo_ms)


func ubicar_jugador(componente: String) -> void:
	if zona_activa == interior:
		ubicar_interior(interior.CABINA, componente)
		return
	var objetivo: Node3D = zona_activa.piezas[componente]
	var origen := zona_activa.to_global(Vector3(1.8, 0, 0))
	if zona_activa in [$Faros, $Motor, $Banco]:
		var centro := zona_activa.to_local(objetivo.global_position)
		var desnivel: float = jugador.camara.position.y - objetivo.global_position.y
		var distancia := sqrt(maxf(0.0, 1.6 * 1.6 - desnivel * desnivel))
		origen = zona_activa.to_global(centro + Vector3(distancia, 0, 0))
	jugador.ubicar(Vector3(origen.x, 0, origen.z))
	if zona_activa == $Sector:
		jugador.global_position.z = objetivo.global_position.z
	apuntar_jugador(objetivo.global_position)


func ubicar_interior(origen: Vector3, componente: String) -> void:
	jugador.ubicar(interior.to_global(origen), interior.position,
		Rect2(interior.MINIMO, interior.MAXIMO - interior.MINIMO))
	apuntar_jugador(interior.piezas[componente].global_position)


func apuntar_jugador(objetivo: Vector3) -> void:
	jugador.look_at(Vector3(objetivo.x, jugador.global_position.y, objetivo.z))
	jugador.camara.look_at(objetivo)


func navegar(destino: String) -> void:
	navegando = true
	cerrar_menu()
	jugador.activo = false
	negro.modulate.a = 0.0
	negro.show()
	var fundido := create_tween()
	fundido.tween_property(negro, "modulate:a", 1.0, 0.2)
	fundido.tween_callback(func():
		if destino == "subir":
			ubicar_interior(interior.ENTRADA, "puerta_salida")
		else:
			jugador.ubicar(Vector3(-2.65, 0, puerta_pasajeros.global_position.z))
			apuntar_jugador(puerta_pasajeros.global_position))
	fundido.tween_property(negro, "modulate:a", 0.0, 0.2)
	await fundido.finished
	negro.hide()
	navegando = false
	if not pausa_visible:
		jugador.activo = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func ejecutar(id: String, fuente: String, lectura_previa: Dictionary = {}) -> void:
	if motor == null or (panel.conexion.pausado() and fuente != "banco"):
		return
	var ahora := Time.get_ticks_msec()
	sincronizar_fuente_seguridad()
	var decision: Dictionary = motor.ejecutar(id, fuente, ahora - ultimo_ms, controles_seguridad(), lectura_previa)
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
	elif decision.has("punto_medido"):
		texto = "Medición registrada: %s = %.1f V" % [
			decision.punto_medido.to_upper(), decision.lectura_mostrada]
	elif decision.has("lectura-reportada"):
		texto = "Lecturas reportadas guardadas"
	elif texto.is_empty():
		var id: String = decision.get("accion", "")
		if id == "inspeccionar" and zona_activa != $Sector:
			texto = "%s abierta" % zona_activa.piezas[zona_activa.acceso].nombre
		elif id.begins_with("diagnosticar_"):
			texto = "Diagnóstico registrado"
		elif id == "reconectar":
			texto = "Conductor reconectado"
		else:
			texto = RESULTADOS.get(id, "Acción completada")
	avisar(texto, decision.has("lectura-reportada"))


func avisar(texto: String, sobre_menu := false) -> void:
	resultado.text = texto
	resultado.visible = sobre_menu or not menu_pieza.visible
	duracion_aviso.start()


func mostrar_estado(inmediato := false) -> void:
	var estado: Dictionary = motor.estado()
	var terminado: bool = not motor.fin().is_empty()
	jugador.activo = not terminado and not pausa_visible and not navegando and not menu_pieza.visible
	if terminado:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var lineas := PackedStringArray()
	for clave in INDICIOS:
		if estado.has(clave):
			lineas.append("%s %s" % ["✓" if estado[clave] else "—", INDICIOS[clave]])
	var orden: Label = lateral.get_node("Estado")
	orden.text = datos.titulo.trim_prefix("[MUESTRA] ")
	orden.tooltip_text = orden.text
	var falla: bool = motor.hay_problemas() or motor.fin() == "falta-critica"
	# La captura cambia el encuadre. Las acciones conservan el Tween para mostrar fallos de apertura.
	zona_activa.reflejar_estado(estado, falla, inmediato)
	if zona_activa == $Banco:
		actualizar_banco()
		interior.mostrar_modulo_auxiliar(estado.resuelto)
		lineas.append("Fuente: %s · TP0 primero, luego TP1 o TP2." % $Banco.etiqueta_fuente(motor.mediciones.fuente))
	lateral.get_node("Indicios").text = "\n".join(lineas)
	actualizar_leds()
	actualizar_hud()
	resumen.mostrar(motor)


func actualizar_leds() -> void:
	var estado: Dictionary = motor.estado()
	var bloqueado: Variant = estado.get("bloqueo_puesto")
	if datos.zona == "motor":
		bloqueado = controles_seguridad().get("bloqueo", false)
	panel.mostrar_leds({"energizado": estado.get("energizado"), "bloqueado": bloqueado,
		"falla": motor.hay_problemas() or motor.fin() == "falta-critica"
			or (zona_activa == $Banco and not estado.resuelto)})


func actualizar_hud() -> void:
	var terminado: bool = motor != null and not motor.fin().is_empty()
	var aviso: Control = lateral.get_node("Aviso")
	aviso.visible = not aviso.text.is_empty()
	var detalle := not terminado and not hud_oculto
	$Interfaz.visible = detalle or terminado or pausa_visible or aviso.visible
	$Interfaz.offset_right = 476.0 if terminado else 12.0 + ANCHO_HUD
	$Interfaz.anchor_bottom = 1.0 if terminado else 0.0
	lateral.get_node("Estado").visible = detalle
	lateral.get_node("Indicios").visible = detalle
	lateral.get_node("Conexion").visible = pausa_visible
	var margen: float = $Interfaz.get_theme_stylebox("panel").get_minimum_size().y
	$Interfaz.offset_bottom = -12.0 if terminado else 12.0 + lateral.get_combined_minimum_size().y + margen


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
	if motor == null or not motor.fin().is_empty() or pausa_visible or navegando or not accion_pendiente.is_empty():
		return
	var opciones: Array[Dictionary] = []
	var causas: Array = []
	var lectura := "[MUESTRA] Sin falla en esta orden"
	match pieza.componente:
		"puerta_pasajeros":
			opciones.append(MenuPieza.navegacion("subir", "Subir al autobús"))
			lectura = ""
		"puerta_salida":
			opciones.append(MenuPieza.navegacion("bajar", "Bajar del autobús"))
			lectura = ""
	if opciones.is_empty() and pieza.zona == zona_activa:
		opciones = MenuPieza.entradas(motor, datos, pieza.componente)
		if zona_activa != $Sector or not opciones.is_empty():
			lectura = zona_activa.lectura_pieza(pieza.componente)
		if motor.estado().get("inspeccionado", motor.estado().get("sintomas_revisados", false)):
			causas = datos.causas
	elif opciones.is_empty() and pieza.zona == interior:
		lectura = interior.lectura_pieza(pieza.componente)
	salida_hasta = 0
	resultado.hide()
	var banco := zona_activa == $Banco and pieza.zona == $Banco and pieza.componente == "multimetro"
	var reportadas: Dictionary = motor.mediciones.reportadas if banco else {}
	menu_pieza.abrir(pieza.nombre, lectura, opciones, causas, causa_marcada, estado_pieza(pieza), reportadas, banco)
	jugador.activo = false
	$Apuntado.hide()


func estado_pieza(pieza: Interactuable) -> Dictionary:
	if pieza.zona == interior and pieza.componente == "monitor" and interior.falla_auxiliar:
		return {"texto": "Falla", "color": "rojo"}
	if pieza.zona != zona_activa:
		return {"texto": "Correcto", "color": "verde"}
	var estado: Dictionary = motor.estado()
	var componente := pieza.componente
	match componente:
		"terminal", "abrazadera_motor":
			var clave := "tornillo_roto" if componente == "terminal" else "pieza_danada"
			if estado.get(clave, false):
				return {"texto": "Daño", "color": "rojo"}
		"fusible_faros":
			if estado.get("fusible_quemado", false):
				return {"texto": "Falla", "color": "rojo"}
		"faro_izquierdo", "faro_derecho":
			if not estado.get(componente, true):
				return {"texto": "Falla", "color": "rojo"}
		"monitor":
			if pieza.zona == interior:
				return {"texto": "Falla", "color": "rojo"} if interior.falla_red else {"texto": "Correcto", "color": "verde"}
			match zona_activa.lectura:
				"Rojo": return {"texto": "Falla", "color": "rojo"}
				"Ámbar": return {"texto": "Alerta", "color": "ambar"}
		"monitor_temperatura", "motor_traccion":
			if estado.get("alerta_temperatura", false):
				return {"texto": "Alerta", "color": "ambar"}
	return {"texto": "Correcto", "color": "verde"}


func cerrar_menu() -> void:
	accion_pendiente = ""
	menu_pieza.cerrar()
	jugador.mostrar_herramienta("")
	if not navegando and not pausa_visible and motor != null and motor.fin().is_empty():
		jugador.activo = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func elegir_accion(indice: int, fuente: String) -> void:
	if not menu_pieza.visible or not accion_pendiente.is_empty() or panel.conexion.pausado() \
			or indice < 0 or indice >= menu_pieza.entradas.size():
		return
	var entrada: Dictionary = menu_pieza.entradas[indice]
	if entrada.get("navegacion", false):
		navegar(entrada.id)
	elif entrada.requiere_panel:
		accion_pendiente = entrada.id
		if panel.conexion.fuente_panel() == "virtual":
			panel_oculto = false
			actualizar_panel(Time.get_ticks_msec())
		menu_pieza.esperar_panel(entrada.id == "reconectar" and fuente_banco.fuente() == "banco")
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
			if not menu_pieza.visible and jugador.activo:
				# El aviso usa el rayo del último paso físico. El clic puede llegar antes
				# del primer paso o justo después de mover la cámara.
				alcance.force_raycast_update()
				var pieza := alcance.get_collider() as Interactuable
				if zona_activa == $Banco and (pieza != null and pieza.zona == $Banco
						and pieza.componente in ["tp0", "tp1", "tp2"]):
					tocar_borne(pieza.componente, accion.fuente_entrada)
				else:
					if zona_activa == $Banco and not motor.mediciones.punta_negra.is_empty():
						tocar_borne("", accion.fuente_entrada)
					if pieza != null:
						abrir_menu(pieza)
		"elegir-accion":
			elegir_accion(int(accion.valor) - 1, accion.get("fuente_entrada", "teclado"))
		"cancelar":
			if menu_pieza.visible:
				cerrar_menu()
		"confirmar":
			if not accion_pendiente.is_empty():
				if accion_pendiente == "reconectar" and fuente_banco.fuente() == "banco":
					return
				if zona_activa == $Banco and accion.fuente_entrada in ["teclado", "control"]:
					if panel.conexion.fuente_panel() == "virtual":
						panel.emitir("confirmar", 1)
					return
				var id := accion_pendiente
				cerrar_menu()
				ejecutar(id, accion.fuente_entrada)


func tocar_borne(punto: String, fuente: String) -> void:
	var id: String = motor.mediciones.tocar(punto)
	jugador.mostrar_herramienta("medir_banco")
	if not id.is_empty():
		ejecutar(id, fuente)
	else:
		actualizar_banco()
		if not motor.mediciones.aviso_puntas.is_empty():
			avisar(motor.mediciones.aviso_puntas)


func actualizar_banco() -> void:
	var mediciones: RefCounted = motor.mediciones
	var lectura: Dictionary = mediciones.leer.call(motor.estado())
	$Banco.mostrar_multimetro(mediciones.pantalla, lectura.aviso, mediciones.fuente)


func recibir_banco(linea: String, ahora: int) -> void:
	var lectura_previa := fuente_banco.recibir(linea, ahora)
	sincronizar_banco()
	if not lectura_previa.is_empty() and motor.fin().is_empty():
		cerrar_menu()
		ejecutar("reconectar", "banco", lectura_previa)


func sincronizar_banco() -> void:
	if motor.mediciones.fuente != fuente_banco.fuente():
		motor.mediciones.fuente = fuente_banco.fuente()
		if accion_pendiente == "reconectar":
			menu_pieza.esperar_panel(motor.mediciones.fuente == "banco")
		mostrar_estado()
	else:
		actualizar_banco()


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()
	actualizar_panel(ahora)
	if zona_activa != $Banco:
		return
	var fuente_anterior := fuente_banco.fuente()
	var aviso_anterior: String = fuente_banco.conexion.aviso()
	fuente_banco.actualizar(ahora)
	if fuente_anterior != fuente_banco.fuente() or aviso_anterior != fuente_banco.conexion.aviso():
		sincronizar_banco()
	if aviso_anterior != fuente_banco.conexion.aviso() and not fuente_banco.conexion.aviso().is_empty():
		avisar(fuente_banco.conexion.aviso(), true)
	if not _udp_banco.is_bound():
		return
	for indice in range(mini(_udp_banco.get_available_packet_count(), 64)):
		recibir_banco(_udp_banco.get_packet().get_string_from_utf8(), ahora)


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
	_udp_banco.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func actualizar_panel(ahora: int) -> void:
	panel.conexion.actualizar(ahora)
	sincronizar_fuente_seguridad()
	lateral.get_node("Conexion").text = panel.conexion.etiqueta()
	var pausa: bool = panel.conexion.pausado()
	if pausa != pausa_visible:
		pausa_visible = pausa
		jugador.activo = not pausa and not navegando and motor != null and motor.fin().is_empty()
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
	var registro_banco: bool = zona_activa == $Banco and menu_pieza.visible and accion_pendiente.is_empty()
	panel.visible = $AlternarPanel.visible and not panel_oculto and not registro_banco


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
	if navegando or motor == null or not evento.is_pressed() or evento.is_echo():
		return
	if evento is InputEventKey:
		if evento.keycode == KEY_ESCAPE and not menu_pieza.visible:
			var ahora := Time.get_ticks_msec()
			get_viewport().set_input_as_handled()
			if ahora < salida_hasta:
				salida_hasta = 0
				salida_solicitada.emit()
			else:
				avisar("Esc de nuevo para salir")
				salida_hasta = ahora + int(duracion_aviso.wait_time * 1000)
			return
		if evento.keycode == KEY_H and motor.fin().is_empty():
			hud_oculto = not hud_oculto
			actualizar_hud()
			get_viewport().set_input_as_handled()
			return
		if menu_pieza.visible and evento.keycode in [KEY_UP, KEY_DOWN]:
			menu_pieza.mover_foco(1 if evento.keycode == KEY_DOWN else -1)
			get_viewport().set_input_as_handled()
			return
	if not motor.fin().is_empty():
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
	elif (capturado or (modo_captura and not menu_pieza.visible)) \
			and evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		accion = panel.entrada.traducir("teclado", "clic", 1)
	elif evento is InputEventJoypadButton:
		match evento.button_index:
			JOY_BUTTON_A:
				if menu_pieza.visible and menu_pieza.elegir_con_control():
					get_viewport().set_input_as_handled()
					return
				if capturado:
					accion = panel.entrada.traducir("control", "A", 1)
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				if menu_pieza.visible:
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
