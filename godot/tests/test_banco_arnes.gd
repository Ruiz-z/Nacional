extends RefCounted

const Banco = preload("res://logica/simulador/banco_arnes.gd")


static func ejecutar() -> bool:
	for fila in [[false, false, 5.0, 5.0], [true, false, 0.0, 5.0],
			[false, true, 5.0, 0.0], [true, true, 0.0, 0.0]]:
		var lectura := Banco.calcular(fila[0], fila[1])
		if not Banco.coincide(lectura.tp1, fila[2]) or not Banco.coincide(lectura.tp2, fila[3]):
			return false
	return Banco.calcular(true, false).aviso == Banco.calcular(false, true).aviso \
		and Banco.coincide(4.8, 5.0) and Banco.coincide(0.2, 0.0) and not Banco.coincide(5.21, 5.0)
