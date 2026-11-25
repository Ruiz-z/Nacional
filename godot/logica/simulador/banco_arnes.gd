extends RefCounted

const AVISO := "Módulo auxiliar sin respuesta"
const TOLERANCIA := 0.2
const NOMINAL_5V := 5.0

# Tensión de la rama en alto. 5 V para el Arduino Uno; 3.3 V para el ESP32.
static var nominal_alto := NOMINAL_5V


static func etiqueta_alto() -> String:
	return "≈%s V" % String.num(nominal_alto, 1).trim_suffix(".0")


static func calcular(s1_abierto: bool, s2_abierto: bool) -> Dictionary:
	return {"tp1": 0.0 if s1_abierto else nominal_alto, "tp2": 0.0 if s2_abierto else nominal_alto,
		"aviso": AVISO if s1_abierto or s2_abierto else "Módulo disponible"}


static func coincide(lectura: float, nominal: float) -> bool:
	var diferencia := absf(lectura - nominal)
	return diferencia < TOLERANCIA or is_equal_approx(diferencia, TOLERANCIA)
