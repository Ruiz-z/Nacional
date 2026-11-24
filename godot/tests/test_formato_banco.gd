extends RefCounted


static func ejecutar() -> bool:
	var ruta := ProjectSettings.globalize_path("res://").path_join("../contenido/banco.json")
	if not FileAccess.file_exists(ruta):
		return false
	var banco: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not banco is Dictionary or banco.competencias.size() != 4 or banco.items.is_empty():
		return false
	var ids := []
	for competencia in banco.competencias:
		if competencia.nombre.is_empty():
			return false
		ids.append(competencia.id)
	if ids != ["seguridad-alto-voltaje", "sistema-electrico-bateria",
			"diagnostico-fallas", "electronica-conectividad"]:
		return false
	return banco.items[0].has_all(["id", "competencia", "formato", "dificultad",
		"criticidad", "fuente", "muestra", "version"])
