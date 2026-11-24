extends RefCounted

const Prueba = preload("res://tests/escenario_prueba.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var sesion := Motor.new(Prueba.datos())
	if not sesion.has_method("resumen") or not sesion.resumen().is_empty():
		return false
	sesion.ejecutar("preparar", "teclado", 10)
	sesion.ejecutar("insegura", "panel", 20)
	var previo := sesion.resumen()
	if previo.linea_tiempo.size() != 2 or previo.errores.size() != 1 \
			or previo.aciertos.size() != 1 or previo.get("pregunta") != "¿Qué harías distinto?" \
			or previo.has("ruta_ideal") or sesion.registrar_reflexion(" "):
		return false
	if not sesion.registrar_reflexion("Revisaría la decisión anterior."):
		return false
	previo = sesion.resumen()
	if previo.reflexion.is_empty() or previo.ruta_ideal[0].accion != "preparar" \
			or previo.ruta_ideal[0].fuente != Prueba.FUENTE:
		return false
	var nuevo: RefCounted = sesion.reintentar()
	nuevo.ejecutar("reparar", "teclado", 15)
	var comparacion: Dictionary = nuevo.resumen().comparacion
	return comparacion.anterior == {"errores": 1, "tiempo_ms": 30, "puntaje": 0} \
		and comparacion.actual == {"errores": 0, "tiempo_ms": 15, "puntaje": 100}
