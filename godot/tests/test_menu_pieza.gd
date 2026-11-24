extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")


static func ejecutar() -> bool:
	var menu := load("res://logica/simulador/menu_pieza.gd") as GDScript
	if menu == null:
		return false
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	var motor := Motor.new(datos)
	var compuerta: Array = menu.entradas(motor, datos, "compuerta")
	if compuerta.size() != 1 or compuerta[0].id != "inspeccionar" or compuerta[0].requiere_panel:
		return false
	var regla: Dictionary = datos.acciones.inspeccionar
	regla.erase("requiere_panel")
	if menu.entradas(motor, datos, "compuerta")[0].requiere_panel:
		return false
	regla["requiere_panel"] = "false"
	if Escenario.validar(datos, "prueba.json").errores.is_empty():
		return false
	motor.ejecutar("inspeccionar", "teclado", 0)
	motor.ejecutar("forzar_pieza", "teclado", 0)
	var terminal: Array = menu.entradas(motor, datos, "terminal")
	return terminal.size() == 2 and not terminal[0].requiere_panel and terminal[1].id == "reponer_pieza" \
		and terminal[1].requiere_panel and not terminal[1].costo.is_empty() \
		and not terminal[1].tiempo.is_empty() and not terminal[1].riesgo.is_empty()
