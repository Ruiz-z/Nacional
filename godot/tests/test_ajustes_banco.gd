extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Mediciones = preload("res://logica/simulador/mediciones_arnes.gd")


static func ejecutar() -> bool:
	var datos: Dictionary = Escenario.cargar("escenarios/modulo_auxiliar.json").escenario
	if not datos.has("briefing") or datos.get("ubicacion_inicial") != {"multimetro": "mesa_banco"}:
		return false
	if not Escenario.indicios_validos(datos):
		return false
	var misiones: Array = datos.indicios.filter(func(indicio: Dictionary) -> bool: return indicio.has("mision"))
	if misiones.map(func(indicio: Dictionary) -> String: return indicio.mision) != [
		"Mide TP1 y TP2 con el multímetro", "Anota las lecturas en la hoja", "Repara: reconecta el conductor"]:
		return false
	if datos.briefing.como != [
		"Toma el multímetro de la mesa, mide TP1 y TP2 contra TP0, anota las lecturas en la hoja y repara."]:
		return false
	var mision: Dictionary = datos.indicios[4]
	if Escenario.mision_cumplida(mision, {"tp1_medido": true}) \
			or not Escenario.mision_cumplida(mision, {"tp1_medido": true, "tp2_medido": true}):
		return false
	for claves in [[], ["tp1_medido", "tp1_medido"], ["tp1_medido", "tp3_medido"]]:
		mision.claves = claves
		if Escenario.indicios_validos(datos):
			return false
	for ubicacion in [[], {"multimetro": "caja_azul"}, {"llave_ajustable": "mesa_banco"}]:
		if Escenario.ubicacion_valida(ubicacion, "banco"):
			return false
	for como in ["Mide.", [], ["Mide.", 5], ["A.", "B.", "C.", "D."]]:
		if Escenario.briefing_valido(datos.briefing.merged({"como": como}, true)):
			return false
	var mediciones := Mediciones.new()
	if mediciones.tocar("tp1") != "" or mediciones.aviso_puntas != "La punta negra va en TP0.":
		return false
	if mediciones.puntas() != ["", ""]:
		return false
	mediciones.tocar("tp0")
	if mediciones.tocar("tp2") != "medir_tp2" or mediciones.puntas() != ["tp0", "tp2"]:
		return false
	if mediciones.tocar("tp0") != "" or mediciones.tocar("tp2") != "" \
			or mediciones.puntas() != ["tp0", "tp2"]:
		return false
	if mediciones.tocar("tp1") != "medir_tp1" or mediciones.puntas() != ["tp0", "tp1"]:
		return false
	mediciones.tocar("")
	return mediciones.puntas() == ["", ""]
