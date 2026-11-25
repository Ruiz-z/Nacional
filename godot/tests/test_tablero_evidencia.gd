extends RefCounted

const Evidencia = preload("res://logica/tablero/evidencia.gd")

static func ejecutar() -> bool:
	var competencia := "diagnostico-fallas"
	var vacia: Dictionary = Evidencia.calcular([], [])[competencia]
	if vacia.errores != 0 or vacia.oportunidades != 0 or vacia.sin_ayuda != 0 or not vacia.tiempos.is_empty():
		return false
	var intentos := [
		{"competencia": competencia, "formato": "opcion-multiple", "item": "pregunta",
			"resultado": "incorrecto", "ayudas": 1, "tiempo_ms": 0},
		{"competencia": competencia, "formato": "accion-panel", "item": "panel",
			"resultado": "correcto", "fuente_entrada": "panel", "ayudas": 0, "tiempo_ms": 600},
		{"competencia": competencia, "formato": "escenario", "item": "orden", "caso": "orden",
			"resultado": "correcto", "fuente_entrada": "teclado", "ayudas": 0, "reloj_sim": "2026-01-01"},
		{"competencia": competencia, "formato": "detalle-escenario", "item": "orden",
			"resultado": "incorrecto", "tipo_error": "paso-omitido"}]
	var eventos := [
		{"escenario": "orden", "accion": "medir", "fuente_falla": "banco",
			"tiempo_ms": 200, "reloj_sim": "2026-01-01"},
		{"escenario": "orden", "accion": "medir", "fuente_entrada": "banco",
			"tiempo_ms": 400, "reloj_sim": "2026-01-01"}]
	var dato: Dictionary = Evidencia.calcular(intentos, eventos, {"orden": {"medir": competencia}})[competencia]
	return dato.teoria == 1 and dato.practicas == 0 and dato.banco == 1 and dato.errores == 1 \
		and dato.oportunidades == 3 and dato.sin_ayuda == 2 and dato.tiempos.orden.medir == 300.0 \
		and dato.tiempos[""].pregunta == 0.0
