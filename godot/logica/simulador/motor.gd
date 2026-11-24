extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const EvaluacionPanel = preload("res://logica/entrada/evaluacion_panel.gd")
const FUENTE_ELEVADOR := "[MUESTRA] procedimiento didáctico, sin fuente oficial"
const ENTRADAS := ["panel", "virtual", "teclado", "control", "banco"]

# Estas cifras son reglas del juego, independientes de los valores del escenario.
const PENALIZACIONES := {"paso-innecesario": 4, "herramienta-equivocada": 4, "orden-incorrecto": 8,
	"valor-fuera-de-rango": 10, "causa-equivocada": 12, "paso-omitido": 12,
	"punto-de-medicion-incorrecto": 8, "lectura-mal-interpretada": 12, "accion-insegura": 30}

var enviar_brecha: Callable
var mediciones: Mediciones

var _causa_marcada := ""
var _brechas: Array = []
var _creditos_recuperacion := {}
var _escenario: Dictionary
var _estado: Dictionary
var _decisiones: Array = []
var _fin := ""
var _puntaje := 100
var _faltas: Array = []
var _punto_seguro := 0
var _progreso_previo: Array = []
var _intento_anterior := {}
var _reflexion := ""
var _reflexion_omitida := false
var _diagnostico_final := {}
var _causa_banco := ""


func _init(escenario: Dictionary, lector_banco: Callable = Mediciones.leer_variante,
		fuente_banco := "virtual") -> void:
	_escenario = escenario.duplicate(true)
	_estado = _escenario.estado.duplicate()
	if _escenario.get("zona") == "banco":
		mediciones = Mediciones.new(lector_banco, fuente_banco)
	var inicio := activar_eventos({}, _estado)
	if inicio.is_empty():
		_fin = "estado-invalido"
		return
	_estado = inicio.estado
	actualizar_fin()


func estado() -> Dictionary:
	return _estado.duplicate()


func fin() -> String:
	return _fin


func puntaje() -> int:
	return _puntaje


func faltas() -> Array:
	return _faltas.duplicate(true)


static func seguridad_confirmada(controles: Dictionary) -> bool:
	return controles.get("bloqueo", false) == true and controles.get("etiquetado", false) == true


func acciones_acertadas() -> Array[String]:
	var acciones: Array[String] = []
	for decision in _progreso_previo + _decisiones:
		if es_acierto(decision) and decision.accion not in acciones:
			acciones.append(decision.accion)
	return acciones


