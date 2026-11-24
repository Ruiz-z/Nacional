extends Node3D

signal decision_tomada(decision: Dictionary)

const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")

@export_file("*.json") var archivo := "../contenido/escenarios/aislamiento.json"
var motor: RefCounted
var datos: Dictionary
var ultimo_ms: int


func _ready() -> void:
	var carga := Escenario.cargar(ProjectSettings.globalize_path("res://").path_join(archivo))
	datos = carga.get("escenario", {})
	if datos.is_empty():
		$Interfaz/Lateral/Estado.text = str(carga)
		return
	motor = Motor.new(datos)
	ultimo_ms = Time.get_ticks_msec()
	$Interfaz/Lateral/Inspeccionar.pressed.connect(func(): ejecutar("inspeccionar", "teclado"))
	$Interfaz/Lateral/Inspeccionar.grab_focus()
	mostrar_estado()


func ejecutar(id: String, fuente: String) -> void:
	var ahora := Time.get_ticks_msec()
	var decision: Dictionary = motor.ejecutar(id, fuente, ahora - ultimo_ms)
	ultimo_ms = ahora
	mostrar_estado()
	decision_tomada.emit(decision)


func mostrar_estado() -> void:
	var lineas := PackedStringArray([datos.titulo])
	for clave in motor.estado():
		lineas.append("%s: %s" % [clave.replace("_", " "), motor.estado()[clave]])
	$Interfaz/Lateral/Estado.text = "\n".join(lineas)


func _unhandled_input(evento: InputEvent) -> void:
	if motor == null:
		return
	var panel = $Interfaz/Lateral/PanelVirtual
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
