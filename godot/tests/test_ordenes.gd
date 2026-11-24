extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")


static func ejecutar() -> bool:
	var ordenes := load("res://logica/simulador/ordenes.gd") as GDScript
	if ordenes == null:
		return false
	var listado: Dictionary = ordenes.listar()
	var esperadas := {
		"aislamiento": ["gabinete", "FG3"], "comunicacion": ["cabina", "FG3"],
		"modulo_auxiliar": ["banco", "FG3"], "faros": ["faros", "FG3"], "motor": ["motor", "FG2"],
		"neumatico_pinchado": ["bajos", "FG7"], "tuercas_rueda_flojas": ["bajos", "FG7"],
		"fuga_suspension_neumatica": ["bajos", "FG7"], "amortiguador_danado": ["bajos", "FG7"],
		"freno_desgastado": ["bajos", "FG5"],
	}
	for orden in listado.ordenes:
		var id: String = orden.archivo.get_file().get_basename()
		if esperadas.get(id) != [orden.zona, orden.grupo_funcion]:
			return false
		esperadas.erase(id)
		if orden.titulo.begins_with("[MUESTRA]") or orden.competencia.is_empty():
			return false
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	for invalido in ["FG10", "FG 3", 3, null]:
		datos.grupo_funcion = invalido
		var errores: Array = Escenario.validar(datos, "prueba.json").errores
		if errores.size() != 1 or not errores[0].contains("grupo_funcion"):
			return false
	datos.grupo_funcion = "FG3"
	datos.zona = "taller"
	return listado.errores.is_empty() and esperadas.is_empty() \
		and not Escenario.validar(datos, "prueba.json").errores.is_empty()
