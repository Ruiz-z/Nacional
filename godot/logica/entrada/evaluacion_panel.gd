extends RefCounted


static func comparar(recibida: Array, esperada: Array, criticidades: Dictionary,
		bloqueo_activo: bool = false) -> Array[Dictionary]:
	var errores: Array[Dictionary] = []
	var pendientes := esperada.duplicate()
	var ultima_posicion := -1
	for indice in range(recibida.size()):
		var evento: Dictionary = recibida[indice]
		var control: String = evento.get("accion", evento.get("ctrl", ""))
		if control == "bloqueo":
			bloqueo_activo = evento.valor == 1
		var posicion := buscar(pendientes, control, evento.valor)
		if not bloqueo_activo and criticidades.has(control):
			errores.append({"tipo_error": "accion-insegura", "criticidad": criticidades[control],
				"indice": indice})
		elif posicion < 0:
			errores.append({"tipo_error": "paso-innecesario", "indice": indice})
		elif posicion < ultima_posicion:
			errores.append({"tipo_error": "orden-incorrecto", "indice": indice})
		if posicion >= 0:
			pendientes[posicion] = null
			ultima_posicion = maxi(ultima_posicion, posicion)
	for indice in range(pendientes.size()):
		if pendientes[indice] != null:
			errores.append({"tipo_error": "paso-omitido", "indice_esperado": indice})
	return errores


static func buscar(pendientes: Array, control: String, valor: Variant) -> int:
	for indice in range(pendientes.size()):
		var esperado: Variant = pendientes[indice]
		if esperado != null and esperado.ctrl == control and esperado.valor == valor:
			return indice
	return -1


static func evaluar_torque(valor: float, minimo: float, maximo: float) -> Dictionary:
	if is_finite(valor) and valor >= maxf(0, minimo) and valor <= minf(100, maximo):
		return {}
	return {"tipo_error": "valor-fuera-de-rango", "valor": valor}
