extends RefCounted

const ACCIONES := ["mover", "mirar", "inspeccionar", "elegir-accion",
	"bloqueo", "etiquetado", "torque", "confirmar", "cancelar"]

var _mapeo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/entrada.json"))
var _registro: Array[Dictionary] = []
var _estado := {"bloqueo": 0, "etiquetado": 0, "torque": 0}


func traducir(fuente: String, control: String, valor: Variant) -> Dictionary:
	var acciones := procesar_lote([{"fuente_entrada": fuente, "ctrl": control, "valor": valor}])
	return {} if acciones.is_empty() else acciones[0]


func procesar_lote(eventos: Array) -> Array[Dictionary]:
	var candidatos: Array[Dictionary] = []
	var ultimas_fuentes := {}
	for evento in eventos:
		var asignacion := buscar_asignacion(evento.fuente_entrada, evento.ctrl)
		if asignacion.is_empty():
			continue
		var accion: String = asignacion[0]
		_registro.append(evento.duplicate(true))
		if accion in ["confirmar", "cancelar"] and evento.valor == 0:
			continue
		ultimas_fuentes[accion] = evento.fuente_entrada
		candidatos.append({"asignacion": asignacion, "evento": evento})

	var acciones: Array[Dictionary] = []
	for candidato in candidatos:
		var asignacion: Array = candidato.asignacion
		var evento: Dictionary = candidato.evento
		if evento.fuente_entrada == ultimas_fuentes[asignacion[0]]:
			acciones.append(aplicar(asignacion, evento.fuente_entrada, evento.valor))
	return acciones


func registro() -> Array[Dictionary]:
	return _registro.duplicate(true)


func aplicar(asignacion: Array, fuente: String, valor: Variant) -> Dictionary:
	var accion: String = asignacion[0]
	var es_panel := fuente in ["panel", "virtual"]
	if asignacion.size() > 1:
		valor = asignacion[1]
	if accion == "torque" and not es_panel:
		valor = clampf(_estado.torque + valor, 0, 100)
	elif accion in ["bloqueo", "etiquetado"] and not es_panel:
		valor = 1 - _estado[accion]
	if _estado.has(accion):
		_estado[accion] = valor
	return {"accion": accion, "valor": valor, "fuente_entrada": fuente}


func buscar_asignacion(fuente: String, control: String) -> Array:
	var grupo: Dictionary = _mapeo.get("panel" if fuente == "virtual" else fuente, {})
	var asignacion: Array = grupo.get(control, [])
	if asignacion.is_empty() or asignacion[0] not in ACCIONES:
		return []
	return asignacion
