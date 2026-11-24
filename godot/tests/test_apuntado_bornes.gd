extends RefCounted


const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")


static func ejecutar() -> bool:
	var casos := [
		["", "", "tp0", "Poner la punta negra aquí (TP0)"],
		["", "", "tp1", "La punta negra va en TP0."],
		["", "", "tp2", "La punta negra va en TP0."],
		["tp0", "", "tp1", "Poner la punta roja aquí (TP1)"],
		["tp0", "", "tp2", "Poner la punta roja aquí (TP2)"],
		["tp0", "", "tp0", "La punta negra ya está aquí (TP0)"],
		["tp0", "tp1", "tp1", "La punta roja ya está aquí (TP1)"],
		["tp0", "tp2", "tp2", "La punta roja ya está aquí (TP2)"],
		["tp0", "tp1", "tp2", "Mover la punta roja aquí (TP2)"],
		["tp0", "tp2", "tp1", "Mover la punta roja aquí (TP1)"],
		["tp0", "tp1", "tp0", "La punta negra ya está aquí (TP0)"],
		["tp1", "tp0", "tp0", "La punta negra va en TP0."],
		["tp1", "tp0", "tp1", "La punta negra va en TP0."],
		["tp1", "tp0", "tp2", "La punta negra va en TP0."],
	]
	for caso in casos:
		var texto: String = Mediciones.texto_apuntado(caso[0], caso[1], caso[2])
		if texto != caso[3]:
			printerr("Apuntado con negra «%s» y roja «%s» a %s: %s" % [caso[0], caso[1], caso[2], texto])
			return false
	return true
