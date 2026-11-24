extends RefCounted

static func ejecutar() -> bool:
	var ruta = load("res://logica/aprendizaje/ruta.gd")
	if ruta == null:
		return false
	var seguridad := "seguridad-alto-voltaje"
	var bateria := "sistema-electrico-bateria"
	var fallas := "diagnostico-fallas"
	var dominios := {seguridad: 70, bateria: 40, fallas: 95}
	var brecha := {"competencia": fallas, "sesion": 4, "tipo_error": "diagnostico-vs-accion", "valor": 0}
	var critica := {"competencia": seguridad, "sesion": 2, "tipo_error": "falta-critica", "valor": 0}
	var acierto := {"competencia": seguridad, "sesion": 4, "resultado": "correcto", "valor": 100}
	return ruta.ordenar(dominios, [], 4) == [bateria, seguridad, fallas] \
		and ruta.ordenar(dominios, [brecha], 4)[0] == bateria \
		and ruta.ordenar(dominios, [brecha, brecha], 4)[0] == fallas \
		and ruta.ordenar(dominios, [critica, brecha, brecha], 4)[0] == seguridad \
		and ruta.ordenar(dominios, [critica, brecha, brecha, acierto], 4)[0] == fallas \
		and ruta.ordenar(dominios, [critica, brecha, brecha], 5)[0] == seguridad \
		and not ruta.aprobada(70, true) and ruta.aprobada(70, false)
