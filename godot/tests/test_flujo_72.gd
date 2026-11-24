extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var flujo = load("res://logica/flujo/recorrido.gd")
	if flujo == null or not flujo.has_method("cerrar_paso"):
		return false
	var alta := Alias.alta(base, "T-72", Base.consultar)
	if not alta.ok:
		return false
	var id: int = alta.id
	var respaldo := base + ".respaldo"
	var salto: Dictionary = flujo.cerrar_paso(base, respaldo, id, "ruta", [], 0, 0, Base.consultar)
	if salto.guardado or FileAccess.file_exists(respaldo):
		return false
	var guardado: Dictionary = flujo.cerrar_paso(base, respaldo, id, "diagnostico", ["seguridad"], 0, 0, Base.consultar)
	if not guardado.guardado or not guardado.respaldo:
		return false
	var cierre_interrumpido := func() -> void:
		var borrador: Dictionary = flujo.estado(base, id, 0, Base.consultar)
		borrador.ruta.clear()
		borrador.microlecciones_hechas = 1
	cierre_interrumpido.call()
	var reabierto: Dictionary = flujo.estado(base, id, 0, Base.consultar)
	if reabierto.siguiente != "ruta" or reabierto.ruta != ["seguridad"] or reabierto.microlecciones_hechas != 0:
		return false
	if reabierto != flujo.estado(respaldo, id, 0, Base.consultar):
		return false
	var sin_respaldo: Dictionary = flujo.cerrar_paso(base, base + "/respaldo", id, "ruta", [], 1, 0, Base.consultar)
	return sin_respaldo.guardado and not sin_respaldo.respaldo \
		and flujo.estado(base, id, 0, Base.consultar).siguiente == "escenario"
