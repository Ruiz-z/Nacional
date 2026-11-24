extends RefCounted

const Base = preload("res://tests/base_tablero.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var alias = load("res://logica/flujo/alias.gd")
	if alias == null:
		return false
	for invalido in ["", "   ", "Ana López", "Pablo", "T-12 Ana", "T-1"]:
		if alias.alta(base, invalido, Base.consultar).ok:
			return false
	var alta: Dictionary = alias.alta(base, " t-042 ", Base.consultar)
	if not alta.ok or alta.alias != "T-042" or alta.id <= 0:
		return false
	var repetido: Dictionary = alias.alta(base, "T-042", Base.consultar)
	return not repetido.ok and repetido.mensaje.contains("ya existe") \
		and alias.elegir(base, "t-042", Base.consultar) == alta \
		and not alias.elegir(base, "T-050", Base.consultar).ok
