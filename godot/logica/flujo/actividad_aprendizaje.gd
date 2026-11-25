extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Banco = preload("res://logica/competencias/banco.gd")
const Diagnostico = preload("res://logica/aprendizaje/diagnostico.gd")
const Evaluacion = preload("res://logica/aprendizaje/evaluacion.gd")
const Leitner = preload("res://logica/aprendizaje/leitner.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")
const Respuestas = preload("res://logica/aprendizaje/respuestas.gd")
const Ruta = preload("res://logica/aprendizaje/ruta.gd")
const RutaIA = preload("res://logica/aprendizaje/ruta_ia.gd")
const Sesion = preload("res://logica/aprendizaje/sesion.gd")

var base: String
var perfil: Dictionary
var paso: String
var plan := {}
var estado := {}
var historial: Array
var intentos := []
var items := []
var avisos := []
var resultados := {}
var ruta := []
var reloj_simulado := false
var sesion := ""
var banco_cargado := {}
var detalle_ia := {}
var origen_ruta := "reglas"
var fuentes_ia := []


func preparar(banco: Dictionary, ahora: int) -> bool:
	estado = Recorrido.estado(base, perfil.id, ahora)
	sesion = "%s-%s-%d" % [paso, perfil.get("alias", ""), ahora]
	var diagnosticado: bool = Recorrido.PASOS.find(estado.get("siguiente", "")) > 0
	if paso not in estado.get("habilitados", []) and not (paso == "ruta" and diagnosticado):
		avisos.append(estado.get("aviso", "Este paso todavía no está disponible."))
		return false
	if banco.is_empty():
		banco = Banco.cargar()
	banco_cargado = banco
	var reloj := Reloj.estado(base, perfil.id, ahora)
	if reloj.is_empty():
		avisos.append("No se pudo consultar la hora. Vuelve al menú e inténtalo otra vez.")
		return false
	reloj_simulado = reloj.simulado
	var filas: Variant = Registro.leer(base, perfil.alias)
	if filas == null:
		avisos.append("No se pudieron abrir tus intentos anteriores. Vuelve al menú e inténtalo otra vez.")
		return false
	historial = filas
	ruta = estado.ruta
	match paso:
		"diagnostico":
			plan = Diagnostico.preparar(banco, int(perfil.get("id", 0)))
		"ruta":
			ruta = ordenar(Diagnostico.resultado(historial, true), historial)
			plan = Sesion.preparar(ruta, Sesion.catalogo(banco))
			for leccion in plan.lecciones:
				items.append_array(leccion.items)
		"post":
			plan = Evaluacion.post(banco, ids_pre(), int(perfil.get("id", 0)))
		"retest":
			var post := historial.filter(func(fila: Dictionary) -> bool: return fila.momento == "post")
			if post.is_empty():
				avisos.append("No se pudo abrir tu evaluación anterior. Vuelve al menú e inténtalo otra vez.")
				return false
			var ultima_fecha: String = post.map(func(fila: Dictionary) -> String: return fila.reloj_sim).max()
			var fecha := Time.get_unix_time_from_datetime_string(ultima_fecha.trim_suffix("Z"))
			plan = Evaluacion.retest(banco, Evaluacion.reconstruir_post(post, ids_pre()),
				fecha, reloj.instante)
	if plan.has("items"):
		items = plan.items
	avisos.assign(plan.avisos)
	if not plan.get("equivalente", true):
		avisos.push_front("Las preguntas cambiaron. Tómalo en cuenta al comparar tus resultados.")
	var cantidad := 6 if paso == "ruta" else Evaluacion.cupos().size()
	if items.size() != cantidad:
		avisos.append("Faltan preguntas para abrir esta actividad. Vuelve al menú y elige otra actividad.")
		return false
	return true


func dominios_actuales() -> Dictionary:
	var dominios := {}
	var instantanea := Diagnostico.resultado(historial, true)
	for competencia in instantanea:
		dominios[competencia] = instantanea[competencia].dominio
	return dominios


