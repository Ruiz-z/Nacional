extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const PruebaCarga = preload("res://tests/test_carga_banco.gd")


static func ejecutar() -> bool:
	var caso := PruebaCarga.item()
	caso.merge({"competencia": "diagnostico-fallas", "formato": "caso-diagnostico",
		"sintomas": ["Indicador simulado fuera de escala"], "codigo_falla": "SIM-1",
		"causa_correcta": "Lectura simulada fuera de escala",
		"pasos": [{"id": "medir", "accion": "Leer el indicador", "resultado": "Lectura fuera de escala",
			"tipo_error": "valor-fuera-de-rango"}], "ruta_ideal": ["medir"]}, true)
	if not acepta(caso):
		return false
	caso.erase("ruta_ideal")
	if acepta(caso):
		return false
	caso.ruta_ideal = ["inventado"]
	if acepta(caso):
		return false
	caso.ruta_ideal = ["medir"]
	caso.pasos[0].tipo_error = "inventado"
	if acepta(caso):
		return false

	var panel := PruebaCarga.item()
	panel.merge({"competencia": "seguridad-alto-voltaje", "formato": "accion-panel",
		"fuente": {"origen": "material-oficial", "titulo": "Fixture", "pagina": "1", "referencia": "Fixture"},
		"muestra": false, "instruccion": "Pulsa el botón de la maqueta.",
		"secuencia_esperada": [{"ctrl": "paro", "valor": 1}]}, true)
	if not acepta(panel):
		return false
	panel.secuencia_esperada = []
	if acepta(panel):
		return false

	var pregunta := PruebaCarga.item()
	pregunta.correcta = 2
	return not acepta(pregunta)


static func acepta(item: Dictionary) -> bool:
	return Banco.validar_texto(JSON.stringify({"items": [item]}), "formatos.json").items.size() == 1
