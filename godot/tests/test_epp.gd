extends RefCounted

const Epp = preload("res://logica/simulador/epp.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Prueba = preload("res://tests/escenario_prueba.gd")


static func ejecutar() -> bool:
	return catalogo_y_zonas() and ofrecidos_estables() and evaluacion() and motor_exige() \
		and escenarios_reales()


static func con_zona(zona: String, extra := {}) -> Dictionary:
	return {"id": "orden-" + zona, "zona": zona}.merged(extra)


static func catalogo_y_zonas() -> bool:
	for zona in Escenario.ZONAS:
		var lista := Epp.requeridos(con_zona(zona))
		if lista.is_empty() or not Epp.valido(lista):
			printerr("EPP sin requisitos válidos en ", zona)
			return false
	if "guantes_dielectricos" not in Epp.requeridos(con_zona("motor")) \
			or "casco" not in Epp.requeridos(con_zona("bajos")) \
			or "guantes_dielectricos" in Epp.requeridos(con_zona("bajos")):
		printerr("El EPP no cambia con la tarea")
		return false
	var propio := Epp.requeridos(con_zona("faros", {"epp": {"requeridos": ["casco"]}}))
	if propio != ["casco"]:
		printerr("El campo epp del escenario no manda")
		return false
	var invalido := Epp.requeridos(con_zona("faros", {"epp": {"requeridos": ["capa-magica"]}}))
	return invalido == Epp.requeridos(con_zona("faros"))


static func ofrecidos_estables() -> bool:
	for zona in Escenario.ZONAS:
		var orden := con_zona(zona)
		var uno := Epp.ofrecidos(orden)
		if uno != Epp.ofrecidos(orden):
			printerr("El vestidor cambia entre intentos")
			return false
		for id in Epp.requeridos(orden):
			if id not in uno:
				printerr("Falta equipo exigido en el vestidor: ", id)
				return false
		if uno.size() != Epp.requeridos(orden).size() + 3:
			printerr("El vestidor no ofrece tres señuelos")
			return false
	return true


static func evaluacion() -> bool:
	var orden := con_zona("motor")
	var exigidos := Epp.requeridos(orden)
	var bien := Epp.evaluar(orden, exigidos)
	var corto := Epp.evaluar(orden, exigidos.slice(1))
	var sobra := Epp.evaluar(orden, exigidos + ["chaleco", "chaleco", "inventado"])
	return bien.completo and bien.faltantes.is_empty() and bien.sobrantes.is_empty() \
		and not corto.completo and corto.faltantes == [exigidos[0]] \
		and sobra.completo and sobra.sobrantes == ["chaleco"]


static func motor_exige() -> bool:
	var datos := Prueba.datos()
	var libre := Motor.new(datos)
	if libre.epp_pendiente() or not libre.ejecutar("preparar", "teclado", 10).aplicada:
		printerr("Sin exigir EPP el motor debe seguir igual")
		return false
	var motor := Motor.new(datos)
	motor.exigir_epp()
	var antes := motor.puntaje()
	var bloqueado := motor.ejecutar("preparar", "teclado", 10)
	if not motor.epp_pendiente() or bloqueado.get("aplicada", true) or motor.puntaje() != antes:
		printerr("El EPP pendiente no bloquea los pasos")
		return false
	var exigidos := Epp.requeridos(datos)
	var incompleto := motor.registrar_epp(exigidos.slice(1), "teclado", 500)
	if incompleto.aplicada or incompleto.tipo_error != "paso-omitido" or not motor.epp_pendiente() \
			or motor.puntaje() >= antes:
		printerr("Un EPP incompleto debe seguir pendiente y restar")
		return false
	var completo := motor.registrar_epp(exigidos + ["chaleco"], "teclado", 800)
	if not completo.aplicada or completo.tipo_error != "paso-innecesario" or motor.epp_pendiente():
		printerr("Con el EPP exigido el motor debe liberar los pasos")
		return false
	if not motor.registrar_epp(exigidos, "teclado", 1).is_empty():
		printerr("No se registra el EPP dos veces")
		return false
	if not motor.ejecutar("preparar", "teclado", 10).aplicada:
		printerr("Equipado, el paso debe correr")
		return false
	motor.ejecutar("reparar", "teclado", 10)
	var entrega := motor.resultados("2026-01-01T00:00:00Z")
	var registros: Array = entrega.eventos.filter(func(e: Dictionary): return e.accion == "equiparse_epp")
	return registros.size() == 2 and entrega.errores.size() >= 2 \
		and entrega.intentos.any(func(i: Dictionary): return i.competencia == Epp.COMPETENCIA)


static func escenarios_reales() -> bool:
	for nombre in ["faros", "motor", "aislamiento", "neumatico_pinchado", "modulo_auxiliar", "comunicacion"]:
		var carga := Escenario.cargar("escenarios/%s.json" % nombre)
		if not carga.errores.is_empty() or Epp.requeridos(carga.escenario).is_empty():
			printerr("Orden sin EPP: ", nombre)
			return false
	return true
