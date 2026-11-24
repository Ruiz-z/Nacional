extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)

static func comprobar(base: String) -> bool:
	var menu := Pantallas.abrir(base)
	var correcto := recorrido(menu, base)
	menu.free()
	return correcto


static func recorrido(menu: Node, base: String) -> bool:
	var ahora := int(Time.get_unix_time_from_system())
	var tecnico: int = menu.perfil.id
	menu.botones.diagnostico.pressed.emit()
	if not Pantallas.responder(menu.pantalla, 10):
		return false
	menu.volver()
	if not Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", tecnico, "ruta", [], 3, ahora).guardado:
		return false
	menu.actualizar()
	menu.botones.escenario.pressed.emit()
	var tarjetas: Node = menu.pantalla.get_node("Centro/Columna/Tarjetas")
	var elegida := false
	for tarjeta in tarjetas.get_children():
		if tarjeta.text.contains("Cabina"):
			tarjeta.pressed.emit()
			elegida = true
			break
	if not elegida:
		return false
	var bus: Node = menu.pantalla
	if bus.archivo.get_file() != "comunicacion.json" or bus.datos.id != "comunicacion":
		return false
	bus.abrir_menu(bus.get_node("Sector").piezas.terminal)
	if bus.menu_pieza.visible or bus.motor.estado().sintomas_revisados:
		return false
	bus.cerrar_menu()
	for accion in bus.datos.ruta_ideal:
		bus.ejecutar(accion, "teclado")
	menu.volver()
	if menu.botones.post.disabled:
		return false
	menu.botones.post.pressed.emit()
	if not Pantallas.responder(menu.pantalla, 10):
		return false
	menu.volver()
	menu.botones.retest.pressed.emit()
	if not menu.pantalla.aviso.text.contains("7 día") or not menu.pantalla.item.is_empty():
		return false
	menu.volver()
	if not Reloj.adelantar(base, tecnico, 7):
		return false
	menu.botones.retest.pressed.emit()
	if not Pantallas.responder(menu.pantalla, 10):
		return false
	menu.volver()
	var por_momento := {"pre": [], "post": [], "retest": []}
	for fila in Registro.leer(base, "T-85"):
		if por_momento.has(fila.momento):
			por_momento[fila.momento].append(fila.item)
	return por_momento.post.size() == 10 and por_momento.post == por_momento.retest \
		and por_momento.post.all(func(id: String) -> bool: return id not in por_momento.pre) \
		and not menu.botones.tablero.disabled
