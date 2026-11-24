extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")
const Demo = preload("res://logica/tablero/demo.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var modo = load("res://logica/flujo/modo_demo.gd")
	if modo == null:
		return false
	var real := Alias.alta(base, "T-74", Base.consultar)
	if not real.ok or not Reloj.adelantar(base, real.id, 2, Base.consultar):
		return false
	var demo: Dictionary = modo.abrir(base, Base.consultar)
	if demo.is_empty() or demo.base == base or demo.alias != Demo.ALIAS:
		return false
	if modo.adelantar(base, -1, Base.consultar) or not modo.adelantar(base, 7, Base.consultar):
		return false
	if Reloj.estado(demo.base, demo.id, 0, Base.consultar).desplazamiento_dias != 7:
		return false
	if Base.consultar(demo.base, "DELETE FROM intento WHERE momento = 'retest';") == null:
		return false
	if not modo.restablecer(base, Base.consultar):
		return false
	demo = modo.abrir(base, Base.consultar)
	return Reloj.estado(demo.base, demo.id, 0, Base.consultar).desplazamiento_dias == 0 \
		and Consultas.tecnico(demo.base, Demo.ALIAS, Base.consultar).intentos.size() == 3 \
		and Base.consultar(base, "SELECT alias FROM tecnico;") == [{"alias": "T-74"}] \
		and Reloj.estado(base, real.id, 0, Base.consultar).desplazamiento_dias == 2
