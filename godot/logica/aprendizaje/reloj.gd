extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Leitner = preload("res://logica/aprendizaje/leitner.gd")

static func estado(base: String, tecnico: int, ahora_real: int,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var filas: Variant = consultar.call(base, """
		SELECT coalesce(reloj.desplazamiento_dias, 0) AS dias
		FROM tecnico LEFT JOIN reloj ON reloj.tecnico = tecnico.id WHERE tecnico.id = ?;
	""", [tecnico])
	if filas == null or filas.is_empty():
		return {}
	var dias := int(filas[0].dias)
	return {"desplazamiento_dias": dias, "instante": ahora_real + dias * Leitner.SEGUNDOS_DIA,
		"simulado": dias > 0}


static func adelantar(base: String, tecnico: int, dias: int,
		consultar: Callable = Acceso.consultar) -> bool:
	if dias < 0:
		return false
	return consultar.call(base, """
		INSERT INTO reloj (tecnico, desplazamiento_dias) VALUES (?, ?)
		ON CONFLICT(tecnico) DO UPDATE SET
			desplazamiento_dias = reloj.desplazamiento_dias + excluded.desplazamiento_dias;
	""", [tecnico, dias]) != null


static func restablecer_demo(base: String, tecnico: int,
		consultar: Callable = Acceso.consultar) -> bool:
	var filas: Variant = consultar.call(base, "SELECT id FROM tecnico WHERE id = ? AND demo = 1;", [tecnico])
	if filas == null or filas.is_empty():
		return false
	return consultar.call(base, """
		DELETE FROM reloj WHERE tecnico = (SELECT id FROM tecnico WHERE id = ? AND demo = 1);
	""", [tecnico]) != null
