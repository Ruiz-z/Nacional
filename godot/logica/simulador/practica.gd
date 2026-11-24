extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")
const Intentos = preload("res://logica/aprendizaje/registro.gd")
const Eventos = preload("res://logica/tablero/registro_simulador.gd")
static func opciones(motor: RefCounted, escenario: Dictionary) -> Dictionary:
	if not motor.fin().is_empty():
		return {}
	var acciones: Dictionary = escenario.acciones.duplicate()
	acciones.erase("inspeccionar")
	return acciones.merged(motor.recuperaciones_disponibles())


static func guardar(base: String, tecnico: int, alias: String, motor: RefCounted, ahora: int) -> bool:
	var reloj := Reloj.estado(base, tecnico, ahora)
	if reloj.is_empty():
		return false
	var fecha := Time.get_datetime_string_from_unix_time(reloj.instante) + "Z"
	var entrega: Dictionary = motor.resultados(fecha)
	if entrega.is_empty():
		return false
	var sql := "BEGIN IMMEDIATE;" + Eventos.INSERTAR
	var parametros := Eventos.datos_entrega(tecnico, entrega)
	for intento in entrega.intentos:
		var valores := Intentos.preparar(alias, intento)
		if valores.is_empty():
			return false
		sql += Intentos.INSERTAR
		parametros.append_array(valores)
	return Acceso.consultar(base, sql + "COMMIT;", parametros) != null
