extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const RegistroSimulador = preload("res://logica/tablero/registro_simulador.gd")
const TABLAS := {"tecnicos": "tecnico", "intentos": "intento", "eventos": "evento", "brechas": "brecha"}

static func exportar(base: String, destino: String, formato: String, alias: String = "",
		consultar: Callable = Acceso.consultar) -> bool:
	if formato not in ["csv", "json"] or not destino.ends_with("." + formato):
		return false
	var datos := {"fecha": Time.get_datetime_string_from_system(true) + "Z", "versiones_contenido": []}
	for grupo in TABLAS:
		var tabla: String = TABLAS[grupo]
		var sql := "SELECT tecnico.* FROM tecnico" if tabla == "tecnico" else \
			"SELECT %s.*, tecnico.alias FROM %s JOIN tecnico ON tecnico.id = %s.tecnico" % [tabla, tabla, tabla]
		var parametros: Array = []
		if not alias.is_empty():
			sql += " WHERE tecnico.alias = ?"
			parametros.append(alias)
		var filas: Variant = consultar.call(base, sql + " ORDER BY " + tabla + ".id;", parametros)
		if filas == null:
			return false
		datos[grupo] = filas
	if not alias.is_empty() and datos.tecnicos.is_empty():
		return false
	for evento in datos.eventos:
		RegistroSimulador.leer_metadatos(evento)
	for fila in datos.intentos + datos.eventos:
		var version: Variant = fila.get("version_contenido")
		if version is String and not version.is_empty() and version not in datos.versiones_contenido:
			datos.versiones_contenido.append(version)

	var archivo := FileAccess.open(destino, FileAccess.WRITE)
	if archivo == null:
		return false
	if formato == "json":
		return archivo.store_string(JSON.stringify(datos, "\t") + "\n")
	return escribir_csv(archivo, datos)


static func escribir_csv(archivo: FileAccess, datos: Dictionary) -> bool:
	var columnas := PackedStringArray(["fecha", "tipo", "version_contenido"])
	for grupo in TABLAS:
		for fila in datos[grupo]:
			for campo in fila:
				if campo not in columnas:
					columnas.append(campo)
	if not archivo.store_csv_line(columnas):
		return false
	if datos.tecnicos.is_empty():
		return archivo.store_csv_line(PackedStringArray([datos.fecha, "exportacion", ""]))
	for grupo in TABLAS:
		for fila in datos[grupo]:
			var valores := PackedStringArray([datos.fecha, TABLAS[grupo]])
			for i in range(2, columnas.size()):
				var valor: Variant = fila.get(columnas[i])
				valores.append("" if valor == null else str(valor))
			if not archivo.store_csv_line(valores):
				return false
	return true


static func borrar(base: String, alias: String, confirmado: bool,
		consultar: Callable = Acceso.consultar) -> bool:
	if not confirmado:
		return false
	var filas: Variant = consultar.call(base, "DELETE FROM tecnico WHERE alias = ? RETURNING id;", [alias])
	return filas != null and not filas.is_empty()