func ejecutar(id: String, fuente_entrada: String, tiempo_ms: int, controles: Dictionary = {},
		lectura_previa: Dictionary = {}) -> Dictionary:
	if not _fin.is_empty():
		return rechazo("La práctica ya terminó. Abre otra orden o vuelve a intentarla.")
	if fuente_entrada not in ENTRADAS or tiempo_ms < 0:
		return rechazo("No se recibió el paso. Intenta de nuevo.")
	var recuperacion: bool = _escenario.recuperaciones.has(id)
	var reglas: Dictionary = recuperaciones_disponibles() if recuperacion else _escenario.acciones
	var regla: Dictionary = reglas.get(id, {})
	if regla.is_empty():
		return rechazo("Ese paso aún no está disponible. Revisa la ayuda de la orden.")
	if fuente_entrada == "banco" and (mediciones == null or id != "reconectar"
			or mediciones.fuente != "banco" or lectura_previa.is_empty()):
		return rechazo("No se pudo comprobar la reparación. Revisa la conexión del banco.")
	if mediciones != null and regla.get("requiere_panel", false):
		if mediciones.fuente == "banco" and fuente_entrada != "banco":
			return rechazo("Cierra el conductor abierto en el banco físico.")
		if fuente_entrada not in ["panel", "virtual", "banco"]:
			return rechazo("Confirma la reparación en el panel.")
	var bajos: bool = _escenario.get("zona") == "bajos"
	var bajo_autobus: bool = bajos and regla.componente != "consola_elevador"
	var falta_elevador: bool = bajo_autobus and not controles.get("elevador_seguro", false)
	if bajos and regla.get("requiere_panel", false) and not falta_elevador \
			and fuente_entrada not in ["panel", "virtual"]:
		return rechazo("Confirma la reparación en el panel.")
	if regla.has("torque") and not falta_elevador and not Escenario.numero(controles.get("torque")):
		return rechazo("Ajusta la perilla del panel para registrar el torque.")
	var decision := {"accion": id, "estado_antes": estado(), "fuente_entrada": fuente_entrada,
		"tiempo_ms": tiempo_ms, "competencia": regla.competencia, "fuente": regla.fuente,
		"criticidad": regla.criticidad, "tipo_error": regla.tipo_error, "aplicada": false,
		"motivo": "", "recuperacion": recuperacion, "eventos": []}
	var faltantes := {}
	for campo in regla.previas:
		if _estado[campo] != regla.previas[campo]:
			faltantes[campo] = regla.previas[campo]
	if not faltantes.is_empty():
		decision.motivo = "Intentaste hacer este paso antes de tiempo. Revisa el siguiente paso de la orden."
	var seguridad: String = regla.get("seguridad_panel", "")
	if not seguridad.is_empty() and not seguridad_confirmada(controles):
		faltantes.clear()
		decision.motivo = regla.explicacion_seguridad
		if seguridad == "critica":
			decision.criticidad = "critica"
			decision.tipo_error = "accion-insegura"
	if falta_elevador:
		decision.criticidad = "critica"
		decision.tipo_error = "accion-insegura"
		decision.fuente = FUENTE_ELEVADOR
		decision.motivo = "Intentaste trabajar en los bajos sin trabar ambos soportes. Trábalos antes de volver a trabajar ahí. " + FUENTE_ELEVADOR
	if decision.criticidad == "critica":
		_fin = "falta-critica"
		_puntaje = 0
		if seguridad != "critica" and not falta_elevador:
			decision.motivo = regla.descripcion
	elif not faltantes.is_empty():
		decision.previas_faltantes = faltantes
		if bajos and id == "cerrar_orden":
			decision.tipo_error = "paso-omitido"
	elif decision.motivo.is_empty():
		var efectos: Dictionary = regla.efectos
		if regla.has("torque"):
			var valor: float = controles.torque
			var rango: Dictionary = regla.torque
			var error := EvaluacionPanel.evaluar_torque(valor, rango.minimo, rango.maximo)
			decision["torque_simulado"] = valor
			if not error.is_empty():
				decision.tipo_error = error.tipo_error
				decision.criticidad = "leve"
				decision.motivo = "[MUESTRA] El apriete quedó fuera de rango. Ajusta la perilla al rango del panel."
				efectos = rango.efectos_fuera
		var cambio := activar_eventos(_estado, _estado.merged(efectos, true))
		if cambio.is_empty():
			decision.motivo = "No puedes hacer ese paso así. Revisa el orden de los pasos y vuelve a intentarlo."
		else:
			if mediciones != null:
				if id == "reconectar" and not lectura_previa.is_empty():
					_causa_banco = Mediciones.causa_de_lectura(lectura_previa)
				decision.merge(mediciones.aplicar(id, _estado, regla.causa, lectura_previa), true)
				decision["fuente_falla"] = mediciones.fuente
				if decision.motivo.is_empty():
					decision.motivo = Mediciones.MOTIVOS.get(decision.tipo_error, "")
			_estado = cambio.estado
			decision.eventos = cambio.eventos
			decision.aplicada = true
	if regla.criticidad == "leve" and decision.aplicada:
		decision.motivo = regla.descripcion
	elif not decision.aplicada and decision.criticidad != "critica" and decision.tipo_error.is_empty():
		decision.tipo_error = "orden-incorrecto"
	decision.estado_despues = estado()
	if decision.criticidad != "critica":
		puntuar(decision)
	_decisiones.append(decision)
	if _fin == "falta-critica":
		_faltas.append(decision)
	else:
		actualizar_fin()
		if decision.aplicada and _fin.is_empty() and not hay_problemas():
			_punto_seguro = _decisiones.size()
	registrar_brecha(decision, regla.causa)
	return decision.duplicate(true)


func registrar_herramienta_equivocada(id: String, fuente_entrada: String, tiempo_ms: int, motivo: String) -> Dictionary:
	var regla: Dictionary = _escenario.acciones.get(id, _escenario.recuperaciones.get(id, {}))
	var competencia: String = _escenario.acciones[_escenario.ruta_ideal[0]].competencia
	var decision := {"accion": id, "estado_antes": estado(), "estado_despues": estado(),
		"fuente_entrada": fuente_entrada, "tiempo_ms": tiempo_ms,
		"competencia": regla.get("competencia", competencia), "fuente": regla.get("fuente", _escenario.fuente),
		"criticidad": "leve", "tipo_error": "herramienta-equivocada", "aplicada": false,
		"motivo": motivo, "recuperacion": _escenario.recuperaciones.has(id), "eventos": []}
	puntuar(decision)
	_decisiones.append(decision)
	actualizar_fin()
	return decision.duplicate(true)


