extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")


static func ejecutar() -> bool:
	var lista := Cuentas.accesos_rapidos({"NACIONAL_ACCESO_RAPIDO": " Mau, admin ,prueba,mau,x"})
	if lista != ["mau", "admin", "prueba"] or not Cuentas.accesos_rapidos({}).is_empty():
		printerr("La lista de accesos rápidos no se lee bien")
		return false
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var anteriores := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	Cuentas.crear(base, "admin", "admin", "clave-larga-1")
	Cuentas.crear(base, "mau", "tecnico", "clave-larga-2")
	Cuentas.crear(base, "otra", "tecnico", "clave-larga-3")
	Contrasena.iteraciones_actuales = anteriores
	var permitidos := ["mau", "admin", "prueba"]
	var entra := Cuentas.entrar_rapido(base, "mau", permitidos)
	var admin := Cuentas.entrar_rapido(base, "admin", permitidos)
	return entra.ok and entra.rol == "tecnico" and admin.ok and admin.rol == "admin" \
		and not Cuentas.entrar_rapido(base, "otra", permitidos).ok \
		and not Cuentas.entrar_rapido(base, "prueba", permitidos).ok \
		and not Cuentas.entrar_rapido(base, "mau", []).ok
