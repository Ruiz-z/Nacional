extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Permisos = preload("res://logica/tablero/permisos.gd")
const Resultados = preload("res://logica/tablero/resultados.gd")
const Vistas = preload("res://logica/tablero/vistas.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")


static func ejecutar() -> bool:
	var iteraciones := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var correcto := reglas() and Base.con_base(datos)
	Contrasena.iteraciones_actuales = iteraciones
	return correcto


static func reglas() -> bool:
	return Permisos.puede_ver_equipo("jefe") and Permisos.puede_ver_equipo("admin") and not Permisos.puede_ver_equipo("tecnico") \
		and not Permisos.puede_ver_equipo("") and not Permisos.puede_exportar("tecnico") and Permisos.puede_exportar("jefe") \
		and Permisos.puede_administrar("admin") and not Permisos.puede_administrar("jefe") \
		and Permisos.puede_borrar("admin") and not Permisos.puede_borrar("jefe") and not Permisos.puede_borrar("tecnico") \
		and Permisos.puede_ver("tecnico", "ana", "ana") and not Permisos.puede_ver("tecnico", "ana", "luis") \
		and not Permisos.puede_ver("tecnico", "", "") and Permisos.puede_ver("jefe", "x", "ana") \
		and Permisos.vista_inicial("jefe") == "jefe" and Permisos.vista_inicial("admin") == "admin" \
		and Permisos.vista_inicial("tecnico") == "tecnico" and Permisos.vista_inicial("raro") == "tecnico"


static func datos(base: String) -> bool:
	Cuentas.crear(base, "ana", "tecnico", "clave-de-ana-1")
	Cuentas.crear(base, "luis", "tecnico", "clave-de-luis-1")
	Cuentas.crear(base, "jefa", "jefe", "clave-de-jefa-1")
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('T-01');")
	var carpeta := OS.get_temp_dir()
	var csv := carpeta.path_join("auth-%s.csv" % Crypto.new().generate_random_bytes(4).hex_encode())
	var json := csv.replace(".csv", ".json")
	var exporta_jefe := Resultados.exportar(base, json, "json", "", "jefe", Base.consultar)
	var texto := FileAccess.get_file_as_string(json) if exporta_jefe else ""
	DirAccess.remove_absolute(json)
	var perfil := Consultas.tecnico(base, "ana", Base.consultar)
	return Vistas.aliases(base, "tecnico", "ana") == ["ana"] and Vistas.aliases(base, "tecnico", "") == [] \
		and Vistas.aliases(base, "", "ana") == [] and Vistas.aliases(base, "raro", "ana") == [] \
		and Vistas.aliases(base, "jefe") == ["ana", "jefa", "luis"] and Vistas.aliases(base, "admin").size() == 3 \
		and not Resultados.exportar(base, csv, "csv", "", "tecnico", Base.consultar) and not FileAccess.file_exists(csv) \
		and not Resultados.exportar(base, csv, "csv", "", "", Base.consultar) \
		and exporta_jefe and texto.contains("\"ana\"") and not texto.contains("clave_hash") and not texto.contains("pbkdf2") \
		and not Resultados.borrar(base, "ana", true, "jefe", Base.consultar) \
		and not Resultados.borrar(base, "ana", true, "tecnico", Base.consultar) \
		and not Resultados.borrar(base, "ana", false, "admin", Base.consultar) \
		and Resultados.borrar(base, "ana", true, "admin", Base.consultar) \
		and not perfil.is_empty() and not perfil.has("clave_hash")