func actualizar_fin() -> void:
	if Escenario.cumple(_estado, _escenario.terminacion.resuelto):
		_fin = "resuelto"
	elif _decisiones.size() >= int(_escenario.terminacion.limite_intentos):
		_fin = "limite-intentos"


static func rechazo(motivo: String) -> Dictionary:
	return {"aplicada": false, "motivo": motivo}


func recuperaciones_disponibles() -> Dictionary:
	var opciones := {}
	if not _fin.is_empty():
		return opciones
	for evento in _escenario.eventos.values():
		if Escenario.cumple(_estado, evento.condicion):
			for id in evento.recuperaciones:
				var regla: Dictionary = _escenario.recuperaciones[id]
				if Escenario.cumple(_estado, regla.previas):
					opciones[id] = regla.duplicate(true)
	return opciones


func activar_eventos(antes: Dictionary, despues: Dictionary) -> Dictionary:
	var activados := []
	var pendientes := []
	agregar_eventos(antes, despues, pendientes)
	while true:
		if Escenario.imposible(despues, _escenario.estados_imposibles):
			return {}
		if pendientes.is_empty():
			return {"estado": despues, "eventos": activados}
		var id: String = pendientes.pop_front()
		var evento: Dictionary = _escenario.eventos[id]
		if not Escenario.cumple(despues, evento.condicion):
			continue
		if id in activados:
			return {}
		activados.append(id)
		var siguiente := despues.merged(evento.efectos, true)
		agregar_eventos(despues, siguiente, pendientes)
		despues = siguiente
	return {}


func agregar_eventos(antes: Dictionary, despues: Dictionary, pendientes: Array) -> void:
	for id in _escenario.eventos:
		var condicion: Dictionary = _escenario.eventos[id].condicion
		if id not in pendientes and not Escenario.cumple(antes, condicion) \
				and Escenario.cumple(despues, condicion):
			pendientes.append(id)


func puntuar(decision: Dictionary) -> void:
	var descuento: int = PENALIZACIONES.get(decision.tipo_error, 0)
	decision["ajuste_puntos"] = -descuento
	_puntaje = maxi(0, _puntaje - descuento)
	if not decision.aplicada:
		return
	for id in _creditos_recuperacion.keys():
		var evento: Dictionary = _escenario.eventos[id]
		if not Escenario.cumple(_estado, evento.condicion):
			if decision.accion in evento.recuperaciones and descuento == 0:
				_puntaje = mini(100, _puntaje + _creditos_recuperacion[id])
				decision.ajuste_puntos += _creditos_recuperacion[id]
			_creditos_recuperacion.erase(id)
	# Se comparte el crédito entre los problemas que abre una misma decisión.
	if descuento > 0 and not decision.eventos.is_empty():
		var credito := floori(descuento / (2.0 * decision.eventos.size()))
		for id in decision.eventos:
			if Escenario.cumple(_estado, _escenario.eventos[id].condicion):
				_creditos_recuperacion[id] = credito


func marcar_causa(causa: String) -> bool:
	if not _fin.is_empty() or (not causa.is_empty() and causa not in _escenario.causas):
		return false
	_causa_marcada = causa
	return true


func brechas() -> Array:
	return _brechas.duplicate(true)


func registrar_brecha(decision: Dictionary, causa_de_accion: String) -> void:
	if not decision.aplicada or _causa_marcada.is_empty() or causa_de_accion.is_empty() \
			or _causa_marcada == causa_de_accion or decision.fuente_entrada not in ["panel", "virtual"]:
		return
	var brecha := {"tipo_error": "diagnostico-vs-accion", "caso": _escenario.id,
		"competencia": decision.competencia, "causa_marcada": _causa_marcada,
		"accion_ejecutada": decision.accion, "fuente_entrada": decision.fuente_entrada,
		"tiempo_ms": decision.tiempo_ms}
	_brechas.append(brecha)
	if enviar_brecha.is_valid():
		enviar_brecha.call(brecha.duplicate(true))


func hay_problemas() -> bool:
	for evento in _escenario.eventos.values():
		if not evento.recuperaciones.is_empty() and Escenario.cumple(_estado, evento.condicion):
			return true
	return false


