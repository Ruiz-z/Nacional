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
		# La ruta es solo el mapa: sin preguntas ni opciones; «Continuar» cierra el paso.
		correcto = pantalla.mapa_pendiente and pantalla.roadmap_caja.visible and pantalla.opciones.get_child_count() == 0 \
			and pantalla.enviar.text == "Continuar" and pantalla.enviar.is_visible_in_tree() \
			and not pantalla.desplazamiento.is_ancestor_of(pantalla.enviar) and not pantalla.progreso.visible \
			and pantalla.fuente.text.is_empty() and pantalla.item.is_empty()
		pantalla.enviar.pressed.emit()
		correcto = correcto and pantalla.guardado and menu.get_node("Marco").visible and not menu.get_node("Marco/Volver").visible
	var estado := Recorrido.estado(base, menu.perfil.id, ahora)
	var filas: Variant = Registro.leer(base, menu.perfil.alias)
	menu.free()
	return correcto and filas.is_empty() and estado.siguiente == "escenario" \
		and estado.microlecciones_hechas == 0 and estado.ruta.size() == 4
