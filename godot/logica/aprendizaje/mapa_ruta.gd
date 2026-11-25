extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const TextoLimpio = preload("res://logica/texto_limpio.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")
const OTROS_ERRORES := {
	"falta-critica": "Falta crítica",
	"diagnostico-vs-accion": "Aplicación incorrecta del diagnóstico",
	"accion-insegura": "Acción insegura",
	"respuesta-incorrecta": "Respuesta incorrecta",
}

const EXPLICACIONES_ERROR := {
	"punto-de-medicion-incorrecto": ["La medición se hizo en un punto distinto al indicado."],
	"valor-fuera-de-rango": ["El valor anotado quedó fuera del rango esperado."],
	"lectura-mal-interpretada": ["La conclusión no coincidió con la lectura obtenida."],
	"paso-omitido": ["Faltó un paso necesario del procedimiento."],
	"orden-incorrecto": ["Hiciste los pasos en una secuencia distinta a la indicada."],
	"causa-equivocada": ["Elegiste una causa que las pruebas no respaldaban."],
	"herramienta-equivocada": ["Usaste una herramienta distinta a la que pedía el paso."],
	"paso-innecesario": ["Hiciste un paso que no aportó evidencia al diagnóstico."],
	"falta-critica": ["Un paso puso en riesgo la seguridad durante la práctica.",
		"Repasa las condiciones de seguridad del ejercicio antes de actuar."],
	"diagnostico-vs-accion": ["La acción que hiciste no correspondía al diagnóstico.",
		"Elige una acción que atienda la causa que confirmaste."],
	"accion-insegura": ["Hiciste una acción sin cumplir una condición de seguridad.",
		"Comprueba las condiciones de seguridad antes de cada paso."],
	"respuesta-incorrecta": ["La respuesta no coincidió con la esperada.",
		"Revisa la respuesta correcta y repasa el tema antes de intentarlo de nuevo."],
}
const DIFICULTADES := {"facil": "Fácil", "media": "Media", "dificil": "Difícil"}


static func armar(motivos: Array, instantanea: Dictionary, historial: Array,
		ordenes_catalogo: Array, ordenes_ia: Dictionary, hoy: Dictionary) -> Array:
	var criticas := Ruta.pendientes_criticas(historial)
	var sesion := 0
	var conteos := {}
	for intento in historial:
		sesion = maxi(sesion, intento.get("sesion", 0))
		var tipo := tipo_error(intento)
		if not tipo.is_empty():
			var propios: Dictionary = conteos.get_or_add(intento.competencia, {})
			propios[tipo] = propios.get(tipo, 0) + 1

	var catalogo := {}
	for orden in ordenes_catalogo:
		catalogo[orden.id] = orden

	var primeros := []
	var resto := []
	for tema in motivos:
		var competencia: String = tema.competencia
		var dominio: float = instantanea.get(competencia, {}).get("dominio", 0.0)
		var nombre: String = Banco.COMPETENCIAS.get(competencia, competencia)
		var estado := "Hoy" if hoy.has(competencia) else "Después"
		var critica := criticas.has(competencia)
		if critica:
			estado = "Primero"
		elif Ruta.aprobada(dominio, Ruta.critica_reciente(historial, competencia, sesion)):
			estado = "Hecho"

		var detalle: Dictionary = ordenes_ia.get(competencia, {})
		var propios: Dictionary = conteos.get(competencia, {})
		var destino := primeros if critica else resto
		destino.append({
			"competencia": competencia, "nombre": nombre, "dominio": roundi(dominio),
			"estado": estado, "errores": errores(propios, competencia),
			"motivo": tema.get("motivo", ""),
			"ordenes": ordenes(catalogo, detalle.get("ordenes", []), nombre),
			"temas": detalle.get("temas", []).map(func(entrada: Dictionary) -> Dictionary:
				return entrada.merged({"competencia": competencia})),
			"refuerzo": refuerzo(tema.get("refuerzo", ""), propios),
		})
	return primeros + resto


static func errores(conteo: Dictionary, competencia: String) -> Array:
	if conteo.is_empty():
		return [{"nombre": "Sin errores", "conteo": 0, "tipo_error": "", "competencia": competencia}]
	var ramas := []
	for tipo in conteo:
		var nombre: String = Ruta.NOMBRES_ERROR.get(tipo, OTROS_ERRORES.get(tipo, "Otro error registrado"))
		nombre = nombre.left(1).to_upper() + nombre.substr(1)
		ramas.append({"nombre": nombre, "conteo": conteo[tipo],
			"tipo_error": tipo, "competencia": competencia})
	return ramas


static func refuerzo(texto: String, conteo: Dictionary) -> String:
	if not texto.is_empty():
		return texto
	var frecuencia := 0
	for tipo in conteo:
		if Ruta.REFUERZOS.has(tipo) and conteo[tipo] > frecuencia:
			frecuencia = conteo[tipo]
			texto = Ruta.REFUERZOS[tipo]
	return texto


static func ordenes(catalogo: Dictionary, sugeridas: Array, competencia: String) -> Array:
	var seleccion := []
	for id in sugeridas:
		if catalogo.has(id) and catalogo[id] not in seleccion:
			seleccion.append(catalogo[id])
			if seleccion.size() == 3:
				break
	if seleccion.is_empty():
		for orden in catalogo.values():
			if orden.get("competencia") == competencia:
				seleccion.append(orden)
				if seleccion.size() == 3:
					break
	return seleccion


static func tipo_error(intento: Dictionary) -> String:
	var registrado: Variant = intento.get("tipo_error")
	if registrado is String and not registrado.is_empty():
		return registrado
	return "respuesta-incorrecta" if intento.get("resultado") == "incorrecto" else ""


