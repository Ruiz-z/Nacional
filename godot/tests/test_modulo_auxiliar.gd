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
	for intento in range(4):
		var variante := intento % 2 == 1
		if motor.estado().s2_abierto != variante or motor.mediciones.leer.call(motor.estado()).aviso != aviso:
			return false
		var ruta: Array = datos.variante.ruta_ideal if variante else datos.ruta_ideal
		for id in ruta:
			if not motor.ejecutar(id, "virtual" if id == "reconectar" else "teclado", 0).aplicada:
				return false
		if motor.fin() != "resuelto" or motor.puntaje() != 100:
			return false
		var correcta := "senal" if variante else "alimentacion"
		var elegida := correcta if intento < 2 else "modulo"
		if not comprobar_cierre(motor, elegida, correcta):
			return false
		motor = motor.reintentar()
	if motor.ejecutar("reconectar", "teclado", 0).aplicada:
		return false
	var reparacion := motor.ejecutar("reconectar", "virtual", 0)
	if reparacion.tipo_error != "paso-omitido":
		return false
	for caso in [
		[["medir_tp2", "reportar_tp2_5"], "paso-omitido"],
		[["medir_tp1", "medir_tp2"], "paso-omitido"],
		[["reportar_tp1_0", "reportar_tp2_5"], "paso-omitido"],
		[["medir_tp1", "medir_tp2", "reportar_tp1_otra", "reportar_tp2_5"], "valor-fuera-de-rango"],
		[["medir_tp1", "medir_tp2", "reportar_tp1_5", "reportar_tp2_5"], "valor-fuera-de-rango"],
	]:
		motor = Motor.new(datos)
		for id in caso[0]:
			motor.ejecutar(id, "teclado", 0)
		if motor.ejecutar("reconectar", "virtual", 0).tipo_error != caso[1]:
			return false
		if motor.registrar_diagnostico("modulo", "teclado", 0).correcto:
			return false
		if motor.resumen().errores_arnes != {"medicion": 1, "interpretacion": 0}:
			return false
	var lector := func(_estado: Dictionary) -> Dictionary: return Banco.calcular(false, true)
	motor = Motor.new(datos, lector, "banco físico")
	var medida := motor.ejecutar("medir_tp1", "teclado", 0)
	return medida.lectura_mostrada == 5.0 and medida.fuente_falla == "banco físico"


static func comprobar_cierre(motor: Motor, elegida: String, real: String) -> bool:
	var correcta := elegida == real
	if not motor.pendiente_diagnostico() or motor.resumen().errores_arnes.interpretacion != 0:
		return false
	var cierre := motor.registrar_diagnostico(elegida, "control", 20)
	if cierre.real != real or cierre.correcto != correcta or motor.pendiente_diagnostico():
		return false
	if not motor.registrar_diagnostico(real, "teclado", 20).is_empty():
		return false
	var resultados := motor.resultados("2026-11-24T00:00:00Z")
	var intento: Dictionary = resultados.intentos.back()
	var evento: Dictionary = resultados.eventos.back()
	return motor.resumen().errores_arnes.interpretacion == (0 if correcta else 1) \
		and evento.accion == "diagnostico_final" and evento.causa_elegida == elegida \
		and evento.tipo_error == ("" if correcta else "lectura-mal-interpretada") \
		and evento.criticidad == ("normal" if correcta else "leve") \
		and motor.puntaje() == (100 if correcta else 88) \
		and intento.respuesta == elegida and intento.fuente_entrada == "control" \
		and intento.resultado == ("correcto" if correcta else "incorrecto")
