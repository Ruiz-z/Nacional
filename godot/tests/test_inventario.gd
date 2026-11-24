extends RefCounted


static func ejecutar() -> bool:
	var guion := load("res://logica/simulador/inventario.gd") as GDScript
	if guion == null:
		return false
	var inventario: RefCounted = guion.new()
	for id in ["foco", "destornillador", "fusible_correcto", "multimetro"]:
		if inventario.tomar(id) != "":
			return false
	if inventario.tomar("foco", true).is_empty() or inventario.tomar("calzas").is_empty():
		return false
	for id in ["calzas", "lampara", "flexometro", "manometro"]:
		if inventario.tomar(id, true) != "":
			return false
	if inventario.tomar("abrazadera", true).is_empty():
		return false
	var requiere := {"herramientas": ["lampara", "destornillador"], "piezas": ["foco"]}
	if inventario.faltantes(requiere) != ["lampara"] or not inventario.faltantes(requiere, true).is_empty():
		return false
	inventario.consumir(requiere)
	if inventario.faltantes(requiere, true) != ["foco"]:
		return false
	if inventario.dejar("lampara").is_empty() or inventario.dejar("lampara", true) != "":
		return false
	inventario.reiniciar()
	return inventario.cinturon.is_empty() and inventario.carrito.is_empty()
