extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Banco = preload("res://logica/simulador/banco_arnes.gd")
const Motor = preload("res://logica/simulador/motor.gd")


static func ejecutar() -> bool:
	var carga := Escenario.cargar("escenarios/modulo_auxiliar.json")
	if not carga.errores.is_empty():
		printerr(carga.errores)
		return false
	var datos: Dictionary = carga.escenario
	var motor := Motor.new(datos)
	var aviso: String = motor.mediciones.leer.call(motor.estado()).aviso
	for variante in [false, true, false]:
		if motor.estado().s2_abierto != variante or motor.mediciones.leer.call(motor.estado()).aviso != aviso:
			return false
		var ruta: Array = datos.variante.ruta_ideal if variante else datos.ruta_ideal
		for id in ruta:
			if not motor.ejecutar(id, "virtual" if id == "reconectar" else "teclado", 0).aplicada:
				return false
		if motor.fin() != "resuelto" or motor.puntaje() != 100:
			return false
		motor = motor.reintentar()
	if motor.ejecutar("reconectar", "teclado", 0).aplicada:
		return false
	var reparacion := motor.ejecutar("reconectar", "virtual", 0)
	if reparacion.tipo_error != "paso-omitido":
		return false
	for caso in [
		[["medir_tp2", "reportar_tp2_5"], "punto-de-medicion-incorrecto"],
		[["medir_tp1", "medir_tp2", "reportar_tp1_0", "reportar_tp2_5"], "lectura-mal-interpretada"],
		[["medir_tp1", "medir_tp2", "reportar_tp1_otra", "reportar_tp2_5"], "valor-fuera-de-rango"],
		[["medir_tp1", "medir_tp2", "reportar_tp1_5", "reportar_tp2_5"], "valor-fuera-de-rango"],
	]:
		motor = Motor.new(datos)
		for id in caso[0]:
			motor.ejecutar(id, "teclado", 0)
		if motor.ejecutar("diagnosticar_modulo", "teclado", 0).tipo_error != caso[1]:
			return false
		if not motor.ejecutar("reconectar", "virtual", 0).tipo_error.is_empty():
			return false
		if motor.resumen().errores.size() != 1:
			return false
	var lector := func(_estado: Dictionary) -> Dictionary: return Banco.calcular(false, true)
	motor = Motor.new(datos, lector, "banco físico")
	var medida := motor.ejecutar("medir_tp1", "teclado", 0)
	return medida.lectura_mostrada == 5.0 and medida.fuente_falla == "banco físico"
