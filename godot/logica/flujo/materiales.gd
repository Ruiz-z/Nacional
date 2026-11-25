extends RefCounted

# Enlace a la página local de materiales. Solo jefe directo y admin reciben el permiso de autor; el técnico
# abre la misma página sin permiso y la página le muestra únicamente los materiales revisados.
const PUERTO := 8765
const ARCHIVO_TOKEN := "web/.token-autor"
const ROLES_AUTOR := ["jefe", "admin"]


static func base_url() -> String:
	return "http://127.0.0.1:%d" % PUERTO


# Dirección que abre el navegador. Con permiso pasa por /acceso, que guarda una cookie y quita el token de la barra.
static func url(rol: String, token: String, usuario: String = "", ruta: String = "") -> String:
	if rol in ROLES_AUTOR and not token.strip_edges().is_empty():
		var direccion := "%s/acceso?token=%s" % [base_url(), token.strip_edges().uri_encode()]
		# Quien revisa un material queda registrado con su cuenta, no con un texto libre.
		return direccion + ("&usuario=" + usuario.uri_encode() if not usuario.is_empty() else "")
	# El técnico entra sin permiso de autor, pero con su ruta para recibir primero lo que le toca.
	if rol == "tecnico" and not usuario.is_empty():
		var direccion := "%s/acceso?usuario=%s" % [base_url(), usuario.uri_encode()]
		return direccion + ("&ruta=" + ruta.uri_encode() if not ruta.is_empty() else "")
	return base_url()


# «competencia~dominio.competencia~dominio», de la más urgente a la menos urgente.
static func texto_ruta(ruta: Array, dominios: Dictionary) -> String:
	var partes := PackedStringArray()
	for competencia in ruta:
		if competencia is String and dominios.has(competencia):
			partes.append("%s~%d" % [competencia, roundi(dominios[competencia])])
	return ".".join(partes)


static func leer_token(raiz: String) -> String:
	var archivo := FileAccess.open(raiz.path_join(ARCHIVO_TOKEN), FileAccess.READ)
	return "" if archivo == null else archivo.get_as_text().strip_edges()
