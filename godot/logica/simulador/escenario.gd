extends RefCounted

const Inventario = preload("res://logica/simulador/inventario.gd")

const RutasContenido = preload("res://logica/rutas_contenido.gd")

const COMPONENTES := ["compuerta", "monitor", "cables", "terminal", "bateria",
	"caja_fusibles", "fusible_faros", "conector_faros", "faro_izquierdo", "faro_derecho", "rele_faros",
	"tapa_motor", "motor_traccion", "inversor_motor", "bomba_motor", "radiador_motor",
	"monitor_temperatura", "abrazadera_motor", "fusibles_cabina", "multimetro", "tp0", "tp1", "tp2"]
const ZONAS := ["gabinete", "faros", "motor", "cabina", "banco"]
const FUENTE_BZR := "Volvo Buses, BZR Low Entry Eléctrico (página pública)"
const AISLAMIENTO := "escenarios/aislamiento.json"
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")
const Banco = preload("res://logica/competencias/banco.gd")


static func cargar(ruta: String) -> Dictionary:
	ruta = RutasContenido.resolver(ruta)
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return error(ruta, "archivo", "No se pudo abrir.")
	var json := JSON.new()
	if json.parse(archivo.get_as_text()) != OK:
		return error(ruta, "JSON", "Línea %d: %s" % [json.get_error_line() + 1, json.get_error_message()])
	return validar(json.data, ruta)


static func validar(datos: Variant, ruta: String) -> Dictionary:
	if not datos is Dictionary:
		return error(ruta, "raíz", "Se esperaba un objeto.")
	var campo := campo_invalido(datos)
	if not campo.is_empty():
		return error(ruta, campo, "Falta el campo o su valor no es válido.")
	if ciclo_eventos(datos.eventos):
		return error(ruta, "eventos", "Las transiciones entre eventos contienen un ciclo.")
	return {"escenario": datos.duplicate(true), "errores": []}


static func campo_invalido(datos: Dictionary) -> String:
	for campo in ["id", "titulo", "descripcion", "version", "fuente"]:
		if not Banco.texto_presente(datos.get(campo)):
			return campo
	if not datos.get("muestra") is bool or (datos.muestra and not datos.titulo.begins_with("[MUESTRA]")):
		return "muestra"
	if not fuente_valida(datos.fuente, datos.muestra):
		return "fuente"
	if datos.get("zona") not in ZONAS:
		return "zona"
	if datos.get("dificultad") not in Banco.DIFICULTADES:
		return "dificultad"
	for campo in ["estado", "acciones", "eventos", "recuperaciones", "terminacion", "variante"]:
		if not datos.get(campo) is Dictionary:
			return campo
	if datos.estado.is_empty():
		return "estado"
	for variable in datos.estado:
		if not Banco.texto_presente(variable) or not valor_simple(datos.estado[variable]):
			return "estado.%s" % variable
	if datos.has("indicios") and not indicios_validos(datos):
		return "indicios"
	if not datos.get("estados_imposibles") is Array:
		return "estados_imposibles"
	for condicion in datos.estados_imposibles:
		if not asignacion_valida(condicion, datos.estado) or condicion.is_empty():
			return "estados_imposibles"
	if imposible(datos.estado, datos.estados_imposibles):
		return "estado"
	if not datos.get("causas") is Array or datos.causas.is_empty():
		return "causas"
	for causa in datos.causas:
		if not Banco.texto_presente(causa) or datos.causas.count(causa) != 1:
			return "causas"
	if datos.acciones.is_empty():
		return "acciones"
	for grupo in ["acciones", "recuperaciones", "eventos"]:
		for id in datos[grupo]:
			var campo := validar_regla(datos[grupo][id], grupo, datos)
			if not Banco.texto_presente(id) or not campo.is_empty():
				return "%s.%s%s" % [grupo, id, campo]
	for id in datos.recuperaciones:
		if datos.acciones.has(id):
			return "recuperaciones.%s" % id
	var resuelto: Variant = datos.terminacion.get("resuelto")
	if not asignacion_valida(resuelto, datos.estado) or resuelto.is_empty() \
			or imposible(resuelto, datos.estados_imposibles):
		return "terminacion.resuelto"
	var limite: Variant = datos.terminacion.get("limite_intentos")
	if not numero(limite) or limite < 1 or limite > 2147483647 or limite != floor(limite):
		return "terminacion.limite_intentos"
	if not ruta_valida(datos.get("ruta_ideal"), datos.acciones):
		return "ruta_ideal"
	if datos.variante.has("ruta_ideal") and not ruta_valida(datos.variante.ruta_ideal, datos.acciones):
		return "variante.ruta_ideal"
	var cambio: Variant = datos.variante.get("estado")
	if not asignacion_valida(cambio, datos.estado) or cambio.is_empty() \
			or cumple(datos.estado, cambio) \
			or imposible(datos.estado.merged(cambio, true), datos.estados_imposibles):
		return "variante.estado"
	if datos.zona == "banco":
		for campo in ["s1_abierto", "s2_abierto", "resuelto"]:
			if not datos.estado.get(campo) is bool:
				return "estado." + campo
	return ""


static func indicios_validos(datos: Dictionary) -> bool:
	if not datos.indicios is Array:
		return false
	var claves := {}
	for indicio in datos.indicios:
		if not indicio is Dictionary or not Banco.texto_presente(indicio.get("clave")) \
				or not Banco.texto_presente(indicio.get("etiqueta")):
			return false
		if indicio.has("ayuda") and not Banco.texto_presente(indicio.ayuda):
			return false
		var clave: String = indicio.clave
		if claves.has(clave) or not (datos.estado.get(clave) is bool \
				or (datos.zona == "banco" and clave in Mediciones.INDICIOS)):
			return false
		claves[clave] = true
	return true


