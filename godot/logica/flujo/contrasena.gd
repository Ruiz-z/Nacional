extends RefCounted

# Contraseñas con PBKDF2-HMAC-SHA256. Godot no trae PBKDF2, así que se arma con Crypto.hmac_digest.
# El texto guardado es «pbkdf2-sha256$iteraciones$sal$hash» en hexadecimal; la contraseña nunca se guarda.
const ALGORITMO := "pbkdf2-sha256"
const ITERACIONES := 100000
const LARGO_SAL := 16
const MINIMO := 8
const MAXIMO := 128
# Las pruebas bajan este valor para no esperar; la aplicación usa ITERACIONES.
static var iteraciones_actuales := ITERACIONES
const ALFABETO_TEMPORAL := "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"


static func pbkdf2(clave: PackedByteArray, sal: PackedByteArray, iteraciones: int) -> PackedByteArray:
	var cripto := Crypto.new()
	var bloque := cripto.hmac_digest(HashingContext.HASH_SHA256, clave, sal + PackedByteArray([0, 0, 0, 1]))
	var resultado := bloque.duplicate()
	for _i in range(iteraciones - 1):
		bloque = cripto.hmac_digest(HashingContext.HASH_SHA256, clave, bloque)
		for indice in range(resultado.size()):
			resultado[indice] = resultado[indice] ^ bloque[indice]
	return resultado


static func hash_de(clave: String, iteraciones: int = 0) -> String:
	if iteraciones <= 0:
		iteraciones = iteraciones_actuales
	var sal := Crypto.new().generate_random_bytes(LARGO_SAL)
	var derivado := pbkdf2(clave.to_utf8_buffer(), sal, iteraciones)
	return "%s$%d$%s$%s" % [ALGORITMO, iteraciones, sal.hex_encode(), derivado.hex_encode()]


static func verificar(clave: String, guardado: String) -> bool:
	# HMAC no admite clave vacía; una contraseña vacía nunca es válida.
	if clave.is_empty():
		return false
	var partes := guardado.split("$")
	if partes.size() != 4 or partes[0] != ALGORITMO or not partes[1].is_valid_int():
		return false
	var iteraciones := partes[1].to_int()
	if iteraciones < 1 or iteraciones > 5000000 or partes[2].is_empty() or partes[3].is_empty():
		return false
	var derivado := pbkdf2(clave.to_utf8_buffer(), partes[2].hex_decode(), iteraciones)
	return Crypto.new().constant_time_compare(derivado, partes[3].hex_decode())


# Texto de error en español claro, o vacío si la contraseña sirve.
static func revisar(clave: String) -> String:
	if clave.length() < MINIMO:
		return "La contraseña debe tener al menos %d caracteres." % MINIMO
	if clave.length() > MAXIMO:
		return "La contraseña no puede pasar de %d caracteres." % MAXIMO
	if clave.strip_edges() != clave:
		return "La contraseña no puede empezar ni terminar con espacios."
	return ""


# Contraseña temporal de 12 caracteres sin letras ni números que se confundan (0/O, 1/l/I).
static func temporal() -> String:
	var cripto := Crypto.new()
	var limite := 256 - 256 % ALFABETO_TEMPORAL.length()
	var texto := ""
	while texto.length() < 12:
		for octeto in cripto.generate_random_bytes(24):
			if octeto < limite and texto.length() < 12:
				texto += ALFABETO_TEMPORAL[octeto % ALFABETO_TEMPORAL.length()]
	return texto
