extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const ENTRADAS_VIRTUALES := ["virtual", "teclado", "control", "raton"]


static func es_oportunidad(intento: Dictionary) -> bool:
	return intento.get("formato") != "detalle-escenario" and intento.get("tipo_error") != "diagnostico-vs-accion"


static func calcular(intentos: Array, eventos: Array, competencias_por_accion: Dictionary = {}) -> Dictionary:
	var salida := {}
	for competencia in Banco.COMPETENCIAS:
		salida[competencia] = {"teoria": 0, "practicas": 0, "banco": 0, "errores": 0,
			"oportunidades": 0, "sin_ayuda": 0, "tiempos": {}}
	var bancos := {}
	var sesiones_por_caso := {}
	for intento in intentos:
		if intento.get("formato") == "escenario" and es_oportunidad(intento):
			var clave := [caso(intento), intento.get("reloj_sim", "")]
			var sesiones: Dictionary = sesiones_por_caso.get_or_add(clave, {})
			sesiones[intento.get("sesion_id", "")] = true
	for evento in eventos:
		var escenario: String = evento.get("escenario", "")
		if evento.get("fuente_entrada") == "banco" or evento.get("fuente_falla") == "banco":
			bancos[[escenario, evento.get("reloj_sim", "")]] = true
		var acciones: Dictionary = competencias_por_accion.get(escenario, {})
		var accion: String = evento.get("accion", "")
		var competencia: String = acciones.get(accion, "")
		if salida.has(competencia):
			agregar_tiempo(salida[competencia].tiempos, escenario, accion, evento.get("tiempo_ms"))
	for intento in intentos:
		if not es_oportunidad(intento) or not salida.has(intento.competencia):
			continue
		var dato: Dictionary = salida[intento.competencia]
		var formato: String = intento.get("formato", "")
		var entrada: String = intento.get("fuente_entrada", "")
		var clave := [caso(intento), intento.get("reloj_sim", "")]
		dato.oportunidades += 1
		dato.errores += int(intento.get("resultado") == "incorrecto" or intento.get("tipo_error") == "falta-critica")
		dato.sin_ayuda += int(intento.get("ayudas", -1) == 0)
		if formato == "opcion-multiple":
			dato.teoria += 1
		elif entrada == "banco" or (formato == "escenario" and bancos.has(clave)
				and sesiones_por_caso[clave].size() == 1):
			dato.banco += 1
		elif entrada in ENTRADAS_VIRTUALES and not (formato == "escenario" and bancos.has(clave)):
			dato.practicas += 1
		if formato != "escenario":
			agregar_tiempo(dato.tiempos, "", intento.item, intento.get("tiempo_ms"))
	for dato in salida.values():
		for acciones in dato.tiempos.values():
			for accion in acciones:
				var medicion: Array = acciones[accion]
				acciones[accion] = medicion[0] / medicion[1]
	return salida


static func caso(intento: Dictionary) -> String:
	var id: String = intento.get("caso", "")
	return intento.get("item", "") if id.is_empty() else id


static func agregar_tiempo(tiempos: Dictionary, escenario: String, accion: String, tiempo: Variant) -> void:
	if (tiempo is int or tiempo is float) and tiempo >= 0:
		var acciones: Dictionary = tiempos.get_or_add(escenario, {})
		var medicion: Array = acciones.get_or_add(accion, [0.0, 0])
		medicion[0] += tiempo
		medicion[1] += 1
