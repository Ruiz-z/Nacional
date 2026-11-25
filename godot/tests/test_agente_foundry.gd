extends RefCounted

const RutaIA = preload("res://logica/aprendizaje/ruta_ia.gd")


static func ejecutar() -> bool:
	var ruta := ProjectSettings.globalize_path("res://../foundry/agente-ruta.yaml")
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return false

	var yaml := archivo.get_as_text().replace("\r\n", "\n")
	# El archivo usa un bloque literal indentado para las instrucciones.
	var bloque := RegEx.create_from_string("(?m)^instructions: \\|[-+]?[ \\t]*\\n((?: +[^\\n]*\\n)+)")
	var instrucciones := bloque.search(yaml)
	var nombre := RegEx.create_from_string("(?m)^name: +ruta-aprendizaje[ \\t]*$")
	var herramientas := RegEx.create_from_string("(?m)^tools: +\\[\\s*\\][ \\t]*$")
	var espacios := RegEx.create_from_string("\\s+")
	return instrucciones != null \
		and nombre.search(yaml) != null and herramientas.search(yaml) != null \
		and espacios.sub(instrucciones.get_string(1).strip_edges(), " ", true) \
			== espacios.sub(RutaIA.INSTRUCCION.strip_edges(), " ", true)
