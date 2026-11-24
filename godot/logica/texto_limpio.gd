extends RefCounted

const MUESTRA := "[MUESTRA]"
const DEMO := "[DEMO]"


static func limpiar(texto: String) -> Dictionary:
	var etiquetas := PackedStringArray()
	if texto.contains(MUESTRA):
		etiquetas.append("Ejemplo didáctico")
	if texto.contains(DEMO):
		etiquetas.append("Demo")
	var limpio := texto.replace(MUESTRA, "").replace(DEMO, "")
	return {"texto": limpio.replace("  ", " ").strip_edges(), "etiqueta": " · ".join(etiquetas)}


static func linea(texto: String) -> String:
	var dato := limpiar(texto)
	return dato.texto if dato.etiqueta.is_empty() else dato.etiqueta + "\n" + dato.texto


static func fuente(texto: String) -> String:
	var dato := limpiar(texto)
	if texto.contains(MUESTRA):
		for prefijo in ["valor de ejemplo", "procedimiento didáctico"]:
			if dato.texto.begins_with(prefijo):
				return "ejemplo didáctico" + dato.texto.trim_prefix(prefijo)
	return dato.texto.trim_suffix(" (página pública)").replace(" — ", ". ").replace(";", ".")