static func ruta_valida(ruta: Variant, acciones: Dictionary) -> bool:
	if not ruta is Array or ruta.is_empty():
		return false
	for id in ruta:
		if not acciones.has(id) or acciones[id].criticidad != "normal":
			return false
	return true


static func validar_regla(regla: Variant, grupo: String, datos: Dictionary) -> String:
	if not regla is Dictionary:
		return ".regla"
	if not fuente_valida(regla.get("fuente"), datos.muestra):
		return ".fuente"
	if not Banco.texto_presente(regla.get("descripcion")):
		return ".descripcion"
	var previa := "condicion" if grupo == "eventos" else "previas"
	if not asignacion_valida(regla.get(previa), datos.estado) \
			or imposible(regla[previa], datos.estados_imposibles):
		return "." + previa
	if not asignacion_valida(regla.get("efectos"), datos.estado) \
			or imposible(regla[previa].merged(regla.efectos, true), datos.estados_imposibles):
		return ".efectos"
	if grupo == "eventos":
		if regla.condicion.is_empty():
			return ".condicion"
		if not regla.get("recuperaciones") is Array:
			return ".recuperaciones"
		for id in regla.recuperaciones:
			if not datos.recuperaciones.has(id) or regla.recuperaciones.count(id) != 1:
				return ".recuperaciones"
		return ""
	if regla.has("requiere") and not Inventario.requisitos_validos(regla.requiere):
		return ".requiere"
	if regla.has("titulo") and not Banco.texto_presente(regla.titulo):
		return ".titulo"
	if not regla.get("requiere_panel", false) is bool:
		return ".requiere_panel"
	if regla.has("seguridad_panel"):
		if regla.seguridad_panel not in ["previa", "critica"] or regla.criticidad == "critica":
			return ".seguridad_panel"
		if not Banco.texto_presente(regla.get("explicacion_seguridad")):
			return ".explicacion_seguridad"
	if regla.has("componente") and regla.componente not in COMPONENTES:
		return ".componente"
	if not Banco.COMPETENCIAS.has(regla.get("competencia")):
		return ".competencia"
	if regla.get("criticidad") not in Banco.CRITICIDADES:
		return ".criticidad"
	var tipo: Variant = regla.get("tipo_error")
	if tipo not in Banco.TIPOS_ERROR and not (tipo == "" and regla.criticidad == "normal"):
		return ".tipo_error"
	if regla.get("causa") not in datos.causas and regla.get("causa") != "":
		return ".causa"
	if grupo == "recuperaciones":
		for campo in ["costo", "tiempo", "riesgo"]:
			if not Banco.texto_presente(regla.get(campo)):
				return "." + campo
	return ""


static func fuente_valida(fuente: Variant, muestra: bool) -> bool:
	if not Banco.texto_presente(fuente):
		return false
	if fuente == Banco.FUENTE_MUESTRA:
		return muestra
	if fuente == FUENTE_BZR:
		return muestra
	for permitida in Banco.FUENTES_PERMITIDAS:
		if fuente == permitida or fuente.begins_with(permitida + ": "):
			return true
	return false


static func asignacion_valida(asignacion: Variant, estado: Dictionary) -> bool:
	if not asignacion is Dictionary:
		return false
	for campo in asignacion:
		if not estado.has(campo) or not valor_simple(asignacion[campo]):
			return false
		if typeof(asignacion[campo]) != typeof(estado[campo]) \
				and not (numero(asignacion[campo]) and numero(estado[campo])):
			return false
	return true


static func numero(valor: Variant) -> bool:
	return (valor is int or valor is float) and is_finite(valor)


static func valor_simple(valor: Variant) -> bool:
	return valor is bool or valor is String or numero(valor)


static func cumple(estado: Dictionary, condiciones: Dictionary) -> bool:
	for campo in condiciones:
		if not estado.has(campo) or estado[campo] != condiciones[campo]:
			return false
	return true


static func imposible(estado: Dictionary, prohibidos: Array) -> bool:
	for condicion in prohibidos:
		if cumple(estado, condicion):
			return true
	return false


static func error(ruta: String, campo: String, mensaje: String) -> Dictionary:
	return {"escenario": {}, "errores": ["%s: %s: %s" % [ruta, campo, mensaje]]}


static func ciclo_eventos(eventos: Dictionary) -> bool:
	var conexiones := {}
	for id in eventos:
		var origen: Dictionary = eventos[id]
		var despues: Dictionary = origen.condicion.merged(origen.efectos, true)
		conexiones[id] = []
		for destino in eventos:
			var condicion: Dictionary = eventos[destino].condicion
			if conflicto(condicion, despues):
				continue
			for campo in origen.efectos:
				if condicion.has(campo) and origen.condicion.get(campo) != condicion[campo]:
					conexiones[id].append(destino)
					break
	# Si quedan eventos sin poder retirar, sus dependencias forman un ciclo.
	while not conexiones.is_empty():
		var retirados := []
		for id in conexiones:
			if conexiones[id].is_empty():
				retirados.append(id)
		if retirados.is_empty():
			return true
		for id in retirados:
			conexiones.erase(id)
			for pendientes in conexiones.values():
				pendientes.erase(id)
	return false


static func conflicto(primera: Dictionary, segunda: Dictionary) -> bool:
	for campo in primera:
		if segunda.has(campo) and segunda[campo] != primera[campo]:
			return true
	return false
