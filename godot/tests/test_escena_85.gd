extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)

static func comprobar(base: String) -> bool:
	var menu := Pantallas.abrir(base)
	menu.botones.diagnostico.pressed.emit()
	if menu.pantalla == null or menu.pantalla.item.is_empty():
		menu.free()
		return false
	menu.pantalla.opciones.get_child(0).pressed.emit()
	menu.volver()
	var correcto: bool = Registro.leer(base, menu.perfil.alias) == [] and menu.botones.ruta.disabled
	menu.botones.diagnostico.pressed.emit()
	correcto = correcto and menu.pantalla.actividad.intentos.is_empty() \
		and Pantallas.responder(menu.pantalla, 10, true)
	var filas: Variant = Registro.leer(base, menu.perfil.alias)
	correcto = correcto and filas.size() == 10 and filas[1].dificultad == "facil" \
		and filas[8].formato == "accion-panel" and filas[8].resultado == "correcto" \
		and filas[9].formato == "caso-diagnostico" and filas[9].resultado == "correcto"
	menu.volver()
	correcto = correcto and not menu.botones.ruta.disabled
	menu.free()
	return correcto
