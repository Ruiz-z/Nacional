extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Formato = preload("res://logica/simulador/escenario.gd")

static func ejecutar() -> bool:
	var datos := Prueba.datos()
	datos.eventos.rotura.efectos = {"tornillo_roto": false}
	if not Formato.validar(datos, "ciclo.json").errores.is_empty():
		return false
	datos.eventos["rebote"] = datos.eventos.rotura.duplicate(true)
	datos.eventos.rebote.condicion.tornillo_roto = false
	datos.eventos.rebote.efectos.tornillo_roto = true
	var resultado := Formato.validar(datos, "ciclo.json")
	return resultado.escenario.is_empty() and resultado.errores[0].begins_with("ciclo.json: eventos:")
