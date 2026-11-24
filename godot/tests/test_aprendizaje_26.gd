extends RefCounted

const Esquema = preload("res://logica/datos/esquema.gd")
const PruebaSQLite = preload("res://tests/test_aprendizaje_25.gd")

static func ejecutar() -> bool:
	var reloj = load("res://logica/aprendizaje/reloj.gd")
	if reloj == null:
		return false
	var base := OS.get_temp_dir().path_join("reloj-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".sqlite")
	var consulta := PruebaSQLite.motor()
	var correcto: bool = Esquema.crear(base, consulta) \
		and consulta.call(base, "INSERT INTO tecnico (id, alias, demo) VALUES (1, 'demo', 1);") != null \
		and reloj.adelantar(base, 1, 7, consulta) \
		and not reloj.adelantar(base, 1, -1, consulta) \
		and reloj.estado(base, 1, 100, consulta) == {"desplazamiento_dias": 7,
			"instante": 604900, "simulado": true} \
		and reloj.restablecer_demo(base, 1, consulta) \
		and reloj.estado(base, 1, 100, consulta).instante == 100
	DirAccess.remove_absolute(base)
	return correcto
