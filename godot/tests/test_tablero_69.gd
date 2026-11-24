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
	var respuesta := Asistente.responder(base, "carga", Callable(), antes, Base.consultar)
	if respuesta.get("disponible", true) or respuesta.texto != "Asistente no disponible":
		return false
	var fuente := base + ".txt"
	var archivo := FileAccess.open(fuente, FileAccess.WRITE)
	if archivo == null or not archivo.store_string("Carga de ejemplo."):
		return false
	archivo.close()
	if not Asistente.indexar(base, [{"ruta": fuente, "cita": "Ejemplo"}], Base.consultar):
		return false
	var desconectado := func(_peticion: Dictionary) -> Variant: return null
	respuesta = Asistente.responder(base, "carga", desconectado, antes, Base.consultar)
	return not respuesta.disponible and respuesta.texto == "Asistente no disponible" \
		and Consultas.tecnico(base, Demo.ALIAS, Base.consultar) == antes
