extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")

static func alta(base: String, entrada: String, consultar: Callable = Acceso.consultar) -> Dictionary:
	var alias := normalizar(entrada)
	if alias.is_empty():
		return error("Escribe T, un guion y entre 2 y 8 dígitos. Por ejemplo, T-0001.")
	var filas: Variant = consultar.call(base, """
		INSERT INTO tecnico(alias) VALUES (?)
		ON CONFLICT(alias) DO NOTHING RETURNING id, alias;
	""", [alias])
	if filas is Array and filas.is_empty():
		return error("Ese alias ya existe. Pulsa Entrar con alias o escribe otro.")
	return perfil(filas)


static func elegir(base: String, entrada: String, consultar: Callable = Acceso.consultar) -> Dictionary:
	var alias := normalizar(entrada)
	if alias.is_empty():
		return error("Escribe T, un guion y entre 2 y 8 dígitos. Por ejemplo, T-0001.")
	return perfil(consultar.call(base, "SELECT id, alias FROM tecnico WHERE alias = ? AND demo = 0;", [alias]))


static func normalizar(entrada: String) -> String:
	var alias := entrada.strip_edges().to_upper()
	var formato := RegEx.create_from_string("^T-[0-9]{2,8}$")
	return alias if formato.search(alias) != null else ""


static func perfil(filas: Variant) -> Dictionary:
	if filas == null:
		return error("No se pudo buscar tu alias. Intenta de nuevo.")
	if filas.is_empty():
		return error("Ese alias aún no existe. Regístralo o escribe otro.")
	return {"ok": true, "id": int(filas[0].id), "alias": filas[0].alias}


static func error(mensaje: String) -> Dictionary:
	return {"ok": false, "mensaje": mensaje}
