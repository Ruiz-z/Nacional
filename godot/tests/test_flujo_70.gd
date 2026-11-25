extends RefCounted

const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
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
	return probar_usuario(base) and not repetido.ok and repetido.mensaje.contains("ya existe") \
		and alias.elegir(base, "t-042", Base.consultar) == alta \
		and not alias.elegir(base, "T-050", Base.consultar).ok


static func probar_usuario(base: String) -> bool:
	for invalido in ["", "   ", "Ana López", "T-12 Ana", "A?", "-123"]:
		if Cuentas.revisar_usuario(invalido).is_empty():
			return false
	var anterior := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var cuenta := Cuentas.crear(base, " Tecnico_042 ", "tecnico", "clave-de-prueba")
	var repetido := Cuentas.crear(base, "tecnico_042", "tecnico", "clave-de-prueba")
	Contrasena.iteraciones_actuales = anterior
	return cuenta.ok and cuenta.alias == "tecnico_042" and cuenta.id > 0 \
		and not repetido.ok and repetido.mensaje.contains("ya existe")
