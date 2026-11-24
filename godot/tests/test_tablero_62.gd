extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var demo = load("res://logica/tablero/demo.gd")
	if demo == null or not demo.precargar(base, Base.consultar) or not demo.precargar(base, Base.consultar):
		return false
	var datos := Consultas.tecnico(base, demo.ALIAS, Base.consultar)
	return datos.demo and datos.intentos.size() == 3 and datos.intentos[0].momento == "pre" \
		and datos.intentos[1].momento == "post" and datos.intentos[2].momento == "retest" \
		and datos.intentos[2].reloj_sim > datos.intentos[1].reloj_sim
