extends RefCounted

const Formato = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Prueba = preload("res://tests/escenario_prueba.gd")

static func ejecutar() -> bool:
	var ruta := ProjectSettings.globalize_path("res://").path_join("../contenido/escenarios/aislamiento.json")
	var resultado := Formato.cargar(ruta)
	if not resultado.errores.is_empty():
		printerr(resultado.errores)
		return false
	var datos: Dictionary = resultado.escenario
	if datos.fuente != Prueba.FUENTE or not datos.muestra or datos.eventos.size() != 3:
		return false
	var ideal := Motor.new(datos)
	for id in datos.ruta_ideal:
		if not ideal.ejecutar(id, "teclado", 1).aplicada:
			return false
	if ideal.fin() != "resuelto" or ideal.puntaje() != 100:
		return false
	var practica := Motor.new(datos)
	practica.ejecutar("inspeccionar", "teclado", 1)
	for par in [["forzar_pieza", "reponer_pieza"], ["elegir_otro_sector", "volver_al_sector"],
			["descartar_indicio", "recuperar_indicio"]]:
		if not practica.ejecutar(par[0], "virtual", 1).aplicada:
			return false
		if not practica.recuperaciones_disponibles().has(par[1]) \
				or not practica.ejecutar(par[1], "virtual", 1).aplicada:
			return false
	for id in ["evaluar_indicio", "confirmar_solucion"]:
		if not practica.ejecutar(id, "virtual", 1).aplicada:
			return false
	return practica.fin() == "resuelto" and practica.puntaje() < 100
