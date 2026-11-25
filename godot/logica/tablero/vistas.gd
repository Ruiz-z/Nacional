extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")

const AYUDA := """Dominio = suma de valor × peso ÷ suma de pesos de los últimos 10 intentos.
Peso por dificultad: fácil 1, media 2, difícil 3. Práctica ×2. Falta crítica: 0 con peso 3. Brecha: 0 con peso 1.
Nivel: Novato <40, Básico 40–69, Competente 70–89, Experto ≥90.
Confianza: baja con solo teoría, alta con teoría y práctica.
Ganancia indicativa = dominio post − dominio pre.
Retención simulada = dominio retest ÷ dominio post × 100, con tope de 100. Si post es 0, no calculable.
Error recurrente = mismo tipo de error al menos 3 veces en una competencia.
Brechas y faltas críticas = conteo de registros. Última falta = fecha más reciente.
Tiempo promedio = suma de los milisegundos ÷ número de acciones registradas.
Avance = microlecciones completadas y pendientes en la ruta guardada."""

const Permisos = preload("res://logica/tablero/permisos.gd")

const AYUDA_JEFE := """Oportunidades = respuestas y prácticas registradas. Un intento incorrecto cuenta como un error.
Intentos sin ayuda = oportunidades con cero ayudas registradas.
Los casos con banco requieren que el historial identifique el banco físico."""


# El técnico solo recibe su propio usuario; sin rol válido no se entrega nada.
static func aliases(base: String, rol: String = "", actor: String = "") -> Array:
	if rol == Permisos.TECNICO and not actor.is_empty():
		return [actor]
	if not Permisos.puede_ver_equipo(rol):
		return []
	var filas: Variant = Acceso.consultar(base, "SELECT alias FROM tecnico WHERE clave_hash <> '' OR demo = 1 ORDER BY alias;")
	return [] if filas == null else filas.map(func(fila: Dictionary) -> String: return fila.alias)


static func sesiones(intentos: Array) -> Array[Dictionary]:
	# Con `sesion` se agrupa por sesión; los intentos anteriores usan la fecha y el momento.
	var grupos := {}
	var grupos_fecha := {}
	for intento in intentos:
		var sesion: String = intento.get("sesion_id", "")
		# Una sesión forma un punto por competencia, aunque sus respuestas tengan relojes distintos.
		var clave := [intento.reloj_sim, intento.momento, intento.competencia] if sesion.is_empty() \
			else [intento.reloj_sim, intento.momento, intento.competencia, sesion]
		if not sesion.is_empty():
			clave = [grupos_fecha.get_or_add([sesion, intento.competencia], intento.reloj_sim),
				intento.momento, intento.competencia, sesion]
		grupos.get_or_add(clave, []).append(intento)
	var salida: Array[Dictionary] = []
	for clave in grupos:
		salida.append({"fecha": clave[0], "momento": clave[1], "competencia": clave[2],
			"dominio": Dominio.promedio(grupos[clave])})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.fecha < b.fecha)
	return salida


static func ultimas_sesiones(sesiones_ordenadas: Array) -> Dictionary:
	var grupos := {}
	for sesion in sesiones_ordenadas:
		var recientes: Array = grupos.get_or_add(sesion.competencia, [])
		recientes.append(sesion)
		if recientes.size() > 2:
			recientes.pop_front()
	return grupos
