extends RefCounted

const Escena = preload("res://escenas/panel_virtual.tscn")


static func ejecutar() -> bool:
	var panel := Escena.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)
	var acciones := []
	panel.accion_recibida.connect(func(accion: Dictionary): acciones.append(accion))
	panel.get_node("Bloqueo").toggled.emit(true)
	panel.get_node("Etiquetado").toggled.emit(true)
	panel.get_node("Torque").value = 42
	panel.get_node("AplicarTorque").pressed.emit()
	panel.get_node("Confirmar").pressed.emit()
	panel.get_node("Cancelar").pressed.emit()
	panel.mostrar_leds({"energizado": true, "bloqueado": false, "falla": true})
	var correcto: bool = acciones.size() == 5 and acciones[2] == {
		"accion": "torque", "valor": 42.0, "fuente_entrada": "virtual"}
	correcto = correcto and panel.entrada.registro().size() == 5
	correcto = correcto and panel.get_node("Energizado").text.ends_with("encendido")
	correcto = correcto and panel.get_node("Bloqueado").text.ends_with("apagado")
	panel.free()
	return correcto
