extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")


static func ejecutar() -> bool:
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	if datos.is_empty() or Escenario.cargar("escenarios/comunicacion.json").escenario.is_empty():
		return false
	datos.acciones.inspeccionar.componente = "inventado"
	var errores: Array = Escenario.validar(datos, "prueba.json").errores
	return errores.size() == 1 and errores[0].begins_with("prueba.json: acciones.inspeccionar.componente:")
