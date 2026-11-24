extends VBoxContainer

const TextoLimpio = preload("res://logica/texto_limpio.gd")

signal reintento_solicitado

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")

const MenuVisual = preload("res://escenas/menu_pieza.gd")

var motor: RefCounted
var escenario := {}


func _ready() -> void:
	if get_parent() == get_tree().root:
		FondoTarjeta.aplicar(self, 16)
	$Guardar.pressed.connect(func():
		if motor != null and motor.registrar_reflexion($Reflexion.text):
			mostrar(motor))
	$Reintentar.pressed.connect(func(): reintento_solicitado.emit())


func mostrar(actual: RefCounted, datos_orden: Dictionary = {}) -> void:
	if not datos_orden.is_empty():
		escenario = datos_orden
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
	$Pregunta.text = TextoLimpio.linea(datos.pregunta if not reflexionado else datos.reflexion)
	$Reflexion.visible = not reflexionado
	$Guardar.visible = not reflexionado
	$Reintentar.visible = reflexionado
	var finales := {"resuelto": "Falla resuelta", "falta-critica": "Práctica detenida por seguridad",
		"estado-invalido": "No se pudo abrir la práctica", "limite-intentos": "Se acabaron los intentos"}
	var lineas := PackedStringArray([finales.get(datos.fin, "Práctica terminada")])
	var cierre: Dictionary = datos.diagnostico_final
	if not cierre.is_empty():
		lineas.append("Diagnóstico final: %s · Respuesta: %s" % [
			"Correcto" if cierre.correcto else "Incorrecto", MenuVisual.nombre_causa(cierre.elegida)])
		lineas.append("Causa real: %s · %s" % [MenuVisual.nombre_causa(cierre.real), TextoLimpio.linea(cierre.explicacion)])
		var marca: String = TextoLimpio.limpiar(cierre.fuente).etiqueta
		if not marca.is_empty():
			lineas.append(marca)
		lineas.append("Fuente: " + TextoLimpio.fuente(cierre.fuente))
	for intento in datos.comparacion:
		var metricas: Dictionary = datos.comparacion[intento]
		if not metricas.is_empty():
			lineas.append("%s: %d puntos · %d errores · %d ms" % [
				intento.capitalize(), metricas.puntaje, metricas.errores, metricas.tiempo_ms])
	if datos.has("errores_arnes"):
		lineas.append("Errores de medición: %d · Errores de interpretación: %d" % [
			datos.errores_arnes.medicion, datos.errores_arnes.interpretacion])
	for decision in datos.linea_tiempo:
		lineas.append("%s · %s · %s" % [nombre_accion(decision.accion),
			"Acierto" if decision.aplicada and decision.tipo_error.is_empty() else "Error",
			TextoLimpio.linea(decision.motivo)])
	for brecha in datos.brechas:
		lineas.append("Elegiste %s y ejecutaste %s." % [
			MenuVisual.nombre_causa(brecha.causa_marcada), nombre_accion(brecha.accion_ejecutada)])
	if reflexionado:
		lineas.append("Pasos para resolver la falla")
		for paso in datos.ruta_ideal:
			lineas.append("%s · %s" % [TextoLimpio.linea(paso.descripcion), TextoLimpio.fuente(paso.fuente)])
	$Detalle.text = "\n".join(lineas)



func nombre_accion(id: String) -> String:
	var acciones: Dictionary = escenario.get("acciones", {})
	var recuperaciones: Dictionary = escenario.get("recuperaciones", {})
	var regla: Dictionary = acciones.get(id, recuperaciones.get(id, {}))
	return TextoLimpio.limpiar(regla.get("titulo", "Paso de la orden")).texto
