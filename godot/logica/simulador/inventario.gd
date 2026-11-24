extends RefCounted

const CAPACIDAD := 4
const CATALOGO := {
	"tech_tool": {"nombre": "Tech Tool", "tipo": "herramienta", "espacio": 1},
	"llave_ajustable": {"nombre": "Llave ajustable", "tipo": "herramienta", "espacio": 1},
	"destornillador": {"nombre": "Destornillador", "tipo": "herramienta", "espacio": 1},
	"multimetro": {"nombre": "Multímetro", "tipo": "herramienta", "espacio": 1},
	"manometro": {"nombre": "Manómetro de neumáticos", "tipo": "herramienta", "espacio": 1},
	"llave_torque": {"nombre": "Llave de torque", "tipo": "herramienta", "espacio": 1},
	"flexometro": {"nombre": "Flexómetro", "tipo": "herramienta", "espacio": 1},
	"lampara": {"nombre": "Lámpara", "tipo": "herramienta", "espacio": 1},
	"calzas": {"nombre": "Calzas", "tipo": "herramienta", "espacio": 1},
	"foco": {"nombre": "Foco de repuesto", "tipo": "pieza", "espacio": 1},
	"fusible_correcto": {"nombre": "Fusible correcto", "tipo": "pieza", "espacio": 1},
	"fusible_equivocado": {"nombre": "Fusible equivocado", "tipo": "pieza", "espacio": 1},
	"abrazadera": {"nombre": "Abrazadera", "tipo": "pieza", "espacio": 1},
	"tuercas": {"nombre": "Tuercas de rueda", "tipo": "pieza", "espacio": 1},
	"bolsa_aire": {"nombre": "Bolsa de aire", "tipo": "pieza", "espacio": 2},
	"amortiguador": {"nombre": "Amortiguador", "tipo": "pieza", "espacio": 2},
	"neumatico": {"nombre": "Neumático", "tipo": "pieza", "espacio": 3},
	"pastillas_freno": {"nombre": "Pastillas de freno", "tipo": "pieza", "espacio": 1},
}

var cinturon: Array[String] = []
var carrito: Array[String] = []


static func objeto(id: String) -> Dictionary:
	return CATALOGO.get(id, {}).merged({"id": id}) if CATALOGO.has(id) else {}


static func requisitos_validos(requiere: Variant) -> bool:
	if not requiere is Dictionary:
		return false
	var tipos := {"herramientas": "herramienta", "piezas": "pieza"}
	if requiere.has("herramienta") and (requiere.has("herramientas")
			or not requiere.herramienta is String
			or objeto(requiere.herramienta).get("tipo") != "herramienta"):
		return false
	for grupo in requiere:
		if grupo == "herramienta":
			continue
		if not tipos.has(grupo) or not requiere[grupo] is Array:
			return false
		for id in requiere[grupo]:
			if not id is String or not CATALOGO.has(id) \
					or CATALOGO[id].tipo != tipos[grupo] or requiere[grupo].count(id) != 1:
				return false
	return true


static func espacio(almacen: Array[String]) -> int:
	var total := 0
	for id in almacen:
		total += CATALOGO[id].espacio
	return total


static func libres(almacen: Array[String]) -> int:
	return CAPACIDAD - espacio(almacen)


static func cantidad_espacios(cantidad: int) -> String:
	return "%d espacio%s" % [cantidad, "" if cantidad == 1 else "s"]


func accesibles(cerca := false) -> Array[String]:
	return cinturon + carrito if cerca else cinturon.duplicate()


func tomar(id: String, cerca := false) -> String:
	if not CATALOGO.has(id):
		return "Ese objeto no está disponible. Elige otro."
	if id in cinturon or id in carrito:
		return "Ya llevas %s." % CATALOGO[id].nombre
	var carga: int = CATALOGO[id].espacio
	if carga <= libres(cinturon):
		cinturon.append(id)
	elif cerca and carga <= libres(carrito):
		carrito.append(id)
	else:
		var quedan := libres(cinturon)
		var nombre: String = CATALOGO[id].nombre
		if id == "bolsa_aire":
			nombre = "La " + nombre
		return "%s ocupa %s y en el cinturón te queda%s %d." % [
			nombre, cantidad_espacios(carga), "" if quedan == 1 else "n", quedan]
	return ""


func dejar(id: String, cerca := false) -> String:
	if id not in accesibles(cerca):
		return "No alcanzas ese objeto. Acércate para tomarlo."
	cinturon.erase(id)
	carrito.erase(id)
	return ""


func faltantes(requiere: Dictionary, cerca := false) -> Array[String]:
	var disponibles := accesibles(cerca)
	var resultado: Array[String] = []
	var herramienta: String = requiere.get("herramienta", "")
	if not herramienta.is_empty() and herramienta not in disponibles:
		resultado.append(herramienta)
	for grupo in ["herramientas", "piezas"]:
		for id in requiere.get(grupo, []):
			if id not in disponibles:
				resultado.append(id)
	return resultado


func consumir(requiere: Dictionary, cerca := false) -> void:
	for id in requiere.get("piezas", []):
		if CATALOGO.get(id, {}).get("tipo") == "pieza":
			dejar(id, cerca)


func reiniciar() -> void:
	cinturon.clear()
	carrito.clear()
