extends VBoxContainer

signal reintento_solicitado

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")

var motor: RefCounted


func _ready() -> void:
	if get_parent() == get_tree().root:
		FondoTarjeta.aplicar(self, 16)
	$Guardar.pressed.connect(func():
		if motor != null and motor.registrar_reflexion($Reflexion.text):
			mostrar(motor))
	$Reintentar.pressed.connect(func(): reintento_solicitado.emit())


func mostrar(actual: RefCounted) -> void:
	motor = actual
	var datos: Dictionary = {} if motor == null else motor.resumen()
	var disponible := not datos.is_empty()
	visible = disponible or get_parent() == get_tree().root
	$Vacio.visible = not disponible
	$Detalle.visible = disponible
	$Pregunta.visible = disponible
	if not disponible:
		$Guardar.hide()
		$Reintentar.hide()
		$Reflexion.hide()
		$Reflexion.clear()
		return
	var reflexionado: bool = not datos.reflexion.is_empty()
	$Pregunta.text = datos.pregunta if not reflexionado else datos.reflexion
	$Reflexion.visible = not reflexionado
	$Guardar.visible = not reflexionado
	$Reintentar.visible = reflexionado
	var lineas := PackedStringArray([datos.fin.replace("-", " ")])
	for intento in datos.comparacion:
		var metricas: Dictionary = datos.comparacion[intento]
		if not metricas.is_empty():
			lineas.append("%s: %d puntos · %d errores · %d ms" % [
				intento.capitalize(), metricas.puntaje, metricas.errores, metricas.tiempo_ms])
	for decision in datos.linea_tiempo:
		lineas.append("%s · %s · %s" % [decision.accion,
			"Acierto" if decision.aplicada and decision.tipo_error.is_empty() else "Error",
			decision.motivo])
	for brecha in datos.brechas:
		lineas.append("Brecha: %s → %s" % [brecha.causa_marcada, brecha.accion_ejecutada])
	if reflexionado:
		lineas.append("Ruta ideal")
		for paso in datos.ruta_ideal:
			lineas.append("%s · %s" % [paso.descripcion, paso.fuente])
	$Detalle.text = "\n".join(lineas)
