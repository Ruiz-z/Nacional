extends RefCounted

# Equipo de protección personal: qué exige cada orden antes de empezar a trabajar.
# Los requisitos salen de la zona de la orden y se pueden afinar con el campo "epp" del escenario.

const FUENTE := "[MUESTRA] criterio didáctico de seguridad, sin fuente oficial"
const COMPETENCIA := "seguridad-alto-voltaje"

const CATALOGO := {
	"casco": {"nombre": "Casco de seguridad", "grupo": "cabeza"},
	"gafas": {"nombre": "Gafas de seguridad", "grupo": "ojos"},
	"careta": {"nombre": "Careta facial contra arco", "grupo": "rostro"},
	"guantes_dielectricos": {"nombre": "Guantes dieléctricos", "grupo": "manos"},
	"guantes_trabajo": {"nombre": "Guantes de trabajo", "grupo": "manos"},
	"calzado_dielectrico": {"nombre": "Calzado dieléctrico", "grupo": "pies"},
	"botas": {"nombre": "Botas con casquillo", "grupo": "pies"},
	"chaleco": {"nombre": "Chaleco reflectante", "grupo": "cuerpo"},
	"proteccion_auditiva": {"nombre": "Protección auditiva", "grupo": "oídos"},
}

const ALTO_VOLTAJE := ["guantes_dielectricos", "calzado_dielectrico", "careta", "gafas"]
const BAJO_VEHICULO := ["casco", "botas", "gafas", "guantes_trabajo"]

const POR_ZONA := {
	"motor": ALTO_VOLTAJE,
	"gabinete": ALTO_VOLTAJE,
	"bajos": BAJO_VEHICULO,
	"faros": ["gafas", "botas", "guantes_trabajo"],
	"banco": ["gafas", "botas"],
	"cabina": ["botas", "chaleco"],
}

const MOTIVOS := {
	"casco": "Protege la cabeza de golpes con el chasis y las piezas bajo el autobús.",
	"gafas": "Protegen los ojos de chispas, líquidos y partículas.",
	"careta": "Protege el rostro de un arco eléctrico al abrir equipos de alto voltaje.",
	"guantes_dielectricos": "Aíslan tus manos del alto voltaje. Revísalos antes de ponértelos.",
	"guantes_trabajo": "Protegen las manos de cortes, bordes y piezas calientes.",
	"calzado_dielectrico": "Aísla tus pies del suelo si hay una fuga de alto voltaje.",
	"botas": "Protegen los pies de caídas de piezas y herramientas.",
	"chaleco": "Te hace visible cuando hay maniobras de autobuses en el taller.",
	"proteccion_auditiva": "Reduce el ruido de herramientas neumáticas y del motor en marcha.",
}


static func ids() -> Array[String]:
	var lista: Array[String] = []
	for id in CATALOGO:
		lista.append(id)
	return lista


static func nombre(id: String) -> String:
	return CATALOGO.get(id, {}).get("nombre", id)


static func valido(requeridos: Variant) -> bool:
	if not requeridos is Array or requeridos.is_empty():
		return false
	for id in requeridos:
		if not id is String or not CATALOGO.has(id) or requeridos.count(id) != 1:
			return false
	return true


# EPP que exige la orden: el campo "epp.requeridos" del escenario o, si falta, el de su zona.
static func requeridos(escenario: Dictionary) -> Array[String]:
	var lista: Array = POR_ZONA.get(escenario.get("zona", ""), ["botas"])
	var propio: Variant = escenario.get("epp", {}).get("requeridos") if escenario.get("epp") is Dictionary else null
	if valido(propio):
		lista = propio
	var resultado: Array[String] = []
	for id in lista:
		resultado.append(id)
	return resultado


# Equipo que se ofrece en el vestidor: lo exigido más señuelos, siempre en el mismo orden estable.
static func ofrecidos(escenario: Dictionary) -> Array[String]:
	var exigidos := requeridos(escenario)
	var resto: Array[String] = []
	for id in CATALOGO:
		if id not in exigidos:
			resto.append(id)
	# Cada orden muestra tres señuelos distintos, elegidos por su id para que no cambien entre intentos.
	var llave := str(escenario.get("id", ""))
	resto.sort_custom(func(a: String, b: String) -> bool:
		return (llave + a).sha256_text() < (llave + b).sha256_text())
	var lista: Array[String] = exigidos.duplicate()
	lista.append_array(resto.slice(0, 3))
	lista.sort_custom(func(a: String, b: String) -> bool:
		return (llave + "o" + a).sha256_text() < (llave + "o" + b).sha256_text())
	return lista


static func evaluar(escenario: Dictionary, elegidos: Array) -> Dictionary:
	var exigidos := requeridos(escenario)
	var faltantes: Array[String] = []
	var sobrantes: Array[String] = []
	for id in exigidos:
		if id not in elegidos:
			faltantes.append(id)
	for id in elegidos:
		if id is String and CATALOGO.has(id) and id not in exigidos and id not in sobrantes:
			sobrantes.append(id)
	return {"completo": faltantes.is_empty(), "faltantes": faltantes, "sobrantes": sobrantes}


static func resumen_riesgo(escenario: Dictionary) -> String:
	match escenario.get("zona", ""):
		"motor", "gabinete":
			return "Vas a abrir un equipo de alto voltaje."
		"bajos":
			return "Vas a trabajar bajo un autobús elevado."
		"faros":
			return "Vas a manipular el circuito eléctrico de los faros."
		"banco":
			return "Vas a medir en un banco de pruebas electrónico."
	return "Vas a revisar el autobús en el taller."
