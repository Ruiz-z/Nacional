extends RefCounted

const Esquema = preload("res://logica/datos/esquema.gd")
const PruebaSQLite = preload("res://tests/test_aprendizaje_25.gd")

static func ejecutar() -> bool:
	var registro = load("res://logica/aprendizaje/registro.gd")
	if registro == null:
		return false
	var base := OS.get_temp_dir().path_join("intentos-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".sqlite")
	var consulta := PruebaSQLite.motor()
	var intento := {"competencia": "diagnostico-fallas", "item": "p1", "formato": "opcion-multiple",
		"dificultad": "media", "respuesta": "Opción 'B'", "resultado": "incorrecto",
		"tipo_error": "causa-equivocada", "tiempo_ms": 300, "fuente_entrada": "teclado",
		"momento": "pre", "reloj_sim": "2026-01-01T00:00:00Z", "version_contenido": "1"}
	var correcto: bool = Esquema.crear(base, consulta) \
		and consulta.call(base, "INSERT INTO tecnico (id, alias) VALUES (1, 'prueba');") != null \
		and not registro.guardar(base, "inexistente", intento, consulta) \
		and registro.guardar(base, "prueba", intento, consulta)
	var filas: Variant = registro.leer(base, "prueba", consulta)
	DirAccess.remove_absolute(base)
	if not correcto or not filas is Array or filas.size() != 1:
		return false
	for campo in intento:
		if filas[0][campo] != intento[campo]:
			return false
	return filas[0].tecnico == 1 and filas[0].alias == "prueba" \
		and filas[0].valor == 0 and filas[0].peso == 2