func reintentar() -> RefCounted:
	if _fin.is_empty():
		return null
	var variante := _escenario.duplicate(true)
	variante.estado.merge(variante.variante.estado, true)
	if mediciones != null:
		variante.variante.estado = _escenario.estado.duplicate()
		variante.ruta_ideal = _escenario.variante.get("ruta_ideal", _escenario.ruta_ideal)
		variante.variante.ruta_ideal = _escenario.ruta_ideal
		var nuevo_banco := get_script().new(variante, mediciones.leer, mediciones.fuente) as RefCounted
		nuevo_banco._intento_anterior = metricas()
		nuevo_banco.enviar_brecha = enviar_brecha
		return nuevo_banco
	var nuevo := get_script().new(variante) as RefCounted
	if not nuevo.fin().is_empty() or nuevo.hay_problemas():
		return null
	var ultimo_estado_seguro: Dictionary = nuevo.estado()
	var acciones_seguras := 0
	for decision in _progreso_previo + _decisiones.slice(0, _punto_seguro):
		if not decision.aplicada:
			continue
		var reglas: Dictionary = variante.acciones if not decision.recuperacion else variante.recuperaciones
		if variante.zona == "bajos" or reglas[decision.accion].has("seguridad_panel"):
			break
		var repetida: Dictionary = nuevo.ejecutar(decision.accion, decision.fuente_entrada, 0)
		if not repetida.aplicada or not nuevo.fin().is_empty():
			break
		if not nuevo.hay_problemas():
			ultimo_estado_seguro = nuevo.estado()
			acciones_seguras = nuevo._decisiones.size()
	nuevo._progreso_previo = nuevo._decisiones.slice(0, acciones_seguras)
	nuevo._intento_anterior = metricas()
	nuevo._estado = ultimo_estado_seguro
	nuevo._fin = ""
	nuevo._decisiones.clear()
	nuevo._creditos_recuperacion.clear()
	nuevo._puntaje = 100
	nuevo._punto_seguro = 0
	nuevo.enviar_brecha = enviar_brecha
	return nuevo


func registrar_reflexion(eleccion: String, omitir := false) -> bool:
	var texto := eleccion.strip_edges()
	if _fin.is_empty() or (texto.is_empty() and not omitir) or _reflexion_omitida or not _reflexion.is_empty():
		return false
	_reflexion = "" if omitir else texto
	_reflexion_omitida = omitir
	return true


func pendiente_diagnostico() -> bool:
	return _fin == "resuelto" and _escenario.has("causa_correcta") and _diagnostico_final.is_empty()


func registrar_diagnostico(causa: String, fuente_entrada: String, tiempo_ms: int) -> Dictionary:
	if not pendiente_diagnostico() or causa not in _escenario.causas 			or fuente_entrada not in ENTRADAS or tiempo_ms < 0:
		return {}
	var real: String = _escenario.causa_correcta
	if mediciones != null and not _causa_banco.is_empty():
		real = _causa_banco
	elif mediciones != null:
		for id in _escenario.ruta_ideal:
			if id.begins_with("diagnosticar_"):
				real = _escenario.acciones[id].causa
				break
	_diagnostico_final = {"elegida": causa, "real": real, "correcto": causa == real,
		"explicacion": _escenario.explicacion_causa[real], "fuente": _escenario.fuente,
		"fuente_entrada": fuente_entrada, "tiempo_ms": tiempo_ms}
	return _diagnostico_final.duplicate()


func resumen() -> Dictionary:
	if _fin.is_empty():
		return {}
	var resultado := {"fin": _fin, "linea_tiempo": _decisiones.duplicate(true),
		"aciertos": _decisiones.filter(es_acierto).duplicate(true),
		"errores": _decisiones.filter(es_error).duplicate(true),
		"brechas": brechas(), "diagnostico_final": _diagnostico_final.duplicate(), "pregunta": "¿Qué harías distinto?", "reflexion": _reflexion,
		"reflexion_omitida": _reflexion_omitida,
		"comparacion": {"anterior": _intento_anterior.duplicate(), "actual": metricas()}}
	if mediciones != null:
		resultado["errores_arnes"] = Mediciones.contar_errores(resultado.errores)
	if _reflexion_omitida or not _reflexion.is_empty():
		resultado["ruta_ideal"] = []
		for id in _escenario.ruta_ideal:
			var regla: Dictionary = _escenario.acciones[id]
			resultado.ruta_ideal.append({"accion": id, "fuente": regla.fuente,
				"descripcion": regla.descripcion})
	return resultado


func metricas() -> Dictionary:
	var tiempo_ms := 0
	for decision in _decisiones:
		tiempo_ms += int(decision.tiempo_ms)
	return {"errores": _decisiones.filter(es_error).size(), "tiempo_ms": tiempo_ms,
		"puntaje": _puntaje}


