extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Asistente = preload("res://logica/tablero/asistente.gd")


static func ejecutar() -> bool:
	var banco := Banco.cargar()
	var escenario := Escenario.cargar(Escenario.AISLAMIENTO)
	var asistente := Asistente.new()
	return banco.errores.is_empty() and not banco.items.is_empty() \
		and escenario.errores.is_empty() and not escenario.escenario.is_empty() \
		and asistente.indexar([{"ruta": "banco.json", "cita": "Banco de muestra"}])
