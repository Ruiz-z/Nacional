extends RefCounted

static func ejecutar() -> bool:
	var diagnostico = load("res://logica/aprendizaje/diagnostico.gd")
	if not diagnostico.has_method("resultado"):
		return false
	var bateria := "sistema-electrico-bateria"
	var seguridad := "seguridad-alto-voltaje"
	var resultado: Dictionary = diagnostico.resultado([
		{"competencia": bateria, "valor": 100, "peso": 2, "formato": "opcion-multiple"},
		{"competencia": seguridad, "valor": 100, "peso": 2, "formato": "opcion-multiple"},
		{"competencia": seguridad, "valor": 55, "peso": 4, "formato": "accion-panel"},
	])
	return resultado[bateria] == {"dominio": 100.0, "nivel": "Experto", "confianza": "baja"} \
		and resultado[seguridad] == {"dominio": 70.0, "nivel": "Competente", "confianza": "alta"} \
		and resultado["electronica-conectividad"].confianza == "baja"