static func es_acierto(decision: Dictionary) -> bool:
	return decision.aplicada and decision.tipo_error.is_empty()


static func es_error(decision: Dictionary) -> bool:
	return not es_acierto(decision)


# Los intentos tienen el formato de aprendizaje y los eventos conservan los estados para el tablero.
func resultados(reloj_sim: String) -> Dictionary:
	if _fin.is_empty():
		return {}
	var intentos := []
	var por_competencia := {}
	var eventos := []
	for decision in _decisiones:
		var evento: Dictionary = decision.duplicate(true)
		evento["escenario"] = _escenario.id
		evento["reloj_sim"] = reloj_sim
		eventos.append(evento)
		var intento: Dictionary = por_competencia.get(decision.competencia, {})
		if intento.is_empty():
			intento = intento_de(decision.competencia, decision.accion, reloj_sim)
			por_competencia[decision.competencia] = intento
		intento.tiempo_ms += decision.tiempo_ms
		intento.respuesta = decision.accion
		intento.fuente_entrada = decision.fuente_entrada
		intento.valor = clampi(intento.valor + decision.get("ajuste_puntos", 0), 0, 100)
		if es_error(decision):
			intento.resultado = "incorrecto"
			if mediciones == null and decision.tipo_error != "herramienta-equivocada":
				intento.tipo_error = decision.tipo_error
			if mediciones != null or decision.tipo_error == "herramienta-equivocada":
				var detalle := intento_de(decision.competencia, decision.accion, reloj_sim)
				detalle.merge({"formato": "detalle-escenario", "resultado": "incorrecto",
					"valor": 0, "tipo_error": decision.tipo_error, "tiempo_ms": decision.tiempo_ms,
					"fuente_entrada": decision.fuente_entrada}, true)
				intentos.append(detalle)
		if decision.criticidad == "critica":
			intento.tipo_error = "falta-critica"
			intento.valor = 0
	intentos.append_array(por_competencia.values())
	var brechas_registradas := brechas()
	for brecha in brechas_registradas:
		brecha["reloj_sim"] = reloj_sim
		var intento := intento_de(brecha.competencia, brecha.accion_ejecutada, reloj_sim)
		intento.merge({"valor": 0, "resultado": "incorrecto", "tipo_error": brecha.tipo_error,
			"tiempo_ms": brecha.tiempo_ms, "fuente_entrada": brecha.fuente_entrada}, true)
		intentos.append(intento)
	if not _diagnostico_final.is_empty():
		var cierre := _diagnostico_final
		var competencia: String = _escenario.acciones[_escenario.ruta_ideal[0]].competencia
		var intento := intento_de(competencia, cierre.elegida, reloj_sim)
		var tipo_error := "" if cierre.correcto else "causa-equivocada"
		# El resultado de la práctica ya aporta al dominio por competencia.
		intento.merge({"formato": "detalle-escenario", "valor": 100 if cierre.correcto else 0,
			"resultado": "correcto" if cierre.correcto else "incorrecto",
			"tipo_error": null if cierre.correcto else tipo_error,
			"tiempo_ms": cierre.tiempo_ms, "fuente_entrada": cierre.fuente_entrada}, true)
		intentos.append(intento)
		eventos.append({"accion": "diagnostico_final", "escenario": _escenario.id, "reloj_sim": reloj_sim,
			"estado_antes": estado(), "estado_despues": estado(), "causa_elegida": cierre.elegida,
			"fuente_entrada": cierre.fuente_entrada, "tiempo_ms": cierre.tiempo_ms, "fuente": cierre.fuente,
			"criticidad": "normal" if cierre.correcto else "leve", "tipo_error": tipo_error, "aplicada": true})
	return {"escenario": _escenario.id, "version_contenido": _escenario.version, "fin": _fin,
		"puntaje": _puntaje, "por_competencia": por_competencia, "intentos": intentos,
		"eventos": eventos, "errores": eventos.filter(es_error), "faltas": faltas(),
		"brechas": brechas_registradas}


func intento_de(competencia: String, respuesta: String, reloj_sim: String) -> Dictionary:
	return {"competencia": competencia, "item": _escenario.id, "formato": "escenario",
		"dificultad": _escenario.dificultad, "respuesta": respuesta, "valor": 100,
		"resultado": "correcto", "tipo_error": null, "tiempo_ms": 0, "fuente_entrada": "",
		"momento": "practica", "reloj_sim": reloj_sim, "version_contenido": _escenario.version}
