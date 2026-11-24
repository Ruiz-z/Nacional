extends Node3D

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal decision_tomada(decision: Dictionary)
signal resultados_registrados
signal salida_solicitada

const ANCHO_HUD := 440.0
const FONDO_MISION := Color("#11507D")
const Hoja = preload("res://escenas/hoja_diagnostico.gd")
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const PASOS_ELEVADOR := {
	"colocar_calzas": "Coloca las calzas",
	"elevar_bus": "Sube el autobús en la consola",
	"trabar_soporte": "Traba el soporte",
	"destrabar_soporte": "Destraba el soporte",
	"descender_bus": "Baja el autobús en la consola",
}
const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")
const INDICIOS := {
	"inspeccionado": "Gabinete inspeccionado",
	"continuidad_medida": "Continuidad medida",
	"refrigerante_revisado": "Circuito de refrigerante revisado",
	"temperatura_medida": "Temperatura medida",
	"indicio_confirmado": "Aislamiento revisado",
	"sintomas_revisados": "Síntomas de red revisados",
	"resuelto": "Falla resuelta",
}
const PREVIAS := {
	"faro_izquierdo": "Faro izquierdo encendido",
	"faro_derecho": "Faro derecho encendido",
	"fusible_quemado": "Fusible correcto instalado",
	"chispa": "Chispa eliminada",
	"pieza_danada": "Abrazadera dañada repuesta",
	"alerta_temperatura": "Alerta de temperatura eliminada",
	"tornillo_roto": "Tornillo repuesto",
	"sector_equivocado": "Gabinete correcto",
	"indicio_descartado": "Lectura recuperada",
}
const PROBLEMAS := {
	"tornillo_roto": "Pieza dañada",
	"fusible_quemado": "Fusible quemado",
	"pieza_danada": "Abrazadera dañada",
	"alerta_temperatura": "Alerta de temperatura",
	"sector_equivocado": "Gabinete equivocado",
	"indicio_descartado": "Lectura descartada",
}
const Inventario = preload("res://logica/simulador/inventario.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Practica = preload("res://logica/simulador/practica.gd")
const MenuPieza = preload("res://logica/simulador/menu_pieza.gd")
const MenuVisual = preload("res://escenas/menu_pieza.gd")
const FuenteBanco = preload("res://logica/simulador/fuente_banco.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Elevador = preload("res://escenas/elevador.gd")
const ZonaBase = preload("res://escenas/zona_base.gd")
const Interactuable = preload("res://escenas/interactuable.gd")

@export_file("*.json") var archivo := Escenario.AISLAMIENTO
var motor: RefCounted
var datos: Dictionary
var indicios := {}
var misiones: Array = []
var hoja: Hoja
var indicador_puntas: Label
var acciones_mision := {}
var firma_mision: Array = []
var subpaso_guia := {}
var objetos_requeridos: Array[String] = []
static var preferencia_guia_automatica := true
var guia_automatica := preferencia_guia_automatica
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
var zona_menu: ZonaBase
var navegando := false
var seguridad_panel := {}
var torque_fisico := -1.0
var fuente_seguridad := ""
var requisito_pendiente := ""
var inicio_flashcard := 0
var inicio_cierre := 0
var activo_antes_flashcard := false
var navegando_antes_flashcard := false
var raton_antes_flashcard: Input.MouseMode
var foco_antes_flashcard: Control
var pieza_menu: Interactuable
@onready var taller := $Taller
@onready var interior := $Interior
@onready var puerta_pasajeros: Interactuable = $PuertaPasajeros
@onready var negro: ColorRect = $Fundido/Negro
@onready var zonas := {"gabinete": $Sector, "cabina": interior, "faros": $Faros, "motor": $Motor, "banco": $Banco, "bajos": $Bajos}
@onready var jugador := $Jugador
@onready var alcance: RayCast3D = $Jugador/Camara/Alcance
@onready var resumen := $Resumen
@onready var lateral := $Interfaz/Lateral
@onready var hud_mision := $Interfaz/Lateral/Mision
@onready var menu_pieza := $MenuPieza
@onready var flashcard := $Flashcard
@onready var resultado: Label = $AvisoCentral/Resultado
@onready var duracion_aviso: Timer = $AvisoCentral/Duracion
@onready var panel := $AlineacionPanel/PanelVirtual


func _ready() -> void:
	var carga_elevador: Array[Node3D] = [$Autobus, $Sector, $Faros, $Motor, $PuertaPasajeros, $Bajos]
	$Elevador.configurar(carga_elevador, $Colisiones/Casco, $Bajos)
	$Bajos.acceso = Elevador.CONSOLA
	jugador.configurar(panel.entrada)
	jugador.activo = false
	var fondo := lateral.get_theme_stylebox("panel", "PanelContainer").duplicate() as StyleBoxFlat
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		fondo.set_content_margin(lado, 12)
	fondo.bg_color = FONDO_MISION
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
		push_warning(str(carga.errores))
		$Interfaz/Lateral/Estado.text = "No se abrió la orden. Vuelve al menú y elige otra."
		return
	indicios = INDICIOS
	if datos.has("indicios"):
		indicios = {}
		for indicio in datos.indicios:
			if indicio.has("clave"):
				indicios[indicio.clave] = indicio.etiqueta
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if datos.zona == "banco":
		motor = Motor.new(datos, fuente_banco.leer)
		if "--banco-fisico" in OS.get_cmdline_user_args():
			if _udp_banco.bind(FuenteBanco.PUERTO_UDP, "127.0.0.1") != OK:
				lateral.get_node("Aviso").text = "No se conectó el banco físico. Continúa con el banco en pantalla."
	else:
		motor = Motor.new(datos)
	ultimo_ms = Time.get_ticks_msec()
	menu_pieza.elegida.connect(elegir_accion)
	menu_pieza.cierre_solicitado.connect(cerrar_menu)
	menu_pieza.causa_marcada.connect(func(causa: String):
		if motor.marcar_causa(causa):
			causa_marcada = causa)
	duracion_aviso.timeout.connect(func():
		salida_hasta = 0
		resultado.hide())
	flashcard.abierta.connect(pausar_por_flashcard)
	flashcard.confirmada.connect(func(aviso: Dictionary):
		if guia_automatica and aplicar_guia():
			return
		if not aviso.objeto.is_empty():
			senalar_guia(aviso.objeto))
	flashcard.opcion_elegida.connect(responder_cierre)
	flashcard.terminada.connect(reanudar_tras_flashcard)
	zona_activa = zonas[datos.zona]
	puerta_pasajeros.componente = "puerta_pasajeros"
	puerta_pasajeros.nombre = "Puerta de pasajeros"
	if datos.get("ubicacion_inicial", {}).has("multimetro"):
		taller.ubicar_multimetro_en_banco($Banco)
	if zona_activa != $Banco:
		$Banco.mostrar_fuente("Módulo disponible", "virtual")
	else:
		hoja = Hoja.new()
		add_child(hoja)
		hoja.guardada.connect(guardar_hoja)
		hoja.cancelada.connect(cerrar_menu)
		indicador_puntas = Label.new()
		indicador_puntas.add_theme_font_size_override("font_size", 15)
		var columna: Node = hud_mision.titulo.get_parent()
		columna.add_child(indicador_puntas)
		columna.move_child(indicador_puntas, hud_mision.titulo.get_index() + 1)
	for zona in [$Faros, $Motor]:
		if zona != zona_activa:
			zona.reflejar_estado({}, false, true)
	configurar_misiones()
	get_viewport().size_changed.connect(actualizar_hud)
	if not modo_captura:
		ubicar_jugador(zona_activa.acceso)
		if zona_activa == $Banco and $Banco.piezas.multimetro.visible:
			apuntar_jugador($Banco.piezas.multimetro.global_position)
	lateral.get_node("Continuar").pressed.connect(func():
		panel.conexion.reanudar()
		ultimo_ms = Time.get_ticks_msec()
		actualizar_panel(ultimo_ms))
	panel.accion_recibida.connect(recibir_accion)
	if datos.zona == "motor":
		panel.get_node("Bloqueo").toggled.connect(func(_activo: bool): actualizar_leds())
	resumen.reintento_solicitado.connect(reintentar)
	resumen.salida_solicitada.connect(func(): salida_solicitada.emit())
	lateral.minimum_size_changed.connect(actualizar_hud)
	mostrar_estado(true)
	actualizar_panel(ultimo_ms)
	mostrar_orden()


func mostrar_orden() -> void:
	if datos.has("briefing"):
		flashcard.encolar({"tipo": "orden", "titulo": datos.titulo, "briefing": datos.briefing,
			"texto": "", "donde": "", "fuente": "", "objeto": ""})


func ubicar_jugador(componente: String) -> void:
	if zona_activa == interior:
		ubicar_interior(interior.CABINA, componente)
		return
	var objetivo: Node3D = $Elevador.piezas[componente] if componente == Elevador.CONSOLA \
		else zona_activa.piezas[componente]
	var origen := zona_activa.to_global(Vector3(1.8, 0, 0))
	if zona_activa == $Bajos:
		origen = objetivo.global_position + Vector3(-1.25, 0, 0)
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
	if destino == "subir" and $Elevador.arriba:
		cerrar_menu()
		avisar("Baja el autobús antes de entrar.", "aviso", "Comprueba el elevador")
		return
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
	if not pausa_visible and not flashcard.visible:
		jugador.activo = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func ejecutar(id: String, fuente: String, lectura_previa: Dictionary = {}) -> void:
	if flashcard.visible or hoja_abierta() or motor == null or (panel.conexion.pausado() and fuente != "banco"):
		return
	var bajos: bool = zona_activa == $Bajos
	sincronizar_fuente_seguridad()
	var controles := controles_seguridad()
	if bajos:
		if id == "cerrar_orden":
			if $Elevador.arriba or $Elevador.en_movimiento():
				avisar("Baja el autobús antes de cerrar la orden.", "aviso", "Comprueba el elevador")
				return
		elif not $Elevador.arriba or $Elevador.en_movimiento():
			avisar("Sube el autobús para acceder a los bajos.", "aviso", "Comprueba el elevador")
			return
		controles["elevador_seguro"] = $Elevador.seguro()
		if fuente_seguridad == "virtual":
			controles["torque"] = panel.get_node("Torque").value
		elif torque_fisico >= 0.0:
			controles["torque"] = torque_fisico
	if (not bajos or id == "cerrar_orden" or controles.elevador_seguro) and not comprobar_inventario(id, fuente):
		return
	var ahora := Time.get_ticks_msec()
	var decision: Dictionary = motor.ejecutar(id, fuente, ahora - ultimo_ms, controles, lectura_previa)
	ultimo_ms = ahora
	if decision.get("aplicada", false):
		taller.consumir(requisitos(id), carrito_cerca())
		if requisito_pendiente == id:
			requisito_pendiente = ""
	var zona := zona_activa as ZonaBase
	if zona != null and zona.apertura_manual == false:
		var regla: Dictionary = datos.acciones.get(id, datos.recuperaciones.get(id, {}))
		if not regla.is_empty() and (id == "inspeccionar" \
				or zona.es_pieza_interna(regla.get("componente", "bateria"))):
			zona.cambiar_acceso(true)
	mostrar_resultado(decision)
	actualizar_inventario()
	actualizar_mision()
	if not hud_mision.celebrando and (not motor.pendiente_diagnostico() or not flashcard.visible):
		finalizar_orden()
	mostrar_estado()
	decision_tomada.emit(decision)


func finalizar_orden() -> void:
	if motor.fin().is_empty():
		return
	if motor.pendiente_diagnostico():
		inicio_cierre = Time.get_ticks_msec()
		flashcard.encolar({"tipo": "cierre", "titulo": "¿Qué causó la falla?", "texto": "",
			"fuente": "", "marca": datos.titulo, "donde": "", "objeto": "", "opciones": datos.causas.map(MenuVisual.nombre_causa)})
		return
	guardar_resultados()


func guardar_resultados() -> void:
	if not tecnico.is_empty() and not resultados_guardados:
		resultados_guardados = Practica.guardar(tecnico.base, tecnico.id, tecnico.alias, motor,
			int(Time.get_unix_time_from_system()))
		if resultados_guardados:
			resultados_registrados.emit()
		else:
			lateral.get_node("Aviso").text = "No se guardó el resultado. Vuelve a intentar la práctica."


func responder_cierre(indice: int, fuente: String) -> void:
	if indice < 0 or indice >= datos.causas.size() or not flashcard.visible:
		return
	var cierre: Dictionary = motor.registrar_diagnostico(datos.causas[indice], fuente,
		Time.get_ticks_msec() - inicio_cierre)
	if cierre.is_empty():
		return
	var tipo := "correcto" if cierre.correcto else "incorrecto"
	flashcard.mostrar_respuesta({"tipo": tipo, "titulo": tipo.capitalize(), "donde": "", "objeto": "",
		"texto": "Causa real: %s\n%s" % [MenuVisual.nombre_causa(cierre.real), cierre.explicacion],
		"fuente": cierre.fuente, "marca": datos.titulo})
	guardar_resultados()


func requisitos(id: String) -> Dictionary:
	match id:
		"elevar_bus", "colocar_calzas":
			return {"herramienta": "calzas"}
		"trabar_soporte", "destrabar_soporte":
			return {"herramienta": "llave_ajustable"}
	var regla: Dictionary = datos.acciones.get(id, datos.recuperaciones.get(id, {}))
	return regla.get("requiere", {})


func carrito_cerca() -> bool:
	return taller.cerca(jugador.global_position)


func comprobar_inventario(id: String, fuente := "teclado", solo_guia := false) -> bool:
	if not motor.fin().is_empty() or (datos.recuperaciones.has(id)
			and not motor.recuperaciones_disponibles().has(id)):
		return true
	var requiere := requisitos(id)
	var herramienta: String = requiere.get("herramienta", "")
	var cerca := carrito_cerca()
	var faltantes: Array[String] = taller.inventario.faltantes(requiere, cerca)
	var numero: int = taller.espacio_de(herramienta) if not herramienta.is_empty() else 0
	if numero > 0:
		faltantes.erase(herramienta)
	var equipada: bool = herramienta.is_empty() or (taller.mano == herramienta and (numero <= 4 or cerca))
	if not faltantes.is_empty() and (numero == 0 or equipada or solo_guia):
		requisito_pendiente = id
		if menu_pieza.visible:
			cerrar_menu()
		avisar_objeto("Toma lo que te falta: " + taller.nombres(faltantes), "falta", "Te falta algo", faltantes[0])
		return false
	if equipada:
		return true
	requisito_pendiente = id
	if menu_pieza.visible:
		cerrar_menu()
	var nombre: String = Inventario.CATALOGO[herramienta].nombre
	var mano: Dictionary = Inventario.objeto(taller.mano)
	if not solo_guia and taller.mano != herramienta and mano.get("tipo") == "herramienta" 			and (cerca or taller.mano in taller.inventario.cinturon):
		var texto := "Traes esta herramienta: %s. Cámbiala por esta: %s." % [mano.nombre, nombre]
		var ahora := Time.get_ticks_msec()
		var decision: Dictionary = motor.registrar_herramienta_equivocada(id, fuente, ahora - ultimo_ms, texto)
		ultimo_ms = ahora
		avisar(texto, "error", "Herramienta equivocada")
		if not motor.fin().is_empty():
			finalizar_orden()
		decision_tomada.emit(decision)
	elif numero > 4 and not cerca:
		avisar_objeto("El carrito está lejos. Acércate y presiona %d para tomar %s." % [numero, nombre],
			"aviso", "Toma la herramienta en la mano", herramienta)
	else:
		avisar("Presiona %d para tomar la herramienta." % numero,
			"aviso", "Selecciona " + nombre)
	return false


func senalar_guia(objetivo: String) -> void:
	taller.senalar(objetivo, $Elevador.piezas.get(objetivo))


func listo_para_bajar(estado: Dictionary) -> bool:
	return estado.resuelto or Escenario.cumple(estado, datos.acciones.cerrar_orden.previas)


func paso_elevador(estado: Dictionary) -> Dictionary:
	if zona_activa != $Bajos or not motor.fin().is_empty() or $Elevador.en_movimiento():
		return {}
	var listo := listo_para_bajar(estado)
	if $Elevador.arriba:
		for soporte in $Elevador.trabas:
			if $Elevador.trabas[soporte] == listo:
				return {"id": "destrabar_soporte" if listo else "trabar_soporte", "objetivo": soporte}
		if listo:
			return {"id": "descender_bus", "objetivo": Elevador.CONSOLA}
	elif listo:
		return {"id": "cerrar_orden", "objetivo": Elevador.CONSOLA}
	elif not $Elevador.calzas_colocadas:
		var objetivo := Elevador.CALZAS if "calzas" in taller.inventario.accesibles(carrito_cerca()) else "calzas"
		return {"id": "colocar_calzas", "objetivo": objetivo}
	else:
		return {"id": "elevar_bus", "objetivo": Elevador.CONSOLA}
	return {}


func orientar_requisitos() -> void:
	actualizar_mision()
	if aplicar_guia(true):
		return
	var paso := paso_elevador(motor.estado())
	if not paso.is_empty():
		senalar_guia(paso.objetivo)
		return
	var candidatos: Array = []
	if not requisito_pendiente.is_empty():
		candidatos.append(requisito_pendiente)
	candidatos.append_array(motor.recuperaciones_disponibles().keys())
	var estado: Dictionary = motor.estado()
	for id in datos.ruta_ideal:
		var regla: Dictionary = datos.acciones[id]
		if not regla.efectos.is_empty() and Escenario.cumple(estado, regla.efectos):
			continue
		candidatos.append(id)
	for id in candidatos:
		if not comprobar_inventario(id, "teclado", true):
			return
	avisar("Tienes los objetos necesarios para los pasos pendientes.")


func actualizar_inventario() -> void:
	taller.actualizar_hud(carrito_cerca(), not hud_oculto and motor.fin().is_empty())
	var forma: Node3D
	if not taller.mano.is_empty():
		forma = taller.objetos[taller.mano].get_node("Forma")
	var dejo_multimetro: bool = jugador.id_mano == "multimetro" and taller.mano != "multimetro"
	var empuno_multimetro: bool = jugador.id_mano != "multimetro" and taller.mano == "multimetro"
	jugador.elegir_objeto(taller.mano, forma)
	if zona_activa == $Banco and (dejo_multimetro or empuno_multimetro):
		if dejo_multimetro:
			motor.mediciones.reiniciar_puntas()
		actualizar_banco()


func mostrar_resultado(decision: Dictionary) -> void:
	var texto: String = decision.get("motivo", "")
	var fuente: String = decision.get("fuente", "")
	if decision.get("criticidad") == "critica":
		texto = texto.trim_suffix(" " + fuente)
		avisar(texto, "critico", "Falta crítica", "", fuente)
		return
	if decision.has("previas_faltantes"):
		avisar(aviso_previas(decision.previas_faltantes), "aviso", "Aún no puedes hacerlo")
		return
	var eventos: Array = decision.get("eventos", [])
	var consecuencia := ""
	if "tornillo_roto" in eventos:
		consecuencia = "Pieza dañada: tornillo roto"
	elif not eventos.is_empty():
		var evento: String = eventos[0]
		consecuencia = PROBLEMAS.get(evento, datos.eventos[evento].descripcion)
	var tipo_error: String = decision.get("tipo_error", "")
	if not tipo_error.is_empty():
		var titulos := {
			"punto-de-medicion-incorrecto": "Medición incorrecta",
			"lectura-equivocada": "Medición incorrecta",
			"lectura-mal-interpretada": "Interpretación incorrecta",
			"valor-fuera-de-rango": "Valor fuera de rango",
			"orden-incorrecto": "Orden incorrecto",
			"paso-omitido": "Paso omitido",
			"paso-innecesario": "Paso innecesario",
			"causa-equivocada": "Diagnóstico incorrecto",
			"accion-insegura": "Acción insegura",
		}
		if not consecuencia.is_empty():
			texto = consecuencia if texto.is_empty() else texto + "\n" + consecuencia
		avisar(texto, "error", titulos.get(tipo_error, "Revisa este paso"), "", fuente)
		return
	if not decision.get("aplicada", false):
		avisar(texto, "aviso", "No puedes hacer ese paso")
		return
	if not consecuencia.is_empty():
		avisar(consecuencia, "aviso", "Revisa el autobús", "", fuente)
		return
	if decision.has("punto_medido"):
		avisar("Medición registrada: %s = %.1f V" % [
			decision.punto_medido.to_upper(), decision.lectura_mostrada], "exito", "Medición registrada")
	elif zona_activa == $Bajos and decision.accion in [
			"medir_presion", "localizar_pinchazo", "detectar_tuercas", "medir_bolsa",
			"localizar_fuga", "revisar_amortiguador", "medir_pastillas"]:
		avisar(datos.acciones[decision.accion].descripcion, "exito", "Hallazgo registrado")
	elif decision.accion == "medir_temperatura":
		avisar(datos.acciones[decision.accion].descripcion, "exito", "Medición registrada")


func aviso_previas(faltantes: Dictionary) -> String:
	var etiquetas := PackedStringArray()
	for clave in indicios:
		if faltantes.get(clave) == true:
			etiquetas.append(indicios[clave])
	for clave in faltantes:
		if faltantes[clave] == true and indicios.has(clave):
			continue
		# La reposición del foco también enciende el faro izquierdo.
		if clave == "faro_izquierdo" and faltantes.get("foco_repuesto") == true:
			continue
		etiquetas.append(PREVIAS.get(clave, "revisa los pasos de la orden"))
	var ayuda := siguiente_ayuda(progreso_indicios(motor.estado()))
	var aviso := "Antes de seguir, revisa lo que falta: " + ", ".join(etiquetas) + "."
	return aviso if ayuda.is_empty() else aviso + " " + ayuda


func avisar(texto: String, tipo := "info", titulo := "", donde := "", fuente := "") -> void:
	flashcard.encolar({"texto": texto, "tipo": tipo, "titulo": titulo,
		"donde": donde, "fuente": fuente, "objeto": ""})


func avisar_objeto(texto: String, tipo: String, titulo: String, objeto: String) -> void:
	taller.apagar_guia()
	flashcard.encolar({"texto": texto, "tipo": tipo, "titulo": titulo,
		"donde": taller.ubicacion(objeto), "fuente": "", "objeto": objeto})


func avisar_temporal(texto: String) -> void:
	salida_hasta = 0
	resultado.text = TextoLimpio.linea(texto)
	resultado.visible = not flashcard.visible and not resumen.visible
	duracion_aviso.start()


func pausar_por_flashcard() -> void:
	salida_hasta = 0
	inicio_flashcard = Time.get_ticks_msec()
	activo_antes_flashcard = jugador.activo
	navegando_antes_flashcard = navegando
	raton_antes_flashcard = Input.mouse_mode
	foco_antes_flashcard = get_viewport().gui_get_focus_owner()
	jugador.activo = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resultado.hide()


func reanudar_tras_flashcard() -> void:
	ultimo_ms += Time.get_ticks_msec() - inicio_flashcard
	if not motor.fin().is_empty():
		finalizar_orden()
		if flashcard.visible:
			return
		actualizar_hud()
		if not hud_mision.celebrando:
			resumen.mostrar(motor, datos, lateral.get_node("Aviso").text)
		return
	actualizar_panel(Time.get_ticks_msec())
	if pausa_visible:
		lateral.get_node("Continuar").grab_focus()
		return
	jugador.activo = (activo_antes_flashcard or navegando_antes_flashcard) \
		and not navegando and not menu_pieza.visible and not hoja_abierta()
	Input.mouse_mode = raton_antes_flashcard
	if accion_pendiente == "reconectar":
		menu_pieza.esperar_panel(fuente_banco.fuente() == "banco")
	elif is_instance_valid(foco_antes_flashcard) and foco_antes_flashcard.is_visible_in_tree():
		foco_antes_flashcard.grab_focus()


func progreso_indicios(estado: Dictionary) -> Dictionary:
	return estado.merged(motor.mediciones.indicios()) if motor.mediciones != null else estado


func siguiente_ayuda(progreso: Dictionary) -> String:
	if not motor.fin().is_empty():
		return ""
	for indicio in misiones:
		if not Escenario.mision_cumplida(indicio, progreso):
			var ayuda: String = indicio.get("ayuda", "")
			if not ayuda.is_empty() and indicio.get("clave") == "resuelto" \
					and zona_activa == $Banco and fuente_banco.fuente() == "banco":
				return ("Elige Reconectar conductor en el banco. "
					+ "Cierra el conductor abierto en el banco físico.")
			return ayuda
	return ""


func mostrar_estado(inmediato := false) -> void:
	var estado: Dictionary = motor.estado()
	var terminado: bool = not motor.fin().is_empty()
	jugador.activo = not flashcard.visible and not terminado and not pausa_visible and not navegando and not menu_pieza.visible and not hoja_abierta()
	if terminado:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var falla: bool = motor.hay_problemas() or motor.fin() == "falta-critica"
	# La captura cambia el encuadre. Las acciones conservan el Tween para mostrar fallos de apertura.
	zona_activa.reflejar_estado(estado, falla, inmediato)
	if zona_activa == $Banco:
		actualizar_banco()
		interior.mostrar_modulo_auxiliar(estado.resuelto)
	actualizar_mision(inmediato)
	actualizar_leds()
	actualizar_hud()
	if not flashcard.visible and not hud_mision.celebrando:
		resumen.mostrar(motor, datos, lateral.get_node("Aviso").text)


func configurar_misiones() -> void:
	var agrupadas := []
	for indicio in datos.get("indicios", []):
		agrupadas.append_array(indicio.get("claves", []))
	misiones = datos.get("indicios", []).filter(func(indicio: Dictionary):
		return indicio.get("clave") not in agrupadas)
	if not datos.has("indicios"):
		for clave in indicios:
			if progreso_indicios(motor.estado()).has(clave):
				misiones.append({"clave": clave, "etiqueta": indicios[clave]})
	TextoLimpio.mostrar_chip(hud_mision.marca, datos.titulo)
	acciones_mision.clear()
	for indice in misiones.size():
		var claves := Escenario.claves_mision(misiones[indice])
		var grupos := {}
		for id in datos.acciones:
			var regla: Dictionary = datos.acciones[id]
			if claves.any(func(clave: String): return regla.efectos.get(clave, false) == true):
				grupos[id] = {"ids": [id], "regla": regla, "titulo": regla.titulo}
			elif motor.mediciones != null:
				var clave := Mediciones.indicio_de_accion(id)
				if clave not in claves:
					continue
				# Las opciones de una lectura cuentan como un solo subpaso.
				if not grupos.has(clave):
					grupos[clave] = {"ids": [], "regla": regla, "titulo": regla.titulo}
				grupos[clave].ids.append(id)
		acciones_mision[indice] = grupos.values()

func herramientas_para_dejar() -> Array[String]:
	var candidatas: Array[String] = []
	var cinturon: Array[String] = taller.inventario.cinturon.duplicate()
	cinturon.reverse()
	for id in cinturon:
		if Inventario.CATALOGO[id].tipo == "herramienta" and id not in objetos_requeridos:
			candidatas.append(id)
	return candidatas


func actualizar_mision(inmediato := false) -> void:
	if misiones.is_empty():
		objetos_requeridos.clear()
		cambiar_subpaso_guia({})
		return
	var estado: Dictionary = motor.estado()
	var progreso := progreso_indicios(estado)
	var cumplidas: Array = misiones.map(func(mision: Dictionary): return Escenario.mision_cumplida(mision, progreso))
	var actual := cumplidas.find(false)
	var anterior: int = hud_mision.indice
	var fondo := $Interfaz.get_theme_stylebox("panel") as StyleBoxFlat
	var color := FONDO_MISION.lerp(hud_mision.ACENTO, hud_mision.destello)
	if fondo.bg_color != color:
		fondo.bg_color = color
	if hud_mision.celebrando and not inmediato:
		if hud_mision.progreso != cumplidas:
			hud_mision.progreso = cumplidas
			hud_mision.puntos.queue_redraw()
	elif anterior >= 0 and actual != anterior and cumplidas[anterior] and not inmediato \
			and not modo_captura and (motor.fin().is_empty() or motor.fin() == "resuelto"):
		hud_mision.celebrar(cumplidas, func():
			hud_mision.indice = -1
			firma_mision.clear()
			actualizar_mision(true)
			hud_mision.entrada()
			actualizar_hud()
			if not flashcard.visible and not motor.fin().is_empty():
				finalizar_orden()
			if not flashcard.visible and not motor.fin().is_empty():
				resumen.mostrar(motor, datos, lateral.get_node("Aviso").text))
	if actual == -1:
		objetos_requeridos.clear()
		cambiar_subpaso_guia({})
		return
	var mision: Dictionary = misiones[actual]
	var controles := controles_seguridad()
	var elevador: Dictionary = paso_elevador(estado)
	var disponibles: Array[String] = taller.inventario.accesibles(true)
	var aciertos: Array[String] = motor.acciones_acertadas()
	var ayuda := siguiente_ayuda(progreso)
	var firma := [actual, cumplidas, controles.duplicate(), taller.inventario.cinturon.duplicate(),
		taller.inventario.carrito.duplicate(), taller.hay_superficie(taller.mesa), taller.mano, accion_pendiente,
		aciertos, ayuda, elevador, fuente_banco.fuente(), taller.cajones_abiertos, carrito_cerca(),
		motor.mediciones.punta_negra if motor.mediciones != null else ""]
	if firma == firma_mision:
		return
	firma_mision = firma
	objetos_requeridos.clear()
	var filas: Array = []
	var clave: String = mision.get("clave", "")
	var grupos: Array = acciones_mision[actual]
	if not elevador.is_empty():
		var herramienta: String = requisitos(elevador.id).get("herramienta", "")
		if not herramienta.is_empty():
			objetos_requeridos.append(herramienta)
		var texto: String = PASOS_ELEVADOR.get(elevador.id, "Cierra la orden en la consola")
		var objetivo: String = elevador.objetivo
		if elevador.id in ["trabar_soporte", "destrabar_soporte"]:
			agregar_herramienta(filas, requisitos(elevador.id).herramienta, false, disponibles)
			texto += " · " + $Elevador.piezas[objetivo].nombre
		if elevador.id == "colocar_calzas":
			agregar_herramienta(filas, requisitos(elevador.id).herramienta, false, disponibles)
		if objetivo != "calzas":
			agregar_subpaso(filas, texto, false, {"pieza": $Elevador.piezas[objetivo], "columna": true})
	for grupo in grupos:
		var regla: Dictionary = grupo.regla
		var id: String = grupo.ids[0]
		var hecha: bool = grupo.ids.any(func(accion: String): return accion in aciertos)
		if motor.mediciones != null and motor.mediciones.fuente == "banco" and id.begins_with("medir_"):
			# En el banco físico, reportar la lectura también acredita la medición.
			var prefijo := "reportar_" + id.trim_prefix("medir_") + "_"
			hecha = hecha or aciertos.any(func(accion: String): return accion.begins_with(prefijo))
		var requiere := requisitos(id)
		var herramientas: Array = requiere.get("herramientas", [])
		if requiere.has("herramienta"):
			herramientas = [requiere.herramienta]
		if id.begins_with("medir_") and motor.mediciones != null and motor.mediciones.fuente == "banco":
			herramientas = []
		if not hecha:
			objetos_requeridos.append_array(herramientas)
			objetos_requeridos.append_array(requiere.get("piezas", []))
		for herramienta in herramientas:
			agregar_herramienta(filas, herramienta, hecha, disponibles)
		for pieza in requiere.get("piezas", []):
			agregar_toma(filas, pieza, hecha or pieza in disponibles)
			agregar_acceso_carrito(filas, pieza, hecha)
		if not regla.get("seguridad_panel", "").is_empty():
			agregar_subpaso(filas, "Activa Bloqueo y Etiquetado en el panel",
				hecha or Motor.seguridad_confirmada(controles))
		var componente: String = regla.componente
		var pieza: Node3D = zona_activa.piezas.get(componente, $Elevador.piezas.get(componente))
		var nombre_pieza: String = pieza.nombre if pieza != null else componente.capitalize()
		var texto: String = "Elige %s en %s" % [grupo.titulo, nombre_pieza]
		if motor.mediciones != null:
			if id.begins_with("medir_"):
				if motor.mediciones.fuente == "banco":
					texto = "Reporta la lectura de %s en la hoja" % nombre_pieza
					pieza = zona_activa.piezas.get("hoja_diagnostico")
				else:
					agregar_subpaso(filas, "Coloca la punta negra en TP0",
						hecha or motor.mediciones.punta_negra == "tp0", {"pieza": zona_activa.piezas.tp0})
					texto = "Coloca la punta roja en %s" % nombre_pieza
			elif id.begins_with("reportar_"):
				texto = "Reporta la lectura de %s en la hoja" % id.get_slice("_", 1).to_upper()
		agregar_subpaso(filas, TextoLimpio.limpiar(texto).texto, hecha or accion_pendiente in grupo.ids,
			{"pieza": pieza} if pieza != null else {})
		if regla.get("requiere_panel", false):
			var confirmar := "Confirma en el panel"
			if id == "reconectar" and fuente_banco.fuente() == "banco":
				confirmar = "Cierra el conductor abierto en el banco físico"
			filas.append({"texto": confirmar, "hecho": hecha})
	var titulo: String = TextoLimpio.limpiar(mision.get("mision", mision.get("etiqueta", ""))).texto
	# Conserva las pistas que añaden contexto a los controles o a la pieza.
	if ayuda.trim_suffix(".") == titulo or (not grupos.is_empty() and clave == "bloqueo_confirmado"):
		ayuda = ""
	var pendiente := filas.find_custom(func(fila: Dictionary) -> bool: return not fila.hecho)
	var guia: Dictionary = filas[pendiente].get("guia", {}) if pendiente >= 0 and motor.fin().is_empty() else {}
	var objetivo := ""
	if not guia.is_empty():
		for fila in filas.slice(pendiente):
			var destino: Dictionary = fila.get("guia", {})
			if fila.hecho or destino.has("mano"):
				continue
			objetivo = destino.get("objeto", "")
			break
	if not objetivo.is_empty() and objetivo not in disponibles:
		var carga: int = Inventario.CATALOGO[objetivo].espacio
		if carga > Inventario.libres(taller.inventario.cinturon) \
				and (not carrito_cerca() or carga > Inventario.libres(taller.inventario.carrito)):
			var candidatas := herramientas_para_dejar()
			if not candidatas.is_empty() and taller.hay_superficie(taller.mesa):
				var herramienta := candidatas[0]
				var nombre: String = Inventario.CATALOGO[herramienta].nombre
				var articulo: String = {
					"calzas": "las ", "lampara": "la ", "llave_ajustable": "la ", "llave_torque": "la "
				}.get(herramienta, "el ")
				guia = {"pieza": taller.mesa.piezas.mesa_taller, "columna": true}
				filas.insert(pendiente, {"texto": "Deja %s%s en la mesa" % [articulo, nombre], "hecho": false})
	cambiar_subpaso_guia(guia)
	if not hud_mision.celebrando:
		hud_mision.mostrar(actual, titulo, cumplidas, filas, TextoLimpio.limpiar(ayuda).texto)


func agregar_toma(filas: Array, id: String, hecho: bool) -> void:
	agregar_subpaso(filas, taller.instruccion_tomar(id), hecho, {"objeto": id})


func agregar_herramienta(filas: Array, id: String, hecha: bool, disponibles: Array[String]) -> void:
	agregar_toma(filas, id, hecha or id in disponibles)
	agregar_acceso_carrito(filas, id, hecha)
	var espacio: int = taller.espacio_de(id)
	var tecla := " (%d)" % espacio if espacio > 0 else ""
	agregar_subpaso(filas, "Ten %s en la mano%s" % [Inventario.CATALOGO[id].nombre, tecla],
		hecha or taller.mano == id, {"mano": id})


func agregar_acceso_carrito(filas: Array, id: String, hecha: bool) -> void:
	if id in taller.inventario.carrito:
		agregar_subpaso(filas, "Acércate al carrito · " + Inventario.CATALOGO[id].nombre,
			hecha or carrito_cerca(), {"objeto": id})


func agregar_subpaso(filas: Array, texto: String, hecho: bool, guia := {}) -> void:
	for fila in filas:
		if fila.texto == texto and fila.get("guia", {}) == guia:
			fila.hecho = fila.hecho and hecho
			return
	filas.append({"texto": TextoLimpio.linea(texto), "hecho": hecho, "guia": guia})


func cambiar_subpaso_guia(guia: Dictionary) -> void:
	if subpaso_guia != guia:
		subpaso_guia = guia
		taller.apagar_guia()
	if guia_automatica and not flashcard.visible:
		aplicar_guia()


func aplicar_guia(manual := false) -> bool:
	if subpaso_guia.is_empty():
		return false
	if subpaso_guia.has("pieza"):
		var pieza: Node3D = subpaso_guia.pieza
		taller.senalar(pieza.componente, pieza, manual, subpaso_guia.get("columna", false))
	else:
		var id: String = subpaso_guia.get("mano", subpaso_guia.get("objeto", ""))
		var espacio: int = taller.espacio_de(id) if subpaso_guia.has("mano") else 0
		if espacio > 0:
			taller.senalar_espacio(espacio, manual)
		else:
			taller.senalar(id, null, manual)
	taller.actualizar_hud(carrito_cerca(), not hud_oculto)
	return true


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
	var mision_visible: bool = not misiones.is_empty() and (not terminado or hud_mision.celebrando)
	hud_mision.visible = mision_visible
	hud_mision.mostrando_detalle = not hud_oculto
	hud_mision.actualizar_visibilidad()
	$PistaOrden.visible = datos.has("briefing") and not terminado
	$Interfaz.visible = mision_visible or terminado or pausa_visible or aviso.visible or datos.is_empty()
	var ventana := get_viewport().get_visible_rect().size
	$Interfaz.offset_right = minf(12.0 + ANCHO_HUD, ventana.x - 12.0)
	$Interfaz.anchor_bottom = 1.0 if terminado and not mision_visible else 0.0
	lateral.get_node("Estado").visible = datos.is_empty()
	lateral.get_node("Conexion").visible = pausa_visible
	var margen: float = $Interfaz.get_theme_stylebox("panel").get_minimum_size().y
	$Interfaz.offset_bottom = -12.0 if terminado and not mision_visible else minf(
		ventana.y - 84.0, 12.0 + lateral.get_combined_minimum_size().y + margen)
	if motor != null:
		actualizar_inventario()


func reintentar() -> void:
	if flashcard.visible:
		return
	var nuevo: RefCounted = motor.reintentar()
	if nuevo == null:
		return
	motor = nuevo
	hud_mision.reiniciar()
	firma_mision.clear()
	taller.reiniciar()
	if $Elevador.arriba or $Elevador.en_movimiento():
		jugador.ubicar(Vector3(-4, 0, 0.1))
		apuntar_jugador($Elevador.piezas[Elevador.CONSOLA].global_position)
	$Elevador.reiniciar()
	requisito_pendiente = ""
	if zona_activa is ZonaBase:
		zona_activa.apertura_manual = null
	resultados_guardados = false
	causa_marcada = ""
	cerrar_menu()
	duracion_aviso.stop()
	resultado.hide()
	lateral.get_node("Aviso").text = ""
	ultimo_ms = Time.get_ticks_msec()
	mostrar_estado()
	mostrar_orden()


func abrir_menu(pieza: Interactuable) -> void:
	if flashcard.visible or hoja_abierta():
		return
	if motor == null or not motor.fin().is_empty() or pausa_visible or navegando or not accion_pendiente.is_empty():
		return
	if pieza.zona == $Bajos and not $Elevador.arriba:
		return
	if zona_activa == $Banco and pieza == $Banco.piezas.hoja_diagnostico:
		hoja.abrir(motor.mediciones.reportadas)
		jugador.activo = false
		$Apuntado.hide()
		return
	var zona := pieza.zona as ZonaBase
	pieza_menu = pieza
	if zona != null and zona.es_pieza_interna(pieza.componente) and not zona.abierta:
		return
	var opciones: Array[Dictionary] = []
	var causas: Array = []
	var lectura := "[MUESTRA] Sin falla en esta orden"
	match pieza.componente:
		Elevador.CONSOLA:
			opciones.append(MenuPieza.navegacion("elevar_bus", "Subir el autobús"))
			opciones.append(MenuPieza.navegacion("descender_bus", "Bajar el autobús"))
			if zona_activa == $Bajos and not $Elevador.arriba:
				opciones.append_array(MenuPieza.entradas(motor, datos, pieza.componente))
			lectura = "Autobús elevado" if $Elevador.arriba else "Autobús abajo"
		Elevador.CALZAS:
			if not $Elevador.calzas_colocadas and not $Elevador.arriba:
				opciones.append(MenuPieza.navegacion("colocar_calzas", "Colocar calzas"))
			lectura = "Calzas colocadas" if $Elevador.calzas_colocadas else "Punto junto a la rueda"
		"soporte_izquierdo", "soporte_derecho":
			var trabado: bool = $Elevador.trabas[pieza.componente]
			if $Elevador.arriba:
				opciones.append(MenuPieza.navegacion("destrabar_soporte" if trabado else "trabar_soporte",
					"Destrabar soportes" if trabado else "Trabar soportes"))
			lectura = "Soporte trabado" if trabado else "Soporte libre"
		"mesa_taller", "carrito_taller", "mesa_banco":
			lectura = "Selecciona un objeto en la mano para dejarlo aquí."
		"puerta_pasajeros":
			opciones.append(MenuPieza.navegacion("subir", "Subir al autobús"))
			lectura = ""
		"puerta_salida":
			opciones.append(MenuPieza.navegacion("bajar", "Bajar del autobús"))
			lectura = ""
	if pieza.componente == "caja_taller" or pieza.componente.begins_with("cajon_taller_"):
		var titulo := "Cerrar cajones" if taller.cajones_abiertos else "Abrir cajones"
		opciones.append(MenuPieza.navegacion("cajones", titulo))
		lectura = ""
	var mueble := mueble_para_dejar(pieza)
	if mueble != null:
		if not taller.mano.is_empty() and (mueble != $Banco or taller.mano == "multimetro") \
				and (mueble != taller.caja_roja
				or Inventario.CATALOGO[taller.mano].tipo == "herramienta"):
			opciones.append(MenuPieza.navegacion("dejar", "Dejar aquí: " + Inventario.CATALOGO[taller.mano].nombre))
		var disponibles: Array[String] = taller.objetos_en(mueble)
		if mueble == taller.carrito and carrito_cerca():
			disponibles.append_array(taller.inventario.carrito)
		for objeto in disponibles:
			var opcion := MenuPieza.navegacion("tomar", "Tomar: " + Inventario.CATALOGO[objeto].nombre)
			opcion["objeto"] = objeto
			opciones.append(opcion)
	if mueble == taller.carrito:
		opciones.append(MenuPieza.navegacion("carrito", "Estacionar carrito" if taller.lleva_carrito else "Empujar carrito"))
	if pieza == $Banco.piezas.multimetro:
		if not pieza.visible:
			return
		opciones.append(MenuPieza.navegacion("tomar", "Tomar: Multímetro"))
		lectura = ""
	if taller.objetos.get(pieza.componente) == pieza:
		if not pieza.visible:
			return
		if pieza.componente not in taller.inventario.carrito:
			opciones.append(MenuPieza.navegacion("tomar", "Tomar: " + pieza.nombre))
		lectura = "%d espacio(s)" % Inventario.CATALOGO[pieza.componente].espacio
	if opciones.is_empty() and pieza.zona == zona_activa:
		opciones = MenuPieza.entradas(motor, datos, pieza.componente)
		if zona_activa not in [$Sector, $Bajos] or not opciones.is_empty():
			lectura = zona_activa.lectura_pieza(pieza.componente)
		if motor.estado().get("inspeccionado", motor.estado().get("sintomas_revisados", false)):
			causas = datos.causas
	elif opciones.is_empty() and pieza.zona == interior:
		lectura = interior.lectura_pieza(pieza.componente)
	if zona != null and zona.bisagra != null and pieza.componente == zona.acceso:
		var id := "cerrar_acceso" if zona.abierta else "abrir_acceso"
		var verbo := "Cerrar" if zona.abierta else "Abrir"
		opciones.append(MenuPieza.navegacion(id, "%s %s" % [verbo, zona.nombre_acceso]))
		lectura = zona.lectura_pieza(pieza.componente)
		zona_menu = zona
	if salida_hasta != 0:
		salida_hasta = 0
		resultado.hide()
	menu_pieza.abrir(pieza.nombre, lectura, opciones, causas, causa_marcada, estado_pieza(pieza), mueble != null)
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


func hoja_abierta() -> bool:
	return hoja != null and hoja.visible


func guardar_hoja(acciones: Array, fuente: String) -> void:
	if not hoja_abierta() or flashcard.visible or panel.conexion.pausado() or not motor.fin().is_empty():
		return
	cerrar_menu()
	for id in acciones:
		ejecutar(id, fuente)


func cerrar_menu() -> void:
	if hoja_abierta():
		hoja.hide()
	accion_pendiente = ""
	panel.resaltar_confirmar(false)
	zona_menu = null
	pieza_menu = null
	menu_pieza.cerrar()
	if not flashcard.visible and not navegando and not pausa_visible and motor != null and motor.fin().is_empty():
		jugador.activo = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func elegir_accion(indice: int, fuente: String) -> void:
	if flashcard.visible or not menu_pieza.visible or not accion_pendiente.is_empty() or panel.conexion.pausado() \
			or indice < 0 or indice >= menu_pieza.entradas.size():
		return
	var entrada: Dictionary = menu_pieza.entradas[indice]
	if entrada.get("navegacion", false):
		if entrada.id in ["abrir_acceso", "cerrar_acceso"]:
			zona_menu.cambiar_acceso(entrada.id == "abrir_acceso")
			cerrar_menu()
		elif entrada.id in ["elevar_bus", "descender_bus", "colocar_calzas", "trabar_soporte", "destrabar_soporte"]:
			accion_elevador(entrada.id, pieza_menu.componente, fuente)
		elif entrada.id in ["tomar", "dejar", "cajones", "carrito"]:
			accion_taller(entrada.id, entrada.get("objeto", ""))
		else:
			if taller.lleva_carrito and entrada.id == "subir":
				taller.lleva_carrito = false
			navegar(entrada.id)
	elif pieza_menu.zona == $Bajos and not $Elevador.seguro():
		cerrar_menu()
		ejecutar(entrada.id, fuente)
	elif not comprobar_inventario(entrada.id, fuente):
		return
	elif entrada.requiere_panel:
		accion_pendiente = entrada.id
		actualizar_panel(Time.get_ticks_msec())
		actualizar_mision()
		menu_pieza.esperar_panel(entrada.id == "reconectar" and fuente_banco.fuente() == "banco")
		var torque: Dictionary = datos.acciones.get(entrada.id, {}).get("torque", {})
		if not torque.is_empty():
			avisar("Ajusta la perilla a %d–%d en la escala del panel [MUESTRA]." %
				[torque.minimo, torque.maximo], "info", "Ajusta el torque")
	else:
		cerrar_menu()
		ejecutar(entrada.id, fuente)


func accion_elevador(id: String, componente: String, fuente := "teclado") -> void:
	cerrar_menu()
	if $Elevador.en_movimiento():
		return
	match id:
		"colocar_calzas":
			if $Elevador.arriba:
				return
			if not comprobar_inventario(id, fuente):
				return
			$Elevador.colocar_calzas()
		"trabar_soporte", "destrabar_soporte":
			if not $Elevador.arriba or not $Elevador.trabas.has(componente) or not comprobar_inventario(id, fuente):
				return
			$Elevador.cambiar_traba(componente, id == "trabar_soporte")
		"elevar_bus", "descender_bus":
			var subir := id == "elevar_bus"
			if subir == $Elevador.arriba:
				avisar("El autobús ya está %s." % ("arriba" if subir else "abajo"), "aviso", "Comprueba el elevador")
				return
			if subir and not $Elevador.calzas_colocadas and not comprobar_inventario(id, fuente):
				return
			if not subir and true in $Elevador.trabas.values():
				avisar("Destraba ambos soportes antes de bajar el autobús.", "aviso", "Comprueba el elevador")
				return
			if $Elevador.ocupado(jugador.global_position):
				avisar("Despeja el área bajo el autobús.", "aviso", "Comprueba el elevador")
				return
			if subir and not $Elevador.calzas_colocadas:
				$Elevador.colocar_calzas()
			navegando = true
			jugador.activo = false
			$Elevador.mover(subir)
			await $Elevador.recorrido.finished
			navegando = false
	if requisito_pendiente == id:
		requisito_pendiente = ""
	mostrar_estado()


func mueble_para_dejar(pieza: Interactuable) -> Node3D:
	match pieza.componente:
		"mesa_banco": return taller.mesa_banco
		"mesa_taller": return taller.mesa
		"carrito_taller": return taller.carrito
		"caja_taller": return taller.caja_roja
	if pieza.componente.begins_with("cajon_taller_"):
		return taller.caja_roja
	return null


func accion_taller(id: String, objeto := "") -> void:
	var aviso := ""
	var carga := 0
	match id:
		"tomar":
			var id_objeto := pieza_menu.componente if objeto.is_empty() else objeto
			if id_objeto in taller.inventario.carrito and carrito_cerca():
				taller.mano = id_objeto
			else:
				aviso = taller.tomar(id_objeto, carrito_cerca())
				if not aviso.is_empty() and id_objeto not in taller.inventario.accesibles(true):
					carga = Inventario.objeto(id_objeto).get("espacio", 0)
		"dejar":
			aviso = taller.dejar(taller.mano, carrito_cerca(), mueble_para_dejar(pieza_menu))
		"cajones":
			taller.cambiar_cajones(not taller.cajones_abiertos)
		"carrito":
			taller.lleva_carrito = not taller.lleva_carrito
	cerrar_menu()
	actualizar_inventario()
	actualizar_mision()
	if carga > 0:
		var libres_carrito := Inventario.libres(taller.inventario.carrito)
		var sitio_carrito := carga <= libres_carrito
		if not sitio_carrito:
			if libres_carrito == 0 and Inventario.libres(taller.inventario.cinturon) == 0:
				aviso += " El cinturón y el carrito están llenos."
			else:
				aviso += " Tampoco cabe en el carrito."
		var candidatas := herramientas_para_dejar()
		if candidatas.is_empty():
			aviso += " Deja un objeto para hacer espacio."
		else:
			var nombres := PackedStringArray()
			for candidata in candidatas.slice(0, 2):
				nombres.append(Inventario.CATALOGO[candidata].nombre)
			aviso += " Deja una herramienta que no necesites ahora, por ejemplo: %s." % " o ".join(nombres)
		if sitio_carrito:
			aviso += " Acércate al carrito (a menos de 3 m) para llevarla ahí."
		avisar(aviso, "aviso", "No cabe en el cinturón")
	elif not aviso.is_empty():
		avisar(aviso, "aviso", "Revisa el inventario")


func recibir_accion(accion: Dictionary) -> void:
	if flashcard.visible or panel.conexion.pausado() or motor == null or not motor.fin().is_empty():
		return
	match accion.accion:
		"torque":
			sincronizar_fuente_seguridad()
			if accion.fuente_entrada == "panel" and fuente_seguridad == "panel":
				torque_fisico = accion.valor
			elif accion.fuente_entrada == "virtual" and fuente_seguridad == "virtual" \
					and datos.acciones.get(accion_pendiente, {}).has("torque"):
				var id := accion_pendiente
				cerrar_menu()
				ejecutar(id, "virtual")
		"bloqueo", "etiquetado":
			sincronizar_fuente_seguridad()
			if accion.fuente_entrada == "panel" and fuente_seguridad == "panel":
				seguridad_panel[accion.accion] = accion.valor == 1
				if datos.zona == "motor":
					actualizar_leds()
		"inspeccionar":
			if not menu_pieza.visible and not hoja_abierta() and jugador.activo:
				# El aviso usa el rayo del último paso físico. El clic puede llegar antes
				# del primer paso o justo después de mover la cámara.
				alcance.force_raycast_update()
				var pieza := alcance.get_collider() as Interactuable
				if zona_activa == $Banco and (pieza != null and pieza.zona == $Banco
						and pieza.componente in ["tp0", "tp1", "tp2"]):
					tocar_borne(pieza.componente, accion.fuente_entrada)
				else:
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
				if zona_activa in [$Banco, $Bajos] and accion.fuente_entrada in ["teclado", "control"]:
					if panel.conexion.fuente_panel() == "virtual":
						panel.emitir("confirmar", 1)
					return
				var id := accion_pendiente
				cerrar_menu()
				ejecutar(id, accion.fuente_entrada)


func tocar_borne(punto: String, fuente: String) -> void:
	if flashcard.visible:
		return
	if not punto.is_empty() and not comprobar_inventario("medir_tp2" if punto == "tp2" else "medir_tp1", fuente):
		return
	var id: String = motor.mediciones.tocar(punto)
	if not id.is_empty():
		ejecutar(id, fuente)
	else:
		actualizar_banco()
		var aviso: String = motor.mediciones.aviso_puntas
		if not aviso.is_empty():
			avisar(aviso, "aviso", "Revisa las puntas")


func actualizar_banco() -> void:
	var mediciones: RefCounted = motor.mediciones
	var lectura: Dictionary = mediciones.leer.call(motor.estado())
	$Banco.mostrar_fuente(lectura.aviso, mediciones.fuente)
	var puntas: Array[String] = mediciones.puntas()
	for punto in $Banco.pinzas:
		$Banco.pinzas[punto].visible = punto in puntas
	jugador.pantalla_multimetro.text = mediciones.pantalla
	indicador_puntas.text = "Punta negra: %s · Punta roja: %s" % [
		"—" if puntas[0].is_empty() else puntas[0].to_upper(),
		"—" if puntas[1].is_empty() else puntas[1].to_upper()]
	indicador_puntas.visible = taller.mano == "multimetro"


func recibir_banco(linea: String, ahora: int) -> void:
	var lectura_previa := fuente_banco.recibir(linea, ahora)
	sincronizar_banco()
	if not flashcard.visible and not lectura_previa.is_empty() and motor.fin().is_empty():
		cerrar_menu()
		ejecutar("reconectar", "banco", lectura_previa)


func sincronizar_banco() -> void:
	if motor.mediciones.fuente != fuente_banco.fuente():
		motor.mediciones.fuente = fuente_banco.fuente()
		if accion_pendiente == "reconectar" and not flashcard.visible:
			menu_pieza.esperar_panel(motor.mediciones.fuente == "banco")
		mostrar_estado()
	else:
		actualizar_banco()


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()
	actualizar_panel(ahora)
	if motor != null:
		actualizar_inventario()
		actualizar_mision()
		if not flashcard.visible and guia_automatica:
			aplicar_guia()
	taller.actualizar_flecha(jugador.camara, not flashcard.visible and not menu_pieza.visible and not hoja_abierta() and not hud_oculto)
	if zona_activa != $Banco:
		return
	var fuente_anterior := fuente_banco.fuente()
	var aviso_anterior: String = fuente_banco.conexion.aviso()
	fuente_banco.actualizar(ahora)
	if fuente_anterior != fuente_banco.fuente() or aviso_anterior != fuente_banco.conexion.aviso():
		sincronizar_banco()
	if motor.fin().is_empty() and aviso_anterior != fuente_banco.conexion.aviso() \
			and not fuente_banco.conexion.aviso().is_empty():
		avisar(fuente_banco.conexion.aviso(), "aviso", "Conexión del banco")
	if not _udp_banco.is_bound():
		return
	for indice in range(mini(_udp_banco.get_available_packet_count(), 64)):
		recibir_banco(_udp_banco.get_packet().get_string_from_utf8(), ahora)


func _physics_process(_delta: float) -> void:
	var caminando: bool = jugador.activo and (modo_captura or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	if caminando and taller.lleva_carrito:
		taller.mover_carrito(jugador.global_position, _delta)
	var objetivo := alcance.get_collider() as Interactuable if caminando else null
	if objetivo != pieza_apuntada:
		if is_instance_valid(pieza_apuntada):
			pieza_apuntada.resaltar(false)
		pieza_apuntada = objetivo
		if objetivo != null:
			objetivo.resaltar(true)
	$Mira.visible = caminando
	$Apuntado.visible = objetivo != null
	var rotulo := "Clic / A · %s" % objetivo.nombre if objetivo != null else ""
	if objetivo != null and zona_activa == $Banco and objetivo.componente in ["tp0", "tp1", "tp2"]:
		var mediciones: RefCounted = motor.mediciones
		rotulo = Mediciones.texto_apuntado(mediciones.punta_negra, mediciones.punta_roja, objetivo.componente) \
			if taller.mano == "multimetro" else "Toma el multímetro para medir (%s)" % objetivo.nombre
	$Apuntado/Fondo/Nombre.text = rotulo


func _exit_tree() -> void:
	_udp_banco.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func actualizar_panel(ahora: int) -> void:
	panel.conexion.actualizar(ahora)
	if flashcard.visible:
		return
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
		if pausa and not resumen.visible:
			continuar.grab_focus()
	$AlternarPanel.visible = panel.conexion.fuente_panel() == "virtual" and not pausa \
		and motor != null and motor.fin().is_empty()
	$AlternarPanel.text = "Mostrar panel virtual" if panel_oculto else "Ocultar panel virtual"
	var pendiente := not accion_pendiente.is_empty()
	$AlternarPanel.disabled = pendiente
	var registro_banco: bool = zona_activa == $Banco and (hoja_abierta() or (menu_pieza.visible and not pendiente))
	panel.visible = $AlternarPanel.visible and (pendiente or not panel_oculto) and not registro_banco
	panel.resaltar_confirmar(pendiente and panel.visible and not (
		accion_pendiente == "reconectar" and fuente_banco.fuente() == "banco"))


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
	torque_fisico = -1.0
	if fuente == "virtual":
		panel.get_node("Bloqueo").set_pressed_no_signal(false)
		panel.get_node("Etiquetado").set_pressed_no_signal(false)


func _unhandled_input(evento: InputEvent) -> void:
	# Un clic en la escena (fuera de los paneles) recupera el ratón si la ventana no lo tenía capturado.
	if not flashcard.visible and not hoja_abierta() and motor != null and motor.fin().is_empty() and not pausa_visible and not menu_pieza.visible \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _input(evento: InputEvent) -> void:
	if flashcard.visible or hoja_abierta() or resumen.visible or navegando or motor == null or not evento.is_pressed() or evento.is_echo():
		return
	if ((evento is InputEventKey and evento.keycode == KEY_O) \
			or (evento is InputEventJoypadButton and evento.button_index == JOY_BUTTON_START)) and datos.has("briefing"):
		mostrar_orden()
		get_viewport().set_input_as_handled()
		return
	if evento is InputEventKey:
		if evento.keycode == KEY_ESCAPE and not menu_pieza.visible and motor.fin().is_empty():
			var ahora := Time.get_ticks_msec()
			get_viewport().set_input_as_handled()
			if ahora < salida_hasta:
				salida_hasta = 0
				salida_solicitada.emit()
			else:
				avisar_temporal("Presiona Esc otra vez para salir")
				salida_hasta = ahora + int(duracion_aviso.wait_time * 1000)
			return
		if evento.keycode == KEY_V and motor.fin().is_empty():
			guia_automatica = not guia_automatica
			preferencia_guia_automatica = guia_automatica
			if guia_automatica:
				aplicar_guia()
			else:
				taller.apagar_guia()
				actualizar_inventario()
			avisar_temporal("Guía automática activada" if guia_automatica else "Guía automática desactivada")
			get_viewport().set_input_as_handled()
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
	if not menu_pieza.visible and not pausa_visible and entrada_inventario(evento):
		get_viewport().set_input_as_handled()
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


func entrada_inventario(evento: InputEvent) -> bool:
	var paso := 0
	if evento is InputEventKey:
		if evento.keycode >= KEY_1 and evento.keycode <= KEY_8:
			var numero: int = evento.keycode - KEY_1 + 1
			if numero > 4 and not carrito_cerca():
				avisar("El carrito está lejos. Acércate para tomar lo que necesitas.", "aviso", "Acércate al carrito")
			else:
				taller.mano = taller.objeto_en_espacio(numero)
				actualizar_inventario()
				actualizar_mision()
			return true
		if evento.keycode == KEY_G:
			orientar_requisitos()
			return true
		if evento.keycode in [KEY_LEFT, KEY_RIGHT]:
			paso = -1 if evento.keycode == KEY_LEFT else 1
	elif evento is InputEventMouseButton and evento.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		paso = -1 if evento.button_index == MOUSE_BUTTON_WHEEL_UP else 1
	elif evento is InputEventJoypadButton:
		if evento.button_index == JOY_BUTTON_Y:
			orientar_requisitos()
			return true
		if evento.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
			paso = -1 if evento.button_index == JOY_BUTTON_LEFT_SHOULDER else 1
	if paso == 0:
		return false
	taller.seleccionar(paso, carrito_cerca())
	actualizar_inventario()
	actualizar_mision()
	return true
