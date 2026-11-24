extends RefCounted

const Protocolo = preload("res://logica/entrada/protocolo.gd")

static func ejecutar() -> bool:
	var ruta := ProjectSettings.globalize_path("res://").path_join("../docs/protocolo-panel.md")
	var documento := FileAccess.get_file_as_string(ruta)
	var protocolo := Protocolo.new()
	var controles := []
	var leds := []
	var en_json := false
	for linea in documento.split("\n"):
		if linea == "```json":
			en_json = true
		elif linea == "```":
			en_json = false
		elif en_json:
			var ejemplo: Variant = JSON.parse_string(linea)
			if not ejemplo is Dictionary:
				return false
			if ejemplo.has("led"):
				if ejemplo.get("v") != Protocolo.VERSION or ejemplo.get("valor") != 1:
					return false
				leds.append(ejemplo.led)
			else:
				var evento := protocolo.recibir(linea)
				if evento.is_empty():
					return false
				controles.append(evento.ctrl)
	return controles == Protocolo.CONTROLES + ["hb"] \
		and leds == ["energizado", "bloqueado", "falla"] and protocolo.errores().is_empty()
