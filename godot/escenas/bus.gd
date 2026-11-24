extends Node3D

signal decision_tomada(decision: Dictionary)

const Escenario = preload("res://logica/simulador/escenario.gd")
const Practica = preload("res://logica/simulador/practica.gd")
const Motor = preload("res://logica/simulador/motor.gd")

@export_file("*.json") var archivo := "../contenido/escenarios/aislamiento.json"
var motor: RefCounted
var datos: Dictionary
var ultimo_ms: int
var inspeccionado := false
var conexion_panel: RefCounted
var tecnico := {}
var resultados_guardados := false
var pausa_visible := false
@onready var resumen := $Interfaz/Lateral/Resumen
@onready var lateral := $Interfaz/Lateral
@onready var panel := $Interfaz/PanelVirtual


func _ready() -> void:
	if conexion_panel != null:
		panel.conexion = conexion_panel
		panel.conexion.protocolo.reiniciar_fuente("virtual")
	var carga := Escenario.cargar(ProjectSettings.globalize_path("res://").path_join(archivo))
	datos = carga.get("escenario", {})
	if datos.is_empty():
		$Interfaz/Lateral/Estado.text = str(carga)
		return
	motor = Motor.new(datos)
	ultimo_ms = Time.get_ticks_msec()
	$Interfaz/Lateral/Inspeccionar.pressed.connect(func(): ejecutar("inspeccionar", "teclado"))
	$Interfaz/Lateral/Inspeccionar.grab_focus()
	lateral.get_node("Causa").add_item("Marcar una causa")
	for causa in datos.causas:
		lateral.get_node("Causa").add_item(causa.replace("-", " "))
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
	if id == "inspeccionar" and decision.aplicada:
		inspeccionado = true
	var mensajes := PackedStringArray()
	if not decision.get("motivo", "").is_empty():
		mensajes.append(decision.motivo)
	for evento in decision.get("eventos", []):
		mensajes.append("Problema: %s" % String(evento).replace("_", " "))
	if not mensajes.is_empty() and not decision.get("fuente", "").is_empty():
		mensajes.append(decision.fuente)
	lateral.get_node("Aviso").text = "\n".join(mensajes)
	if not motor.fin().is_empty() and not tecnico.is_empty() and not resultados_guardados:
		resultados_guardados = Practica.guardar(tecnico.base, tecnico.id, tecnico.alias, motor,
			int(Time.get_unix_time_from_system()))
		if not resultados_guardados:
			lateral.get_node("Aviso").text += "\nNo se pudo guardar el resultado de la práctica."
	mostrar_estado()
	decision_tomada.emit(decision)


func mostrar_estado() -> void:
	var lineas := PackedStringArray([datos.titulo])
	var estado: Dictionary = motor.estado()
	for clave in estado:
		lineas.append("%s: %s" % [clave.replace("_", " "), estado[clave]])
	$Interfaz/Lateral/Estado.text = "\n".join(lineas)

	panel.mostrar_leds({"energizado": estado.get("energizado"), "bloqueado": estado.get("bloqueo_puesto"),
		"falla": motor.hay_problemas() or motor.fin() == "falta-critica"})
	mostrar_acciones()
	lateral.get_node("Inspeccionar").visible = motor.fin().is_empty()
	resumen.mostrar(motor)


func reintentar() -> void:
	var nuevo: RefCounted = motor.reintentar()
	if nuevo == null:
		return
	motor = nuevo
	resultados_guardados = false
	lateral.get_node("Causa").select(0)
	lateral.get_node("Accion").select(0)
	lateral.get_node("Aviso").text = ""
	ultimo_ms = Time.get_ticks_msec()
	mostrar_estado()
	lateral.get_node("Inspeccionar").grab_focus()


