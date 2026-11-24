extends RefCounted

const Esquema = preload("res://logica/datos/esquema.gd")
const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")
const Leitner = preload("res://logica/aprendizaje/leitner.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const PASOS := ["diagnostico", "ruta", "escenario", "post", "retest", "tablero"]

static func estado(base: String, tecnico: int, ahora_real: int,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var sin_tecnico := {"siguiente": "alias", "habilitados": ["alias", "modo_demo"]}
	if tecnico <= 0:
		return sin_tecnico
	var filas: Variant = consultar.call(base, """
		SELECT progreso.paso_actual, progreso.ruta, progreso.microlecciones_hechas,
			(SELECT max(reloj_sim) FROM intento WHERE tecnico = ? AND momento = 'post') AS ultimo_post
		FROM tecnico LEFT JOIN progreso ON progreso.tecnico = tecnico.id WHERE tecnico.id = ?;
	""", [tecnico, tecnico])
	if filas == null:
		return {}
	if filas.is_empty():
		return sin_tecnico

	var datos: Dictionary = filas[0]
	var paso: String = datos.paso_actual if datos.paso_actual in PASOS else PASOS[0]
	var habilitados := ["alias", "modo_demo"]
	var ruta: Variant = JSON.parse_string(datos.ruta) if datos.ruta != null else []
	var completadas: Variant = datos.microlecciones_hechas
	var resultado := {"siguiente": paso, "habilitados": habilitados,
		"ruta": ruta if ruta is Array else [], "microlecciones_hechas": 0 if completadas == null else int(completadas)}
	if paso == "retest":
		var reloj := Reloj.estado(base, tecnico, ahora_real, consultar)
		if reloj.is_empty():
			return {}
		if datos.ultimo_post == null:
			resultado["aviso"] = "Falta registrar el post-test."
			return resultado
		var fecha := Time.get_unix_time_from_datetime_string(datos.ultimo_post.trim_suffix("Z"))
		var faltan: int = fecha + 7 * Leitner.SEGUNDOS_DIA - reloj.instante
		if faltan > 0:
			var dias := ceili(float(faltan) / Leitner.SEGUNDOS_DIA)
			resultado["dias_para_retest"] = dias
			resultado["aviso"] = "El retest estará disponible en %d día(s)." % dias
			return resultado
	habilitados.append(paso)
	return resultado


# La ruta contiene las microlecciones pendientes al terminar el paso.
static func cerrar_paso(base: String, respaldo: String, tecnico: int, paso: String, ruta: Array,
		completadas: int, ahora_real: int, consultar: Callable = Acceso.consultar,
		intentos: Array = []) -> Dictionary:
	var resultado := {"guardado": false, "respaldo": false}
	var indice := PASOS.find(paso)
	if indice < 0 or indice == PASOS.size() - 1 or completadas < 0:
		return resultado
	var actual := estado(base, tecnico, ahora_real, consultar)
	if actual.get("siguiente") != paso or paso not in actual.habilitados:
		return resultado

	var siguiente: String = PASOS[indice + 1]
	var sql := """
		INSERT INTO progreso (tecnico, paso_actual, ruta, microlecciones_hechas)
		SELECT id, ?, ?, ? FROM tecnico WHERE id = ?
			AND coalesce((SELECT paso_actual FROM progreso WHERE tecnico = ?), 'diagnostico') = ?
		ON CONFLICT(tecnico) DO UPDATE SET paso_actual = excluded.paso_actual,
			ruta = excluded.ruta, microlecciones_hechas = excluded.microlecciones_hechas;
	"""
	var parametros := [siguiente, JSON.stringify(ruta), completadas, tecnico, tecnico, paso]
	# changes() enlaza las inserciones al único avance permitido para el técnico.
	for intento in intentos:
		if intento.is_empty():
			return resultado
		sql += Registro.INSERTAR_SI_AVANZO
		parametros.append_array(intento)
	var filas: Variant = consultar.call(base, "BEGIN IMMEDIATE;" + sql +
		"COMMIT; SELECT changes() AS guardado;", parametros)
	if filas == null or filas.is_empty() or filas[0].guardado != 1:
		return resultado
	resultado.guardado = true
	resultado.respaldo = Esquema.respaldar(base, respaldo, consultar)
	return resultado


static func cerrar_escenario(base: String, tecnico: int, fin: String, ahora: int) -> Dictionary:
	if fin != "resuelto":
		return {}
	var actual := estado(base, tecnico, ahora)
	if actual.get("siguiente") != "escenario":
		return {}
	return cerrar_paso(base, base + ".respaldo.sqlite", tecnico, "escenario",
		actual.ruta, actual.microlecciones_hechas, ahora)
