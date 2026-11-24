extends RefCounted

const Base = preload("res://tests/base_tablero.gd")

class ModeloFalso:
	extends RefCounted
	var llamadas := 0
	var inventar := false

	func generar(peticion: Dictionary) -> Dictionary:
		llamadas += 1
		if peticion.fuentes.size() != 1 or peticion.historial.has("nombre"):
			return {}
		return {"fuente": 0, "fragmento": "Valor inventado." if inventar else "El indicador muestra la carga simulada."}


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var asistente = load("res://logica/tablero/asistente.gd")
	if asistente == null:
		return false
	var archivo := base + ".txt"
	var fuente := FileAccess.open(archivo, FileAccess.WRITE)
	if fuente == null or not fuente.store_string("contexto ".repeat(500) + "El indicador muestra la carga simulada."):
		return false
	fuente.close()
	if not asistente.indexar(base, [{"ruta": archivo, "cita": "[MUESTRA] Indicadores, p. 1"}], Base.consultar):
		return false
	var modelo := ModeloFalso.new()
	var respuesta: Dictionary = asistente.responder(base, "¿cárga?", modelo.generar,
		{"alias": "T-01", "nombre": "dato ajeno"}, Base.consultar)
	if respuesta.texto != "El indicador muestra la carga simulada." or respuesta.cita != "[MUESTRA] Indicadores, p. 1":
		return false
	respuesta = asistente.responder(base, "neumático NEAR *", modelo.generar, {}, Base.consultar)
	if respuesta.texto != "no tengo esa información" or modelo.llamadas != 1:
		return false
	modelo.inventar = true
	respuesta = asistente.responder(base, "carga", modelo.generar, {}, Base.consultar)
	return respuesta.texto == "no tengo esa información" and respuesta.cita.is_empty()
