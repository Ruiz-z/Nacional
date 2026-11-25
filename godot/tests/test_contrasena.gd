extends RefCounted

const Contrasena = preload("res://logica/flujo/contrasena.gd")


static func ejecutar() -> bool:
	return vectores() and hash_y_verificacion() and revision() and temporal() and rendimiento()


# Vectores conocidos de PBKDF2-HMAC-SHA256 (clave «password», sal «salt»).
static func vectores() -> bool:
	var clave := "password".to_utf8_buffer()
	var sal := "salt".to_utf8_buffer()
	return Contrasena.pbkdf2(clave, sal, 1).hex_encode() == "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" \
		and Contrasena.pbkdf2(clave, sal, 2).hex_encode() == "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" \
		and Contrasena.pbkdf2(clave, sal, 4096).hex_encode() == "c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a"


static func hash_y_verificacion() -> bool:
	var uno := Contrasena.hash_de("clave-segura-1", 50)
	var otro := Contrasena.hash_de("clave-segura-1", 50)
	var partes := uno.split("$")
	return partes.size() == 4 and partes[0] == "pbkdf2-sha256" and partes[1] == "50" \
		and partes[2].length() == 32 and partes[3].length() == 64 \
		and not uno.contains("clave-segura-1") and uno != otro \
		and Contrasena.verificar("clave-segura-1", uno) and Contrasena.verificar("clave-segura-1", otro) \
		and not Contrasena.verificar("clave-segura-2", uno) and not Contrasena.verificar("", uno) \
		and not Contrasena.verificar("x", "") and not Contrasena.verificar("x", "pbkdf2-sha256$abc$00$00") \
		and not Contrasena.verificar("x", "otro$5$00$00") and not Contrasena.verificar("x", "pbkdf2-sha256$0$00$00") \
		and Contrasena.verificar("contraseña ñandú", Contrasena.hash_de("contraseña ñandú", 10))


static func revision() -> bool:
	return Contrasena.revisar("corta").contains("al menos 8") \
		and Contrasena.revisar("x".repeat(129)).contains("128") \
		and Contrasena.revisar(" con-espacios ").contains("espacios") \
		and Contrasena.revisar("una clave larga").is_empty()


static func temporal() -> bool:
	var vistas := {}
	for _i in range(40):
		var clave := Contrasena.temporal()
		if clave.length() != 12 or not Contrasena.revisar(clave).is_empty():
			return false
		for letra in clave:
			if not Contrasena.ALFABETO_TEMPORAL.contains(letra):
				return false
		vistas[clave] = true
	return vistas.size() == 40


# Con las iteraciones reales, un ingreso debe tardar menos de un segundo.
static func rendimiento() -> bool:
	var inicio := Time.get_ticks_msec()
	var guardado := Contrasena.hash_de("clave-de-medicion", Contrasena.ITERACIONES)
	var correcto := Contrasena.verificar("clave-de-medicion", guardado)
	var ms := Time.get_ticks_msec() - inicio
	print("PBKDF2 %d iteraciones: hash + verificación en %d ms." % [Contrasena.ITERACIONES, ms])
	return correcto and ms < 3000
