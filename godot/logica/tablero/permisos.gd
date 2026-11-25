extends RefCounted

# Qué puede hacer cada rol. La lógica de datos consulta estas reglas; ocultar un botón no basta.
const TECNICO := "tecnico"
const JEFE := "jefe"
const ADMIN := "admin"


static func puede_ver_equipo(rol: String) -> bool:
	return rol in [JEFE, ADMIN]


static func puede_exportar(rol: String) -> bool:
	return rol in [JEFE, ADMIN]


static func puede_administrar(rol: String) -> bool:
	return rol == ADMIN


static func puede_borrar(rol: String) -> bool:
	return rol == ADMIN


# El técnico solo ve su propia ficha; jefe directo y admin ven las de todos.
static func puede_ver(rol: String, actor: String, objetivo: String) -> bool:
	return puede_ver_equipo(rol) or (rol == TECNICO and not actor.is_empty() and actor == objetivo)


# Enfoque con el que abre el tablero: personal, equipo u operativo.
static func vista_inicial(rol: String) -> String:
	return {TECNICO: "tecnico", JEFE: "jefe", ADMIN: "admin"}.get(rol, "tecnico")
