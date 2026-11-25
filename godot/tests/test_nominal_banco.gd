extends RefCounted

const Banco = preload("res://logica/simulador/banco_arnes.gd")
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")


static func ejecutar() -> bool:
	var correcto := true
	correcto = correcto and Banco.etiqueta_alto() == "≈5 V" and Mediciones.opciones()["5"] == "≈5 V"
	Banco.nominal_alto = 3.3
	var sano := Banco.calcular(false, false)
	correcto = correcto and is_equal_approx(sano.tp1, 3.3) and Banco.etiqueta_alto() == "≈3.3 V"
	correcto = correcto and Mediciones.opciones()["5"] == "≈3.3 V" and Banco.calcular(true, false).tp1 == 0.0
	# La opción "alto" se califica contra 3.3 V y no contra 5 V.
	var med := Mediciones.new()
	var estado := {"s1_abierto": true, "s2_abierto": false}
	for punto in ["tp1", "tp2"]:
		med.aplicar("medir_" + punto, estado)
	med.aplicar("reportar_tp1_0", estado)
	med.aplicar("reportar_tp2_5", estado)
	correcto = correcto and med.evaluar(estado) == ""
	var texto := {"acciones": {"a": {"titulo": "Registra ≈5 V", "descripcion": "Elige ≈5 V."}}}
	Escenario.aplicar_nominal(texto, Banco.etiqueta_alto())
	correcto = correcto and texto.acciones.a.titulo == "Registra ≈3.3 V"
	Banco.nominal_alto = Banco.NOMINAL_5V
	correcto = correcto and Escenario.nominal_valido(3.3) and not Escenario.nominal_valido(0) \
		and not Escenario.nominal_valido("3.3")
	return correcto
