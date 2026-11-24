extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const SEGUNDOS_DIA := 86400

static func registrar(base: String, tecnico: int, item: String, acierto: bool, ahora: int,
		consultar: Callable = Acceso.consultar) -> bool:
	# SQLite actualiza la caja y la fecha en una sola escritura.
	const SQL := """
		INSERT INTO leitner (tecnico, item, caja, proxima_fecha_sim)
		VALUES (?, ?, 1, ?)
		ON CONFLICT(tecnico, item) DO UPDATE SET
			caja = CASE WHEN ? THEN min(3, caja + 1) ELSE 1 END,
			proxima_fecha_sim = CASE
				WHEN ? = 0 THEN excluded.proxima_fecha_sim
				WHEN caja = 1 THEN ?
				ELSE ? END;
	"""
	var dia := fecha(ahora + SEGUNDOS_DIA)
	return consultar.call(base, SQL, [tecnico, item, dia, int(acierto), int(acierto),
		fecha(ahora + 3 * SEGUNDOS_DIA), fecha(ahora + 7 * SEGUNDOS_DIA)]) != null


static func vencidos(base: String, tecnico: int, ahora: int,
		consultar: Callable = Acceso.consultar) -> Variant:
	return consultar.call(base, """
		SELECT item, caja, proxima_fecha_sim FROM leitner
		WHERE tecnico = ? AND proxima_fecha_sim <= ? ORDER BY proxima_fecha_sim, item;
	""", [tecnico, fecha(ahora)])


static func fecha(instante: int) -> String:
	return Time.get_datetime_string_from_unix_time(instante) + "Z"


# El banco puede relacionar una variante con su ítem original mediante variante_de.
static func item_repetido(banco: Dictionary, id: String) -> Dictionary:
	var original := {}
	for item in banco.items:
		if item.id == id:
			original = item
			break
	if original.is_empty():
		return {}
	for item in banco.items:
		if item.id != id and item.get("variante_de") == id \
				and item.competencia == original.competencia and item.formato == original.formato \
				and item.dificultad == original.dificultad:
			return item.duplicate(true)
	return original.duplicate(true)
