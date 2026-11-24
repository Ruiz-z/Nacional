extends RefCounted

const FUENTE := "[MUESTRA] valor de ejemplo, sin fuente oficial"

static func datos() -> Dictionary:
	return {
		"id": "prueba", "version": "1", "zona": "gabinete", "grupo_funcion": "FG3", "descripcion": "Prueba del simulador.", "titulo": "[MUESTRA] Prueba", "fuente": FUENTE,
		"muestra": true, "dificultad": "media", "causas": ["falla", "otra"],
		"estado": {"listo": false, "tornillo_roto": false, "resuelto": false, "lugar": "A"},
		"estados_imposibles": [{"tornillo_roto": true, "resuelto": true}],
		"acciones": {
			"preparar": accion({}, {"listo": true}),
			"reparar": accion({"listo": true, "tornillo_roto": false}, {"resuelto": true}, "normal", "", "falla"),
			"romper": accion({"listo": true}, {"tornillo_roto": true}, "leve", "valor-fuera-de-rango"),
			"insegura": accion({}, {}, "critica", "accion-insegura"),
		},
		"eventos": {
			"rotura": {"condicion": {"tornillo_roto": true}, "efectos": {}, "fuente": FUENTE,
				"descripcion": "[MUESTRA] Rotura", "recuperaciones": ["reponer"]},
		},
		"recuperaciones": {
			"reponer": accion({}, {"tornillo_roto": false}).merged({
				"costo": "bajo", "tiempo": "breve", "riesgo": "bajo"}),
		},
		"terminacion": {"resuelto": {"resuelto": true}, "limite_intentos": 10},
		"ruta_ideal": ["preparar", "reparar"],
		"variante": {"estado": {"lugar": "B"}},
	}


static func accion(previas: Dictionary, efectos: Dictionary, criticidad: String = "normal",
		tipo_error: String = "", causa: String = "") -> Dictionary:
	return {"previas": previas, "efectos": efectos, "criticidad": criticidad,
		"tipo_error": tipo_error, "causa": causa, "competencia": "diagnostico-fallas",
		"descripcion": "[MUESTRA] Decisión simulada", "fuente": FUENTE}
