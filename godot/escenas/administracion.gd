extends VBoxContainer

const UI = preload("res://escenas/cuenta_ui.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Permisos = preload("res://logica/tablero/permisos.gd")
const Resultados = preload("res://logica/tablero/resultados.gd")
const TextoLimpio = preload("res://logica/texto_limpio.gd")

var base := ""
var perfil := {}
var lista: GridContainer
var nueva: Button
var dialogo: AcceptDialog
var error_formulario: AcceptDialog
var usuario: LineEdit
var roles: OptionButton
var temporal_visible: LineEdit
var copiar: Button
var acciones := {}
var vacio: Label


func _ready() -> void:
	if not Cuentas.puede_crear(perfil.get("rol", ""), "tecnico"):
		add_child(UI.etiqueta("Tu cuenta no tiene acceso a Administración."))
		return
	var admin := Permisos.puede_administrar(perfil.rol)
	var cabecera := HBoxContainer.new()
	add_child(cabecera)
	var titulo := UI.etiqueta("Administración" if admin else "Nuevo técnico", &"Titulo")
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	if not admin:
		var formulario := VBoxContainer.new()
		formulario.custom_minimum_size.x = 420
		formulario.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_child(formulario)
		preparar_formulario(formulario)
		nueva = UI.boton("Crear cuenta", true)
		formulario.add_child(nueva)
		nueva.pressed.connect(crear_cuenta)
		usuario.grab_focus()
		return
	nueva = UI.boton("Nueva cuenta", true)
	nueva.pressed.connect(abrir_alta)
	cabecera.add_child(nueva)
	add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var datos := VBoxContainer.new()
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(datos)
	vacio = UI.etiqueta("", &"Secundario")
	datos.add_child(vacio)
	lista = GridContainer.new()
	lista.columns = 4
	lista.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lista.add_theme_constant_override("h_separation", 24)
	lista.add_theme_constant_override("v_separation", 10)
	datos.add_child(lista)
	actualizar()
	nueva.grab_focus()


func actualizar() -> void:
	if lista == null:
		return
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()
	acciones.clear()
	var cuentas := Cuentas.listar(base)
	vacio.text = "Aún no hay técnicos. Crea la primera cuenta con Nueva cuenta."
	vacio.visible = not cuentas.any(func(cuenta: Dictionary) -> bool: return cuenta.rol == "tecnico")
	for texto in ["Usuario", "Rol", "Estado", "Acciones"]:
		var columna := UI.etiqueta(texto, &"Metadato")
		columna.autowrap_mode = TextServer.AUTOWRAP_OFF
		lista.add_child(columna)
	for cuenta in cuentas:
		var nombre := UI.etiqueta(TextoLimpio.linea(cuenta.alias))
		nombre.autowrap_mode = TextServer.AUTOWRAP_OFF
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nombre.tooltip_text = nombre.text
		nombre.custom_minimum_size.x = 280
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lista.add_child(nombre)
		var nombre_rol := UI.etiqueta(Cuentas.NOMBRES_ROL.get(cuenta.rol, cuenta.rol))
		nombre_rol.autowrap_mode = TextServer.AUTOWRAP_OFF
		lista.add_child(nombre_rol)
		var estado := "Activa"
		if cuenta.heredada:
			estado = "Heredada, sin contraseña"
		elif cuenta.cambiar_clave:
			estado = "Cambiar contraseña pendiente"
		var estado_cuenta := UI.etiqueta(estado, &"Aviso" if estado != "Activa" else &"Secundario")
		estado_cuenta.autowrap_mode = TextServer.AUTOWRAP_OFF
		lista.add_child(estado_cuenta)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		lista.add_child(fila)
		var reset := UI.boton("Restablecer contraseña")
		reset.accessibility_description = "Usuario " + nombre.text
		reset.disabled = cuenta.heredada
		if reset.disabled:
			reset.tooltip_text = "Crea una cuenta nueva para sustituir una cuenta heredada."
		reset.pressed.connect(restablecer.bind(cuenta))
		fila.add_child(reset)
		var borrar := UI.boton("Borrar")
		borrar.accessibility_description = "Usuario " + nombre.text
		var impedimento := motivo_borrado(cuenta, cuentas)
		borrar.disabled = not impedimento.is_empty()
		borrar.tooltip_text = impedimento
		borrar.pressed.connect(confirmar_borrado.bind(cuenta))
		fila.add_child(borrar)
		acciones[cuenta.alias] = {"restablecer": reset, "borrar": borrar}


func motivo_borrado(cuenta: Dictionary, cuentas: Array) -> String:
	if not Permisos.puede_borrar(perfil.get("rol", "")):
		return "Tu cuenta no puede borrar usuarios."
	if cuenta.id == perfil.get("id", -1) or cuenta.alias == perfil.get("alias", ""):
		return "No puedes borrar tu propia cuenta."
	if cuenta.rol == "admin" and not cuenta.heredada:
		var admins := cuentas.filter(func(fila: Dictionary) -> bool: return fila.rol == "admin" and not fila.heredada)
		if admins.size() <= 1:
			return "Conserva al menos una cuenta de administración."
	return ""


func preparar_formulario(bloque: VBoxContainer) -> void:
	bloque.add_theme_constant_override("separation", 10)
	usuario = UI.campo(bloque, "Usuario")
	UI.texto_modal(bloque, "Usa de 3 a 24 caracteres. Evita tu nombre real.", &"Secundario")
	roles = OptionButton.new()
	UI.estilizar_boton(roles)
	if Permisos.puede_administrar(perfil.rol):
		UI.texto_modal(bloque, "Rol", &"Secundario")
		roles.accessibility_name = "Rol"
		roles.custom_minimum_size.y = 44
	else:
		roles.hide()
	bloque.add_child(roles)
	for rol in Cuentas.ROLES:
		if Cuentas.puede_crear(perfil.rol, rol):
			roles.add_item(Cuentas.NOMBRES_ROL[rol])
			roles.set_item_metadata(roles.item_count - 1, rol)
	usuario.text_submitted.connect(func(_texto: String): crear_cuenta())


func abrir_alta() -> void:
	dialogo = UI.modal(self)
	dialogo.ok_button_text = "Crear cuenta"
	dialogo.dialog_hide_on_ok = false
	var bloque := VBoxContainer.new()
	dialogo.add_child(bloque)
	UI.texto_modal(bloque, "Nueva cuenta", &"Seccion")
	preparar_formulario(bloque)
	UI.estilizar_boton(dialogo.add_cancel_button("Cancelar"))
	dialogo.confirmed.connect(crear_cuenta)
	dialogo.canceled.connect(dialogo.queue_free)
	dialogo.popup_centered(Vector2i(420, 0))
	usuario.grab_focus()


func crear_cuenta() -> void:
	if is_instance_valid(error_formulario) and error_formulario.visible:
		return
	var rol_actor: String = perfil.get("rol", "")
	var rol_nuevo: String = roles.get_item_metadata(roles.selected)
	if not Cuentas.puede_crear(rol_actor, rol_nuevo):
		return
	var temporal := Contrasena.temporal()
	var resultado := Cuentas.crear(base, usuario.text, rol_nuevo, temporal, true)
	if not resultado.ok:
		var padre: Control = usuario.get_parent()
		UI.marcar_error(usuario)
		error_formulario = UI.aviso(padre, resultado.mensaje, usuario)
		return
	usuario.clear()
	if is_instance_valid(dialogo):
		dialogo.hide()
		dialogo.queue_free()
	actualizar()
	mostrar_temporal(resultado.alias, temporal)


func restablecer(cuenta: Dictionary) -> void:
	if not Permisos.puede_administrar(perfil.get("rol", "")) or cuenta.heredada:
		return
	var resultado := Cuentas.restablecer(base, cuenta.id)
	if not resultado.ok:
		UI.aviso(self, resultado.mensaje)
		return
	actualizar()
	mostrar_temporal(cuenta.alias, resultado.temporal)


func mostrar_temporal(nombre: String, temporal: String) -> void:
	dialogo = UI.modal(self)
	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 12)
	dialogo.add_child(bloque)
	UI.texto_modal(bloque, "Contraseña temporal", &"Seccion")
	UI.texto_modal(bloque, "Comparte esta contraseña con %s. Al cerrar, dejará de mostrarse." % TextoLimpio.linea(nombre))
	UI.estilizar_boton(dialogo.get_ok_button())
	temporal_visible = UI.campo(bloque, "Contraseña temporal")
	temporal_visible.text = temporal
	temporal_visible.editable = false
	copiar = UI.boton("Copiar", true)
	copiar.pressed.connect(func():
		DisplayServer.clipboard_set(temporal_visible.text)
		copiar.text = "Copiada")
	bloque.add_child(copiar)
	dialogo.confirmed.connect(cerrar_temporal)
	dialogo.canceled.connect(cerrar_temporal)
	dialogo.popup_centered(Vector2i(420, 0))
	copiar.grab_focus()