static func detalle(nodo: Dictionary, tipo: String, historial: Array, banco_items: Array) -> Dictionary:
	var datos := {"titulo": nodo.get("titulo", nodo.get("nombre", "")),
		"parrafos": [], "preguntas": [], "acciones": []}
	var parrafos: Array = datos.parrafos
	match tipo:
		"competencia":
			parrafos.append("%s · Dominio: %d %%" % [nodo.estado, nodo.dominio])
			parrafos.append_array([nodo.motivo, nodo.refuerzo, nodo.get("fuente_propuesta", "")])
			var resumen := PackedStringArray()
			for error in nodo.errores:
				resumen.append("%s · %d" % [error.nombre, error.conteo] if error.conteo else error.nombre)
			parrafos.append("Qué falló\n" + "\n".join(resumen))
			for grupo in ["temas", "ordenes"]:
				var titulos := PackedStringArray()
				for entrada in nodo[grupo]:
					titulos.append(entrada.titulo)
				if not titulos.is_empty():
					var encabezado := "Temas" if grupo == "temas" else "Órdenes del taller"
					parrafos.append(encabezado + "\n" + "\n".join(titulos))
			datos.acciones.append({"texto": "Practicar en el taller", "competencia": nodo.competencia})
		"error":
			var cantidad: int = nodo.conteo
			parrafos.append("Ocurrió una vez." if cantidad == 1 else "Ocurrió %d veces." % cantidad)
			if cantidad > 0:
				var error: String = nodo.tipo_error
				parrafos.append_array(EXPLICACIONES_ERROR.get(error,
					["Revisa el intento y repasa el procedimiento del ejercicio."]))
				parrafos.append(Ruta.REFUERZOS.get(error, ""))
				datos.preguntas = preguntas_falladas(nodo.competencia, error, historial, banco_items)
		"tema":
			var explicacion: Variant = nodo.get("explicacion")
			if explicacion is String:
				parrafos.append(explicacion)
			if not nodo.get("fuente", "").is_empty():
				parrafos.append("Fuente: %s" % nodo.fuente)
		"orden":
			parrafos.append(DIFICULTADES.get(nodo.get("dificultad"), ""))
			parrafos.append(nodo.get("competencia", ""))
			parrafos.append(nodo.get("marca", ""))
			var competencia: String = nodo.get("competencia", "")
			var id: Variant = Banco.COMPETENCIAS.find_key(competencia)
			datos.acciones.append({"texto": "Practicar", "archivo": nodo.get("archivo", ""),
				"competencia": competencia if id == null else id})
	datos.parrafos = parrafos.filter(func(parrafo: String) -> bool: return not parrafo.strip_edges().is_empty())
	return datos


static func preguntas_falladas(competencia: String, error: String, historial: Array, banco_items: Array) -> Array:
	var por_id := {}
	for item in banco_items:
		por_id[item.id] = item
	var preguntas := []
	var json := JSON.new()
	for intento in historial:
		if intento.get("competencia") != competencia or tipo_error(intento) != error:
			continue
		var item: Dictionary = por_id.get(intento.get("item"), {})
		var guardada: Variant = intento.get("respuesta")
		var recibida: Variant = json.data if guardada is String and json.parse(guardada) == OK else guardada
		var pregunta := {}
		match item.get("formato"):
			"opcion-multiple":
				pregunta = {"enunciado": item.pregunta, "correcta": item.opciones[int(item.correcta)]}
				if (recibida is int or recibida is float) and recibida >= 0 \
						and recibida < item.opciones.size() and floor(recibida) == recibida:
					pregunta.respuesta = item.opciones[int(recibida)]
			"caso-diagnostico":
				pregunta.enunciado = "%s\n%s" % [item.codigo_falla, "\n".join(item.sintomas)]
				var pasos := {}
				for paso in item.pasos:
					pasos[paso.id] = paso.accion
				pregunta.correcta = secuencia(item.ruta_ideal, pasos)
				if recibida is Array:
					pregunta.respuesta = secuencia(recibida, pasos)
			"accion-panel":
				pregunta = {"enunciado": item.instruccion, "correcta": acciones_panel(item.secuencia_esperada)}
				if recibida is Array:
					pregunta.respuesta = acciones_panel(recibida)
		if not pregunta.has("respuesta") and recibida is String:
			pregunta.respuesta = recibida
		for campo in pregunta.keys():
			pregunta[campo] = TextoLimpio.linea(pregunta[campo])
			if pregunta[campo].is_empty():
				pregunta.erase(campo)
		if not pregunta.is_empty():
			preguntas.append(pregunta)
	return preguntas


static func secuencia(ids: Array, pasos: Dictionary) -> String:
	var acciones := PackedStringArray()
	for id in ids:
		if pasos.has(id):
			acciones.append(pasos[id])
	return " → ".join(acciones)


static func acciones_panel(eventos: Array) -> String:
	var acciones := PackedStringArray()
	for evento in eventos:
		if not evento is Dictionary:
			continue
		match evento.get("ctrl", evento.get("accion", "")):
			"bloqueo":
				acciones.append("Activar bloqueo" if evento.valor == 1 else "Desactivar bloqueo")
			"etiquetado":
				acciones.append("Activar etiquetado" if evento.valor == 1 else "Desactivar etiquetado")
			"torque":
				acciones.append("Ajustar torque a %s" % evento.valor)
			"confirmar":
				acciones.append("Confirmar")
			"cancelar":
				acciones.append("Cancelar")
	return " → ".join(acciones)
