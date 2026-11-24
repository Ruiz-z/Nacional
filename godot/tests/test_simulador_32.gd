extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")

static func ejecutar() -> bool:
	var Formato := load("res://logica/simulador/escenario.gd") as GDScript
	if Formato == null:
		return false
	var datos := Prueba.datos()
	if not Formato.validar(datos, "demo.json").errores.is_empty():
		return false
	for campo in ["estado", "acciones", "eventos", "recuperaciones", "fuente"]:
		var incompleto := datos.duplicate(true)
		incompleto.erase(campo)
		var resultado: Dictionary = Formato.validar(incompleto, "demo.json")
		if not resultado.escenario.is_empty() or not resultado.errores[0].begins_with("demo.json: " + campo):
			return false
	datos.estado.tornillo_roto = true
	datos.estado.resuelto = true
	return Formato.validar(datos, "demo.json").errores[0].begins_with("demo.json: estado:")