func motivos_ruta() -> Array:
	var motivos := Ruta.motivos(ruta, dominios_actuales(), historial, 1)
	for tema in motivos:
		if detalle_ia.has(tema.competencia):
			tema.motivo = detalle_ia[tema.competencia].motivo
			tema.refuerzo = detalle_ia[tema.competencia].practica
	return motivos


func contexto_ruta(ordenes: Array) -> Dictionary:
	return RutaIA.contexto(perfil.get("alias", ""), ruta, dominios_actuales(), historial, ordenes)


# Reordena la ruta con la propuesta validada de la IA y rearma la sesión; las respuestas aún no empezaron.
func aplicar_ruta_ia(validada: Dictionary) -> bool:
	if validada.is_empty() or not intentos.is_empty() or paso != "ruta":
		return false
	var nuevo_plan := Sesion.preparar(validada.orden, Sesion.catalogo(banco_cargado))
	if nuevo_plan.lecciones.size() != 3:
		return false
	var nuevos := []
	for leccion in nuevo_plan.lecciones:
		nuevos.append_array(leccion.items)
	if nuevos.size() != items.size():
		return false
	ruta = validada.orden.duplicate()
	plan = nuevo_plan
	items = nuevos
	detalle_ia = validada.detalle.duplicate(true)
	fuentes_ia = validada.get("fuentes", []).duplicate()
	origen_ruta = "ia"
	return true


func leccion(indice: int) -> Dictionary:
	return plan.lecciones[numero_leccion(indice) - 1] if paso == "ruta" else {}


func numero_leccion(indice: int) -> int:
	return floori(indice / 2.0) + 1


func responder(respuesta: Variant, tiempo_ms: int, fuente: String, ahora: int) -> bool:
	if intentos.size() >= items.size():
		return false
	var reloj := Reloj.estado(base, perfil.id, ahora)
	if reloj.is_empty():
		return false
	var item: Dictionary = items[intentos.size()]
	if paso == "diagnostico" and item.formato == "opcion-multiple":
		Diagnostico.responder_media(plan, item.id, respuesta)
		avisos.assign(plan.avisos)
	var momento: String = {"diagnostico": "pre", "ruta": "practica"}.get(paso, paso)
	var intento := Respuestas.intento(item, respuesta, tiempo_ms, fuente, momento,
		Leitner.fecha(reloj.instante))
	intento.merge({"sesion_id": sesion, "caso": item.id, "numero_intento": intentos.size() + 1})
	intentos.append(intento)
	return true


func guardar(ahora: int) -> Dictionary:
	# La ruta se muestra como mapa, sin preguntas: el paso se cierra al continuar.
	if paso == "ruta":
		# Con la ruta ya cerrada, abrirla de nuevo solo la consulta.
		if Recorrido.estado(base, perfil.id, ahora).get("siguiente") != "ruta":
			return {"guardado": true, "respaldo": true}
		return Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", perfil.id, paso, ruta,
			estado.microlecciones_hechas, ahora)
	if items.is_empty() or intentos.size() != items.size():
		return {}
	var completadas: int = estado.microlecciones_hechas
	resultados = Diagnostico.resultado(intentos)
	if paso == "diagnostico":
		ruta = ordenar(resultados, intentos)
	var valores := intentos.map(func(intento: Dictionary) -> Array:
		return Registro.preparar(perfil.alias, intento))
	return Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", perfil.id, paso, ruta,
		completadas, ahora, Acceso.consultar, valores)


func ordenar(instantanea: Dictionary, intentos_previos: Array) -> Array:
	var dominios := {}
	for competencia in instantanea:
		dominios[competencia] = instantanea[competencia].dominio
	return Ruta.ordenar(dominios, intentos_previos, 1)


func ids_pre() -> Array:
	var pre := historial.filter(func(fila: Dictionary) -> bool: return fila.momento == "pre")
	return pre.map(func(fila: Dictionary) -> String: return fila.item)
