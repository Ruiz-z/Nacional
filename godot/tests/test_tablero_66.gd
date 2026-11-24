extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Demo = preload("res://logica/tablero/demo.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var resultados = load("res://logica/tablero/resultados.gd")
	if resultados == null or not Demo.precargar(base, Base.consultar):
		return false
	if Base.consultar(base, "INSERT INTO tecnico(alias) VALUES ('T-02');") == null:
		return false
	var csv := base + ".csv"
	var json := base + ".json"
	if not resultados.exportar(base, csv, "csv", Demo.ALIAS, Base.consultar) \
			or not resultados.exportar(base, json, "json", "", Base.consultar):
		return false
	var contenido := FileAccess.get_file_as_string(csv)
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(json))
	if not datos is Dictionary or datos.tecnicos.size() != 2 or datos.intentos.size() != 3:
		return false
	if datos.fecha.is_empty() or datos.versiones_contenido != ["1"] \
			or not contenido.contains("version_contenido") or not contenido.contains("La mitad de la carga") \
			or contenido.contains("T-02"):
		return false
	return not resultados.borrar(base, Demo.ALIAS, false, Base.consultar) \
		and Base.consultar(base, "SELECT id FROM intento;").size() == 3 \
		and resultados.borrar(base, Demo.ALIAS, true, Base.consultar) \
		and Base.consultar(base, "SELECT id FROM intento;") == [] \
		and Base.consultar(base, "SELECT alias FROM tecnico;") == [{"alias": "T-02"}]
