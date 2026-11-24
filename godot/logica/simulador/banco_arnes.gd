extends RefCounted

const AVISO := "Módulo auxiliar sin respuesta"
const TOLERANCIA := 0.2


static func calcular(s1_abierto: bool, s2_abierto: bool) -> Dictionary:
	return {"tp1": 0.0 if s1_abierto else 5.0, "tp2": 0.0 if s2_abierto else 5.0,
		"aviso": AVISO if s1_abierto or s2_abierto else "Módulo disponible"}


static func coincide(lectura: float, nominal: float) -> bool:
	var diferencia := absf(lectura - nominal)
	return diferencia < TOLERANCIA or is_equal_approx(diferencia, TOLERANCIA)
