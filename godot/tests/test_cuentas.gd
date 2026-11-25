extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Esquema = preload("res://logica/datos/esquema.gd")

const AHORA := 1800000000


static func ejecutar() -> bool:
	var iteraciones := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var correcto := Base.con_base(alta) and Base.con_base(ingreso) and Base.con_base(bloqueo) \
		and Base.con_base(claves) and Base.con_base(heredadas) and migracion() and permisos()
	Contrasena.iteraciones_actuales = iteraciones
	return correcto


static func alta(base: String) -> bool:
	var admin := Cuentas.crear(base, "  Admin.Taller ", "admin", "clave-del-admin")
	var repetido := Cuentas.crear(base, "admin.taller", "jefe", "otra-clave-larga")
	var filas: Array = Base.consultar(base, "SELECT alias, rol, clave_hash, cambiar_clave FROM tecnico;")
	return admin.ok and admin.alias == "admin.taller" and admin.rol == "admin" \
		and not repetido.ok and repetido.mensaje.contains("ya existe") \
		and filas.size() == 1 and filas[0].clave_hash.begins_with("pbkdf2-sha256$") \
		and not filas[0].clave_hash.contains("clave-del-admin") and filas[0].cambiar_clave == 0 \
		and not Cuentas.crear(base, "ab", "tecnico", "clave-larga-1").ok \
		and not Cuentas.crear(base, "Juan Perez", "tecnico", "clave-larga-1").ok \
		and not Cuentas.crear(base, "tecnico01", "root", "clave-larga-1").ok \
		and Cuentas.crear(base, "tecnico01", "tecnico", "corta").mensaje.contains("8 caracteres") \
		and Cuentas.crear(base, "tecnico02", "tecnico", "clave-temporal", true).ok \
		and Base.consultar(base, "SELECT cambiar_clave FROM tecnico WHERE alias = 'tecnico02';")[0].cambiar_clave == 1 \
		and Cuentas.hay_admin(base)


static func ingreso(base: String) -> bool:
	Cuentas.crear(base, "jefe.uno", "jefe", "clave-del-jefe")
	var bueno := Cuentas.entrar(base, "JEFE.UNO", "clave-del-jefe", AHORA)
	var malo := Cuentas.entrar(base, "jefe.uno", "clave-equivocada", AHORA)
	var desconocido := Cuentas.entrar(base, "nadie", "clave-equivocada", AHORA)
	return bueno.ok and bueno.rol == "jefe" and bueno.alias == "jefe.uno" and not bueno.cambiar_clave \
		and not malo.ok and malo.mensaje == Cuentas.MENSAJE_INVALIDO and malo.mensaje == desconocido.mensaje \
		and not Cuentas.entrar(base, "jefe.uno", "", AHORA).ok


static func bloqueo(base: String) -> bool:
	Cuentas.crear(base, "tecnico01", "tecnico", "clave-del-tecnico")
	for _i in range(4):
		Cuentas.entrar(base, "tecnico01", "mal-mal-mal", AHORA)
	var quinto := Cuentas.entrar(base, "tecnico01", "mal-mal-mal", AHORA)
	# Bloqueado: ni la contraseña correcta entra hasta que pase la espera.
	var durante := Cuentas.entrar(base, "tecnico01", "clave-del-tecnico", AHORA + 10)
	var despues := Cuentas.entrar(base, "tecnico01", "clave-del-tecnico", AHORA + 31)
	var limpio: Array = Base.consultar(base, "SELECT fallos, bloqueado_hasta FROM tecnico WHERE alias = 'tecnico01';")
	# La segunda tanda de 5 fallos espera el doble.
	for _i in range(5):
		Cuentas.entrar(base, "tecnico01", "mal-mal-mal", AHORA + 100)
	var segunda := Cuentas.entrar(base, "tecnico01", "clave-del-tecnico", AHORA + 101)
	return not quinto.ok and quinto.get("bloqueado", false) and quinto.espera_s == 30 and not durante.ok and durante.bloqueado and durante.espera_s == 20 \
		and despues.ok and limpio[0].fallos == 0 and limpio[0].bloqueado_hasta == 0 \
		and segunda.get("bloqueado", false) and segunda.espera_s == 29


