extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")


static func ejecutar() -> bool:
	var seguro := {"bloqueo": true, "etiquetado": true}
	for zona in ["faros", "motor"]:
		var carga := Escenario.cargar("escenarios/%s.json" % zona)
		if not carga.errores.is_empty():
			printerr(carga.errores)
			return false
		var datos: Dictionary = carga.escenario
		var motor := Motor.new(datos)
		for id in datos.ruta_ideal:
			var fuente := "virtual" if datos.acciones[id].get("requiere_panel", false) else "teclado"
			if not motor.call("ejecutar", id, fuente, 0, seguro).aplicada:
				return false
		if motor.fin() != "resuelto" or motor.puntaje() != 100:
			return false
		var error_id := "reponer_fusible_equivocado" if zona == "faros" else "apretar_abrazadera"
		var evento := "fusible_quemado" if zona == "faros" else "pieza_danada"
		var recuperacion := "reponer_fusible" if zona == "faros" else "reponer_abrazadera"
		motor = Motor.new(datos)
		for id in datos.ruta_ideal.slice(0, -2):
			motor.call("ejecutar", id, "virtual", 0, seguro)
		if evento not in motor.call("ejecutar", error_id, "virtual", 0, seguro).eventos:
			return false
		if not motor.call("ejecutar", recuperacion, "virtual", 0, seguro).aplicada or motor.hay_problemas():
			return false
		if zona == "motor" and not comprobar_seguridad(datos, seguro):
			return false
	return true


static func comprobar_seguridad(datos: Dictionary, seguro: Dictionary) -> bool:
	for controles in [{}, {"bloqueo": true}, {"etiquetado": true}]:
		var motor := Motor.new(datos)
		motor.ejecutar("inspeccionar", "teclado", 0)
		if motor.call("ejecutar", "bloquear_y_etiquetar", "virtual", 0, controles).aplicada:
			return false
		var decision: Dictionary = motor.call("ejecutar", "tocar_cables_naranja_sin_bloqueo", "teclado", 0, controles)
		if decision.tipo_error != "accion-insegura" or decision.criticidad != "critica" \
				or decision.motivo.is_empty() or decision.fuente.is_empty() or motor.fin() != "falta-critica":
			return false
	var motor := Motor.new(datos)
	motor.ejecutar("inspeccionar", "teclado", 0)
	return motor.call("ejecutar", "tocar_cables_naranja_sin_bloqueo", "teclado", 0, seguro).aplicada \
		and motor.fin().is_empty()
