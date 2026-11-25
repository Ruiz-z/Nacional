extends RefCounted

# Cuentas con usuario, contraseña y rol. La columna `alias` de la tabla `tecnico` guarda el usuario.
const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")

const ROLES := ["tecnico", "jefe", "admin"]
const NOMBRES_ROL := {"tecnico": "Técnico", "jefe": "Jefe directo", "admin": "Admin"}
const FALLOS_PARA_BLOQUEO := 5
const ESPERA_BASE_S := 30
const MENSAJE_INVALIDO := "Usuario o contraseña incorrectos."
const FORMATO_USUARIO := "^[a-z0-9][a-z0-9._-]{2,23}$"
# Hash de una contraseña inexistente: se verifica igual cuando el usuario no existe, para no dar pistas por el tiempo.
const HASH_SENUELO := "pbkdf2-sha256$100000$00000000000000000000000000000000$0000000000000000000000000000000000000000000000000000000000000000"


static func normalizar(entrada: String) -> String:
	return entrada.strip_edges().to_lower()


# Texto de error en español claro, o vacío si el usuario sirve.
static func revisar_usuario(entrada: String) -> String:
	var usuario := normalizar(entrada)
	if RegEx.create_from_string(FORMATO_USUARIO).search(usuario) == null:
		return "El usuario debe tener entre 3 y 24 caracteres: letras minúsculas, números, punto, guion o guion bajo. No uses tu nombre real."
	return ""


static func hay_admin(base: String, consultar: Callable = Acceso.consultar) -> bool:
	var filas: Variant = consultar.call(base,
		"SELECT count(*) AS total FROM tecnico WHERE rol = 'admin' AND clave_hash <> '' AND demo = 0;")
	return filas is Array and not filas.is_empty() and int(filas[0].total) > 0


# El admin crea cualquier rol; el jefe directo solo técnicos; el técnico no crea cuentas.
static func puede_crear(rol_actor: String, rol_nuevo: String) -> bool:
	return rol_actor == "admin" or (rol_actor == "jefe" and rol_nuevo == "tecnico")


# `temporal` pide cambiar la contraseña en el primer ingreso. No comprueba permisos: usa puede_crear antes.
static func crear(base: String, usuario: String, rol: String, clave: String, temporal := false,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var error_usuario := revisar_usuario(usuario)
	if not error_usuario.is_empty():
		return error(error_usuario)
	if rol not in ROLES:
		return error("Ese rol no existe.")
	var error_clave := Contrasena.revisar(clave)
	if not error_clave.is_empty():
		return error(error_clave)
	var filas: Variant = consultar.call(base, """
		INSERT INTO tecnico (alias, rol, clave_hash, cambiar_clave) VALUES (?, ?, ?, ?)
		ON CONFLICT(alias) DO NOTHING RETURNING id, alias, rol;
	""", [normalizar(usuario), rol, Contrasena.hash_de(clave), 1 if temporal else 0])
	if filas == null:
		return error("No se pudo crear la cuenta. Intenta de nuevo.")
	if filas.is_empty():
		return error("Ese usuario ya existe. Elige otro.")
	return {"ok": true, "id": int(filas[0].id), "alias": filas[0].alias, "rol": filas[0].rol}


# Devuelve {ok, id, alias, rol, cambiar_clave}. Tras 5 fallos seguidos hay que esperar; la espera crece.
static func entrar(base: String, usuario: String, clave: String, ahora: int,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var filas: Variant = consultar.call(base, """
		SELECT id, alias, rol, clave_hash, cambiar_clave, fallos, bloqueado_hasta
		FROM tecnico WHERE alias = ? AND demo = 0;
	""", [normalizar(usuario)])
	if filas == null:
		return error("No se pudo comprobar tu cuenta. Intenta de nuevo.")
	if filas.is_empty() or filas[0].clave_hash == "":
		Contrasena.verificar(clave, HASH_SENUELO)
		return error(MENSAJE_INVALIDO)
	var fila: Dictionary = filas[0]
	var espera := int(fila.bloqueado_hasta) - ahora
	if espera > 0:
		return {"ok": false, "bloqueado": true, "espera_s": espera,
			"mensaje": "Demasiados intentos. Espera %d s para volver a probar." % espera}
	if not Contrasena.verificar(clave, fila.clave_hash):
		var fallos := int(fila.fallos) + 1
		var hasta := 0
		if fallos % FALLOS_PARA_BLOQUEO == 0:
			hasta = ahora + ESPERA_BASE_S * (fallos / FALLOS_PARA_BLOQUEO)
		consultar.call(base, "UPDATE tecnico SET fallos = ?, bloqueado_hasta = ? WHERE id = ?;",
			[fallos, hasta, int(fila.id)])
		return error(MENSAJE_INVALIDO)
	consultar.call(base, "UPDATE tecnico SET fallos = 0, bloqueado_hasta = 0 WHERE id = ?;", [int(fila.id)])
	return {"ok": true, "id": int(fila.id), "alias": fila.alias, "rol": fila.rol,
		"cambiar_clave": int(fila.cambiar_clave) == 1}


# El técnico cambia su contraseña; desaparece la marca de contraseña temporal.
static func cambiar_clave(base: String, id: int, clave_nueva: String,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var error_clave := Contrasena.revisar(clave_nueva)
	if not error_clave.is_empty():
		return error(error_clave)
	var filas: Variant = consultar.call(base, """
		UPDATE tecnico SET clave_hash = ?, cambiar_clave = 0, fallos = 0, bloqueado_hasta = 0
		WHERE id = ? AND demo = 0 RETURNING id;
	""", [Contrasena.hash_de(clave_nueva), id])
	if filas == null or filas.is_empty():
		return error("No se pudo cambiar la contraseña.")
	return {"ok": true}


# Quien administra restablece una contraseña: devuelve la temporal, que se muestra una sola vez.
static func restablecer(base: String, id: int, consultar: Callable = Acceso.consultar) -> Dictionary:
	var temporal := Contrasena.temporal()
	var filas: Variant = consultar.call(base, """
		UPDATE tecnico SET clave_hash = ?, cambiar_clave = 1, fallos = 0, bloqueado_hasta = 0
		WHERE id = ? AND demo = 0 RETURNING id;
	""", [Contrasena.hash_de(temporal), id])
	if filas == null or filas.is_empty():
		return error("No se pudo restablecer la contraseña.")
	return {"ok": true, "temporal": temporal}


# Lista para la pantalla de administración. «heredada»: cuenta anterior a las contraseñas, no puede entrar.
static func listar(base: String, consultar: Callable = Acceso.consultar) -> Array:
	var filas: Variant = consultar.call(base, """
		SELECT id, alias, rol, clave_hash, cambiar_clave, creado FROM tecnico WHERE demo = 0 ORDER BY rol, alias;
	""")
	if filas == null:
		return []
	return filas.map(func(fila: Dictionary) -> Dictionary: return {
		"id": int(fila.id), "alias": fila.alias, "rol": fila.rol, "creado": fila.creado,
		"heredada": fila.clave_hash == "", "cambiar_clave": int(fila.cambiar_clave) == 1})


static func error(mensaje: String) -> Dictionary:
	return {"ok": false, "mensaje": mensaje}
