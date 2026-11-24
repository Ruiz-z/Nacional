extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")


static func ejecutar() -> bool:
	var ordenes := load("res://logica/simulador/ordenes.gd") as GDScript
	if ordenes == null:
		return false
	var listado: Dictionary = ordenes.listar()
	var zonas := {}
	for orden in listado.ordenes:
		zonas[orden.archivo.get_file()] = orden.zona
		if orden.titulo.begins_with("[MUESTRA]") or orden.competencia.is_empty():
			return false
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	datos.zona = "taller"
	return listado.errores.is_empty() and zonas.get("aislamiento.json") == "gabinete" \
		and zonas.get("comunicacion.json") == "cabina" \
		and zonas.size() == 5 and zonas.get("modulo_auxiliar.json") == "banco" and zonas.get("faros.json") == "faros" and zonas.get("motor.json") == "motor" \
		and not Escenario.validar(datos, "prueba.json").errores.is_empty()
