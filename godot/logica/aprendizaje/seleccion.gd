extends RefCounted

# Orden de las preguntas candidatas por técnico. Sin semilla (0) queda el orden del banco; con semilla, cada
# técnico ve un orden distinto pero estable: abrir la misma prueba dos veces da las mismas preguntas.
# El campo `grupo` agrupa preguntas del mismo tema: en una prueba no se repite un grupo si hay alternativa.


static func barajar(items: Array, semilla: int) -> Array:
	if semilla == 0:
		return items
	var copia := items.duplicate()
	copia.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return clave(a, semilla) < clave(b, semilla))
	return copia


# SHA-256 y no String.hash(): el hash rápido de Godot conserva el orden de ids que solo difieren al final.
static func clave(item: Dictionary, semilla: int) -> int:
	return ("%d:%s" % [semilla, item.get("id", "")]).sha256_text().left(12).hex_to_int()


static func grupo_de(item: Dictionary) -> String:
	return str(item.get("grupo", ""))


# Primera pregunta del formato cuyo grupo aún no se usó; si todas repiten grupo, la primera del formato.
static func elegir(candidatas: Array, formato: String, grupos_usados: Array, excluidos: Array = []) -> Dictionary:
	var primera := {}
	for item in candidatas:
		if item.formato != formato or item.id in excluidos:
			continue
		if primera.is_empty():
			primera = item
		var grupo := grupo_de(item)
		if grupo.is_empty() or grupo not in grupos_usados:
			return item.duplicate(true)
	return primera.duplicate(true)


static func recordar(grupos_usados: Array, item: Dictionary) -> void:
	var grupo := grupo_de(item)
	if not grupo.is_empty() and grupo not in grupos_usados:
		grupos_usados.append(grupo)
