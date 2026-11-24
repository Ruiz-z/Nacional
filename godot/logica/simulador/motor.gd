extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const ENTRADAS := ["panel", "virtual", "teclado", "control"]

# Estas cifras son reglas del juego, independientes de los valores del escenario.
const PENALIZACIONES := {"paso-innecesario": 4, "orden-incorrecto": 8,
	"valor-fuera-de-rango": 10, "causa-equivocada": 12, "paso-omitido": 12,
	"accion-insegura": 30}

var enviar_brecha: Callable

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


func _init(escenario: Dictionary) -> void:
	_escenario = escenario.duplicate(true)
	_estado = _escenario.estado.duplicate()
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


func ejecutar(id: String, fuente_entrada: String, tiempo_ms: int, controles: Dictionary = {}) -> Dictionary:
	if not _fin.is_empty():
		return rechazo("El escenario ya terminó.")
	if fuente_entrada not in ENTRADAS or tiempo_ms < 0:
		return rechazo("La fuente de entrada o el tiempo no es válido.")
	var recuperacion: bool = _escenario.recuperaciones.has(id)
	var reglas: Dictionary = recuperaciones_disponibles() if recuperacion else _escenario.acciones
	var regla: Dictionary = reglas.get(id, {})
	if regla.is_empty():
		return rechazo("La acción no está disponible.")
	var decision := {"accion": id, "estado_antes": estado(), "fuente_entrada": fuente_entrada,
		"tiempo_ms": tiempo_ms, "competencia": regla.competencia, "fuente": regla.fuente,
		"criticidad": regla.criticidad, "tipo_error": regla.tipo_error, "aplicada": false,
		"motivo": "", "recuperacion": recuperacion, "eventos": []}
	for campo in regla.previas:
		if _estado[campo] != regla.previas[campo]:
			decision.motivo = "Se requiere %s = %s." % [campo, regla.previas[campo]]
			break
	var seguridad: String = regla.get("seguridad_panel", "")
	if not seguridad.is_empty() and not (controles.get("bloqueo", false) == true
			and controles.get("etiquetado", false) == true):
		decision.motivo = regla.explicacion_seguridad
		if seguridad == "critica":
			decision.criticidad = "critica"
			decision.tipo_error = "accion-insegura"
	if decision.criticidad == "critica":
		_fin = "falta-critica"
		_puntaje = 0
		if seguridad != "critica":
			decision.motivo = regla.descripcion
	elif decision.motivo.is_empty():
		var cambio := activar_eventos(_estado, _estado.merged(regla.efectos, true))
		if cambio.is_empty():
			decision.motivo = "La acción produciría un estado imposible."
		else:
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
	var nuevo := get_script().new(variante) as RefCounted
	if not nuevo.fin().is_empty() or nuevo.hay_problemas():
		return null
	var ultimo_estado_seguro: Dictionary = nuevo.estado()
	var acciones_seguras := 0
	for decision in _progreso_previo + _decisiones.slice(0, _punto_seguro):
		if not decision.aplicada:
			continue
		var reglas: Dictionary = variante.acciones if not decision.recuperacion else variante.recuperaciones
		if reglas[decision.accion].has("seguridad_panel"):
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


func registrar_reflexion(eleccion: String) -> bool:
	var texto := eleccion.strip_edges()
	if _fin.is_empty() or texto.is_empty() or not _reflexion.is_empty():
		return false
	_reflexion = texto
	return true


func resumen() -> Dictionary:
	if _fin.is_empty():
		return {}
	var resultado := {"fin": _fin, "linea_tiempo": _decisiones.duplicate(true),
		"aciertos": _decisiones.filter(es_acierto).duplicate(true),
		"errores": _decisiones.filter(es_error).duplicate(true),
		"brechas": brechas(), "pregunta": "¿Qué harías distinto?", "reflexion": _reflexion,
		"comparacion": {"anterior": _intento_anterior.duplicate(), "actual": metricas()}}
	if not _reflexion.is_empty():
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
			intento.tipo_error = decision.tipo_error
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
	return {"escenario": _escenario.id, "version_contenido": _escenario.version, "fin": _fin,
		"puntaje": _puntaje, "por_competencia": por_competencia, "intentos": intentos,
		"eventos": eventos, "errores": eventos.filter(es_error), "faltas": faltas(),
		"brechas": brechas_registradas}


func intento_de(competencia: String, respuesta: String, reloj_sim: String) -> Dictionary:
	return {"competencia": competencia, "item": _escenario.id, "formato": "escenario",
		"dificultad": _escenario.dificultad, "respuesta": respuesta, "valor": 100,
		"resultado": "correcto", "tipo_error": null, "tiempo_ms": 0, "fuente_entrada": "",
		"momento": "practica", "reloj_sim": reloj_sim, "version_contenido": _escenario.version}
