extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Practica = preload("res://logica/simulador/practica.gd")


static func ejecutar() -> bool:
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	var motor := Motor.new(datos)
	var esperadas := {"compuerta": ["inspeccionar"], "monitor": ["evaluar_indicio"],
		"cables": ["ignorar_aviso_seguridad"], "terminal": ["forzar_pieza"],
		"bateria": ["confirmar_solucion", "elegir_otro_sector", "descartar_indicio"]}
	for pieza in esperadas:
		var opciones: Array = Practica.opciones(motor, datos, pieza).keys()
		opciones.sort()
		var ids: Array = esperadas[pieza]
		ids.sort()
		if opciones != ids:
			return false
	motor.ejecutar("inspeccionar", "teclado", 0)
	motor.ejecutar("forzar_pieza", "teclado", 0)
	if not Practica.opciones(motor, datos, "terminal").has("reponer_pieza") \
			or Practica.opciones(motor, datos, "bateria").has("reponer_pieza"):
		return false
	datos.acciones.confirmar_solucion.erase("componente")
	if not Practica.opciones(motor, datos, "bateria").has("confirmar_solucion"):
		return false
	var comunicacion: Dictionary = Escenario.cargar("escenarios/comunicacion.json").escenario
	return Practica.opciones(Motor.new(comunicacion), comunicacion, "monitor").size() == 3
