extends RefCounted

const Formato = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Prueba = preload("res://tests/escenario_prueba.gd")

static func ejecutar() -> bool:
	var ruta := ProjectSettings.globalize_path("res://").path_join("../contenido/escenarios/comunicacion.json")
	var resultado := Formato.cargar(ruta)
	if not resultado.errores.is_empty():
		printerr(resultado.errores)
		return false
	var datos: Dictionary = resultado.escenario
	if datos.fuente != Prueba.FUENTE or not datos.muestra or datos.sintomas.is_empty() \
			or not datos.codigo_falla.begins_with("[MUESTRA]"):
		return false
	var sesion := Motor.new(datos)
	sesion.marcar_causa("otro-modulo")
	sesion.ejecutar("revisar_sintomas", "teclado", 1)
	sesion.ejecutar("confirmar_diagnostico", "panel", 1)
	return sesion.fin() == "resuelto" and sesion.brechas().size() == 1
