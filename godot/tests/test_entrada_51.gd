extends RefCounted

static func ejecutar() -> bool:
	var conexion := load("res://logica/entrada/conexion_panel.gd").new() as RefCounted
	var latido := '{"v":1,"ctrl":"hb"}'
	var control := '{"v":1,"ctrl":"bloqueo","valor":1,"n":0,"t":0}'
	if conexion.fuente_panel() != "virtual" or conexion.pausado():
		return false
	conexion.iniciar_panel(100)
	if conexion.fuente_panel() != "panel" or conexion.recibir(control, "panel", 101).is_empty():
		return false
	conexion.recibir(latido, "panel", 1100)
	conexion.recibir(latido, "virtual", 2100)
	conexion.recibir('{"v":2,"ctrl":"hb"}', "panel", 3000)
	conexion.actualizar(4099)
	if conexion.pausado() or conexion.fuente_panel() != "panel":
		return false
	conexion.recibir(latido, "panel", 4100)
	if not conexion.pausado() or conexion.fuente_panel() != "virtual" or conexion.aviso().is_empty():
		return false
	if not conexion.recibir(control, "virtual", 4101).is_empty():
		return false
	conexion.reanudar()
	if conexion.pausado() or conexion.recibir(control, "virtual", 4102).is_empty():
		return false
	conexion.iniciar_panel(4200)
	return conexion.fuente_panel() == "panel" and not conexion.recibir(control, "panel", 4201).is_empty()