static func claves(base: String) -> bool:
	var cuenta := Cuentas.crear(base, "tecnico03", "tecnico", "clave-inicial-1", true)
	var primera := Cuentas.entrar(base, "tecnico03", "clave-inicial-1", AHORA)
	var corta := Cuentas.cambiar_clave(base, cuenta.id, "corta")
	var cambio := Cuentas.cambiar_clave(base, cuenta.id, "clave-nueva-123")
	var restablecida := Cuentas.restablecer(base, cuenta.id)
	var con_temporal := Cuentas.entrar(base, "tecnico03", restablecida.get("temporal", ""), AHORA)
	return primera.ok and primera.cambiar_clave and not corta.ok and cambio.ok \
		and not Cuentas.entrar(base, "tecnico03", "clave-inicial-1", AHORA).ok \
		and restablecida.ok and restablecida.temporal.length() == 12 \
		and con_temporal.ok and con_temporal.cambiar_clave \
		and not Cuentas.entrar(base, "tecnico03", "clave-nueva-123", AHORA).ok \
		and not Cuentas.restablecer(base, 9999).ok


# Las cuentas anteriores (solo alias) y las de demostración no pueden entrar.
static func heredadas(base: String) -> bool:
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('T-01');")
	Base.consultar(base, "INSERT INTO tecnico (alias, demo) VALUES ('[DEMO] Taller-01', 1);")
	Cuentas.crear(base, "admin.uno", "admin", "clave-del-admin")
	var lista := Cuentas.listar(base)
	var heredada: Array = lista.filter(func(fila: Dictionary) -> bool: return fila.alias == "T-01")
	return not Cuentas.entrar(base, "T-01", "", AHORA).ok and not Cuentas.entrar(base, "t-01", "cualquiera", AHORA).ok \
		and not Cuentas.entrar(base, "[DEMO] Taller-01", "cualquiera", AHORA).ok \
		and lista.size() == 2 and heredada.size() == 1 and heredada[0].heredada \
		and Cuentas.hay_admin(base)


# Una base creada antes de las cuentas se completa sin perder técnicos ni intentos.
static func migracion() -> bool:
	var carpeta := OS.get_temp_dir().path_join("nacional-" + Crypto.new().generate_random_bytes(8).hex_encode())
	DirAccess.make_dir_absolute(carpeta)
	var base := carpeta.path_join("antigua.sqlite")
	var antigua := """
		CREATE TABLE tecnico (id INTEGER PRIMARY KEY, alias TEXT NOT NULL UNIQUE,
			demo INTEGER NOT NULL DEFAULT 0, creado TEXT NOT NULL DEFAULT 'x') STRICT;
		INSERT INTO tecnico (alias) VALUES ('T-07');
	"""
	var correcto: bool = Base.consultar(base, antigua) != null
	correcto = correcto and Esquema.crear(base)
	var columnas: Array = Base.consultar(base, "SELECT name FROM pragma_table_info('tecnico');").map(
		func(fila: Dictionary) -> String: return fila.name)
	var fila: Array = Base.consultar(base, "SELECT alias, rol, clave_hash, fallos FROM tecnico;")
	correcto = correcto and "rol" in columnas and "clave_hash" in columnas and "cambiar_clave" in columnas \
		and fila.size() == 1 and fila[0].alias == "T-07" and fila[0].rol == "tecnico" and fila[0].clave_hash == "" \
		and Esquema.crear(base)
	for archivo in DirAccess.get_files_at(carpeta):
		DirAccess.remove_absolute(carpeta.path_join(archivo))
	DirAccess.remove_absolute(carpeta)
	return correcto


static func permisos() -> bool:
	return Cuentas.puede_crear("admin", "admin") and Cuentas.puede_crear("admin", "jefe") \
		and Cuentas.puede_crear("jefe", "tecnico") and not Cuentas.puede_crear("jefe", "jefe") \
		and not Cuentas.puede_crear("jefe", "admin") and not Cuentas.puede_crear("tecnico", "tecnico")
