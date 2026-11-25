extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const VistaAdmin = preload("res://logica/tablero/vista_admin.gd")


static func ejecutar() -> bool:
	var iteraciones := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var correcto := Base.con_base(comprobar)
	Contrasena.iteraciones_actuales = iteraciones
	return correcto


static func comprobar(base: String) -> bool:
	Cuentas.crear(base, "admin.uno", "admin", "clave-del-admin")
	Cuentas.crear(base, "jefa", "jefe", "clave-de-jefa-1")
	Cuentas.crear(base, "ana", "tecnico", "clave-de-ana-1")
	Cuentas.crear(base, "luis", "tecnico", "clave-de-luis-1")
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('T-01');")
	Base.consultar(base, """
		INSERT INTO intento(tecnico, competencia, item, formato, dificultad, respuesta, valor, peso,
			resultado, tipo_error, tiempo_ms, fuente_entrada, momento, reloj_sim, version_contenido)
		SELECT id, 'seguridad-alto-voltaje', 'x', 'opcion-multiple', 'facil', '0', 100, 1,
			'correcto', NULL, 5, 'interfaz', 'pre', '2026-01-12', '1' FROM tecnico WHERE alias = 'ana';
	""")
	var items := [{"revisado": false}, {"revisado": true}, {"id": "sin-campo"}]
	var vacio := VistaAdmin.resumen(base, items, true, "/ruta/que/no/existe.sqlite", Base.consultar)
	var carpeta := OS.get_temp_dir().path_join("nacional-%s.respaldo" % Crypto.new().generate_random_bytes(4).hex_encode())
	var archivo := FileAccess.open(carpeta, FileAccess.WRITE)
	archivo.store_string("x")
	archivo.close()
	var con_respaldo := VistaAdmin.resumen(base, items, false, carpeta, Base.consultar)
	DirAccess.remove_absolute(carpeta)
	return vacio.cuentas == {"tecnico": 3, "jefe": 1, "admin": 1} and vacio.heredadas == 1 \
		and vacio.tecnicos.size() == 2 and vacio.con_actividad == 1 and vacio.sin_actividad == 1 \
		and vacio.tecnicos[0].alias == "ana" and vacio.tecnicos[0].ultima == "2026-01-12" and vacio.tecnicos[1].ultima == "" \
		and vacio.preguntas == 3 and vacio.pendientes_revision == 2 and vacio.foundry \
		and not vacio.respaldo.existe and vacio.respaldo.fecha == "" \
		and con_respaldo.respaldo.existe and con_respaldo.respaldo.fecha.length() == 16 and not con_respaldo.foundry
