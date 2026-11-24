extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")
const Bus = preload("res://escenas/bus.tscn")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var bus := Bus.instantiate()
	bus.tecnico = Alias.alta(base, "T-58").merged({"base": base})
	(Engine.get_main_loop() as SceneTree).root.add_child(bus)
	var lateral := bus.get_node("Interfaz/Lateral")
	bus.ejecutar("inspeccionar", "teclado")
	lateral.get_node("Causa").select(2)
	lateral.get_node("Causa").item_selected.emit(2)
	var acciones: OptionButton = lateral.get_node("Accion")
	bus.abrir_menu(bus.get_node("Sector").piezas.monitor)
	acciones.select(1)
	bus.panel.get_node("Confirmar").pressed.emit()
	bus.abrir_menu(bus.get_node("Sector").piezas.bateria)
	acciones.select(1)
	bus.panel.recibir(JSON.stringify({"v": 1, "n": 2, "t": Time.get_ticks_msec() + 100, "ctrl": "confirmar", "valor": 1}), "virtual", Time.get_ticks_msec() + 100)
	var correcto: bool = bus.motor.estado().indicio_confirmado and bus.motor.brechas().size() == 1
	correcto = correcto and bus.resultados_guardados
	var brechas: Variant = Base.consultar(base, "SELECT causa_marcada FROM brecha;")
	var intentos: Variant = Base.consultar(base, "SELECT tipo_error FROM intento WHERE tipo_error = 'diagnostico-vs-accion';")
	correcto = correcto and brechas == [{"causa_marcada": "aviso-inconsistente"}] \
		and intentos == [{"tipo_error": "diagnostico-vs-accion"}]
	bus.free()
	return correcto
