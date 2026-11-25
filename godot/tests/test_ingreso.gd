extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Menu = preload("res://escenas/menu.tscn")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const CLAVE := "clave-de-prueba"


static func ejecutar() -> bool:
	var anterior := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var correcto := Base.con_base(comprobar)
	Contrasena.iteraciones_actuales = anterior
	return correcto


static func enviar(menu: Node, usuario: String, clave: String) -> void:
	menu.usuario.text = usuario
	menu.clave.text = clave
	menu.clave.text_submitted.emit(clave)


static func cerrar_aviso(menu: Node) -> void:
	menu.aviso.get_ok_button().pressed.emit()


static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	var correcto := recorrido(menu, base)
	menu.free()
	return correcto


static func recorrido(menu: Node, base: String) -> bool:
	if menu.etapa != "primer-admin" or Cuentas.hay_admin(base):
		return false
	menu.repeticion.text = "corta"
	enviar(menu, "admin01", "corta")
	if menu.aviso == null or not menu.aviso.visible or Cuentas.hay_admin(base):
		return false
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	menu.aviso.push_input(escape)
	if menu.aviso.visible:
		return false
	menu.repeticion.text = CLAVE
	enviar(menu, "admin01", CLAVE)
	if not Cuentas.hay_admin(base) or menu.perfil.get("rol") != "admin":
		return false
	menu.barra.get_child(-1).pressed.emit()
	if menu.etapa != "ingreso" or not menu.perfil.is_empty() or not menu.usuario.text.is_empty():
		return false
	menu.demo_boton.pressed.emit()
	if menu.pantalla == null or not menu.perfil.is_empty():
		return false
	menu.pantalla.get_node("Tablero").pressed.emit()
	if menu.pantalla.vista != "jefe" or menu.pantalla.base == base:
		return false
	menu.volver()
	for intento in range(5):
		enviar(menu, "admin01", "incorrecta")
		if menu.aviso == null or not menu.aviso.visible or not menu.perfil.is_empty():
			return false
		if intento < 4 and menu.enviar.disabled:
			return false
		cerrar_aviso(menu)
	if not menu.enviar.disabled or not menu.enviar.text.contains("30"):
		return false
	enviar(menu, "admin01", CLAVE)
	if not menu.perfil.is_empty():
		return false
	Base.consultar(base, "UPDATE tecnico SET bloqueado_hasta = 0 WHERE alias = 'admin01';")
	menu.espera_hasta = Time.get_ticks_msec() - 1
	menu._process(0)
	enviar(menu, "admin01", CLAVE)
	if menu.perfil.get("rol") != "admin":
		return false
	menu.cerrar_sesion()
	if not Cuentas.crear(base, "tecnico01", "tecnico", CLAVE, true).ok:
		return false
	enviar(menu, "tecnico01", CLAVE)
	if menu.etapa != "cambio" or not menu.perfil.is_empty() \
			or not menu.botones.values().all(func(boton: Button) -> bool: return boton.disabled):
		return false
	menu.clave.text = "clave-nueva"
	menu.repeticion.text = "clave-nueva"
	menu.enviar.pressed.emit()
	var ingreso := Cuentas.entrar(base, "tecnico01", "clave-nueva", menu.ahora())
	return menu.perfil.get("rol") == "tecnico" and ingreso.ok and not ingreso.cambiar_clave
