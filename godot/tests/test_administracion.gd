extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Gestion = preload("res://escenas/administracion.tscn")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Texto = preload("res://tests/test_escena_64.gd")


static func ejecutar() -> bool:
	var anterior := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var correcto := Base.con_base(comprobar)
	Contrasena.iteraciones_actuales = anterior
	return correcto


static func comprobar(base: String) -> bool:
	var admin := Cuentas.crear(base, "admin01", "admin", "clave-de-prueba")
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('T-0001');")
	var gestion := Gestion.instantiate()
	gestion.base = base
	gestion.perfil = admin
	(Engine.get_main_loop() as SceneTree).root.add_child(gestion)
	var correcto := recorrido(gestion, base, admin)
	gestion.free()
	return correcto


static func recorrido(gestion: Node, base: String, admin: Dictionary) -> bool:
	if not gestion.acciones.admin01.borrar.disabled or not gestion.acciones["T-0001"].restablecer.disabled \
			or not Texto.leer(gestion).contains("Heredada, sin contraseña"):
		return false
	gestion.perfil = {"rol": "admin", "id": -1}
	if gestion.motivo_borrado(admin.merged({"heredada": false}), Cuentas.listar(base)).is_empty():
		return false
	gestion.perfil = admin
	gestion.nueva.pressed.emit()
	gestion.usuario.text = "tecnico01"
	gestion.usuario.text_submitted.emit("tecnico01")
	if not gestion.acciones.has("tecnico01") or not gestion.dialogo.visible:
		return false
	var temporal: String = gestion.temporal_visible.text
	var ingreso := Cuentas.entrar(base, "tecnico01", temporal, 1)
	if temporal.is_empty() or not ingreso.ok or not ingreso.cambiar_clave \
			or not Texto.leer(gestion).contains("Cambiar contraseña pendiente"):
		return false
	gestion.dialogo.hide()
	gestion.dialogo.confirmed.emit()
	if not gestion.temporal_visible.text.is_empty():
		return false
	gestion.acciones.tecnico01.restablecer.pressed.emit()
	var otra: String = gestion.temporal_visible.text
	if otra.is_empty() or otra == temporal or Cuentas.entrar(base, "tecnico01", temporal, 2).ok \
			or not Cuentas.entrar(base, "tecnico01", otra, 2).cambiar_clave:
		return false
	gestion.dialogo.hide()
	gestion.dialogo.canceled.emit()
	gestion.acciones.tecnico01.borrar.pressed.emit()
	gestion.dialogo.hide()
	gestion.dialogo.canceled.emit()
	if Cuentas.listar(base).size() != 3:
		return false
	gestion.acciones.tecnico01.borrar.pressed.emit()
	gestion.dialogo.hide()
	gestion.dialogo.confirmed.emit()
	return not gestion.acciones.has("tecnico01") and Cuentas.listar(base).size() == 2
