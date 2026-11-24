extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")
const Demo = preload("res://logica/tablero/demo.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if Base.consultar(base, "INSERT INTO tecnico(alias) VALUES ('T-01');") == null:
		return false
	var datos := Consultas.tecnico(base, "T-01", Base.consultar)
	if datos.get("estado") != "sin_sesiones" or not datos.intentos.is_empty():
		return false
	for competencia in datos.competencias.values():
		if competencia.dominio != "pendiente" or competencia.nivel != "pendiente" \
				or competencia.ganancia != "pendiente" or competencia.retencion != "pendiente":
			return false
	if not Demo.precargar(base, Base.consultar):
		return false
	datos = Consultas.tecnico(base, Demo.ALIAS, Base.consultar)
	return datos.estado == "con_sesiones" and datos.competencias["diagnostico-fallas"].dominio == "pendiente" \
		and Consultas.tecnico(base, "ausente", Base.consultar).is_empty()
