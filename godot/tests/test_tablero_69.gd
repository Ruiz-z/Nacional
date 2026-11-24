extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Asistente = preload("res://logica/tablero/asistente.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")
const Demo = preload("res://logica/tablero/demo.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if not Demo.precargar(base, Base.consultar):
		return false
	var antes := Consultas.tecnico(base, Demo.ALIAS, Base.consultar)
	var asistente := Asistente.new()
	var respuesta := asistente.responder("carga", Callable(), antes)
	if respuesta.get("disponible", true) or respuesta.texto != "El asistente no está disponible. Intenta de nuevo más tarde.":
		return false
	var fuente := base + ".txt"
	var archivo := FileAccess.open(fuente, FileAccess.WRITE)
	if archivo == null or not archivo.store_string("Carga de ejemplo."):
		return false
	archivo.close()
	var indexado := asistente.indexar([{"ruta": fuente, "cita": "Ejemplo"}])
	DirAccess.remove_absolute(fuente)
	if not indexado:
		return false
	var desconectado := func(_peticion: Dictionary) -> Variant: return null
	respuesta = asistente.responder("carga", desconectado, antes)
	return not respuesta.disponible and respuesta.texto == "El asistente no está disponible. Intenta de nuevo más tarde." \
		and Consultas.tecnico(base, Demo.ALIAS, Base.consultar) == antes