func cerrar_temporal() -> void:
	temporal_visible.clear()
	dialogo.queue_free()
	if lista == null:
		usuario.grab_focus()
	else:
		nueva.grab_focus()


func confirmar_borrado(cuenta: Dictionary) -> void:
	if not motivo_borrado(cuenta, Cuentas.listar(base)).is_empty():
		return
	dialogo = UI.modal(self)
	dialogo.ok_button_text = "Borrar cuenta"
	var cancelar := dialogo.add_cancel_button("Cancelar")
	UI.estilizar_boton(cancelar)
	var bloque := VBoxContainer.new()
	dialogo.add_child(bloque)
	UI.texto_modal(bloque, "Borrar cuenta", &"Seccion")
	UI.texto_modal(bloque, "Se borrarán la cuenta %s y su progreso." % TextoLimpio.linea(cuenta.alias))
	dialogo.canceled.connect(dialogo.queue_free)
	dialogo.confirmed.connect(func():
		dialogo.queue_free()
		var cuentas := Cuentas.listar(base)
		var vigente := cuentas.filter(func(fila: Dictionary) -> bool: return fila.id == cuenta.id and fila.alias == cuenta.alias)
		if vigente.is_empty() or not motivo_borrado(vigente[0], cuentas).is_empty() \
				or not Resultados.borrar(base, cuenta.alias, true, perfil.rol):
			UI.aviso(self, "No se pudo borrar la cuenta. Actualiza la lista e intenta de nuevo.")
		actualizar()
		nueva.grab_focus())
	dialogo.popup_centered(Vector2i(420, 0))
	cancelar.grab_focus()