func mostrar_acciones() -> void:
	var lista: OptionButton = lateral.get_node("Accion")
	var causa: OptionButton = lateral.get_node("Causa")
	causa.visible = inspeccionado and motor.fin().is_empty()
	lista.visible = causa.visible
	lateral.get_node("ConfirmarAccion").visible = lista.visible
	var anterior: Variant = lista.get_selected_metadata()
	lista.clear()
	lista.add_item("Elegir acción y confirmar")
	var opciones := Practica.opciones(motor, datos)
	for id in opciones:
		var regla: Dictionary = opciones[id]
		var texto: String = regla.descripcion
		if regla.has("costo"):
			texto += " · costo %s · tiempo %s · riesgo %s" % [regla.costo, regla.tiempo, regla.riesgo]
		lista.add_item("%d. %s" % [lista.item_count, texto])
		var indice := lista.item_count - 1
		lista.set_item_metadata(indice, id)
		if id == anterior:
			lista.select(indice)


func recibir_accion(accion: Dictionary) -> void:
	if panel.conexion.pausado() or motor == null or not motor.fin().is_empty():
		return
	var lista: OptionButton = lateral.get_node("Accion")
	match accion.accion:
		"inspeccionar":
			ejecutar("inspeccionar", accion.fuente_entrada)
		"elegir-accion":
			if lista.visible and int(accion.valor) in range(lista.item_count):
				lista.select(int(accion.valor))
				lista.grab_focus()
		"cancelar":
			lista.select(0)
		"confirmar":
			if lista.visible and lista.selected > 0:
				ejecutar(lista.get_selected_metadata(), accion.fuente_entrada)


func _process(_delta: float) -> void:
	actualizar_panel(Time.get_ticks_msec())


func actualizar_panel(ahora: int) -> void:
	panel.conexion.actualizar(ahora)
	lateral.get_node("Conexion").text = panel.conexion.etiqueta()
	var pausa: bool = panel.conexion.pausado()
	if pausa != pausa_visible:
		pausa_visible = pausa
		var continuar: Button = lateral.get_node("Continuar")
		continuar.visible = pausa
		for nombre in ["Inspeccionar", "Causa", "Accion", "ConfirmarAccion"]:
			lateral.get_node(nombre).disabled = pausa
		if pausa:
			continuar.grab_focus()
		elif motor != null and motor.fin().is_empty():
			lateral.get_node("Inspeccionar").grab_focus()
	panel.visible = panel.conexion.fuente_panel() == "virtual" and not panel.conexion.pausado() \
		and motor != null and motor.fin().is_empty()


func _input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and motor != null and motor.fin().is_empty():
		var tecla := OS.get_keycode_string(evento.keycode)
		if tecla in ["Enter", "Escape"] and not lateral.get_node("Accion").has_focus():
			return
		var accion: Dictionary = panel.entrada.traducir("teclado", tecla, 1)
		if accion.get("accion") in ["elegir-accion", "confirmar", "cancelar"]:
			recibir_accion(accion)
			get_viewport().set_input_as_handled()


func _unhandled_input(evento: InputEvent) -> void:
	if motor == null or panel.conexion.pausado():
		return
	if evento is InputEventJoypadMotion:
		var control := "stick-izquierdo" if evento.axis <= JOY_AXIS_LEFT_Y else "stick-derecho"
		if evento.axis <= JOY_AXIS_RIGHT_Y:
			var accion: Dictionary = panel.entrada.traducir("control", control, evento.axis_value)
			if not accion.is_empty():
				var eje: int = evento.axis % 2
				if accion.accion == "mover":
					$Camara.translate(Vector3(evento.axis_value, 0, 0) if eje == 0 else Vector3(0, 0, evento.axis_value))
				elif accion.accion == "mirar":
					if eje == 0:
						$Camara.rotate_y(-evento.axis_value * 0.1)
					else:
						$Camara.rotate_x(-evento.axis_value * 0.1)
	elif evento is InputEventJoypadButton and evento.pressed and evento.button_index == JOY_BUTTON_A:
		var accion: Dictionary = panel.entrada.traducir("control", "A", 1)
		if not accion.is_empty():
			ejecutar(accion.accion, accion.fuente_entrada)
