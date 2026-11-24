extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)

static func comprobar(base: String) -> bool:
	var menu := Pantallas.abrir(base)
	var ahora := int(Time.get_unix_time_from_system())
	var avance := Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", menu.perfil.id,
		"diagnostico", [], 0, ahora)
	menu.actualizar()
	menu.botones.ruta.pressed.emit()
	var correcto: bool = avance.guardado and menu.pantalla != null
	if correcto:
		var pantalla: Node = menu.pantalla
		correcto = pantalla.detalle.text.contains("Microlección 1 de 3") \
			and pantalla.detalle.text.contains("Fuente de prueba") \
			and Pantallas.responder(pantalla, 6) and pantalla.detalle.text.contains("Prioridad actualizada")
	var estado := Recorrido.estado(base, menu.perfil.id, ahora)
	var filas: Variant = Registro.leer(base, "T-85")
	menu.free()
	return correcto and filas.size() == 6 and estado.siguiente == "escenario" \
		and estado.microlecciones_hechas == 3 and estado.ruta.size() == 4
