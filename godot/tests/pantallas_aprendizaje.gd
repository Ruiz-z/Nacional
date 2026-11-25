extends RefCounted

const Menu = preload("res://escenas/menu.tscn")
const Cuentas = preload("res://logica/flujo/cuentas.gd")
const Contrasena = preload("res://logica/flujo/contrasena.gd")
const Banco = preload("res://logica/competencias/banco.gd")

static func abrir(base: String) -> Node:
	var menu := Menu.instantiate()
	menu.base = base
	menu.banco_aprendizaje = banco()
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	entrar(menu)
	return menu


static func preparar_cuenta(menu: Node, usuario: String, clave: String, rol: String) -> Dictionary:
	var anteriores := Contrasena.iteraciones_actuales
	Contrasena.iteraciones_actuales = 200
	var cuenta := Cuentas.crear(menu.base, usuario, rol, clave)
	if not Cuentas.hay_admin(menu.base):
		Cuentas.crear(menu.base, "admin-prueba", "admin", Contrasena.temporal())
	Contrasena.iteraciones_actuales = anteriores
	menu.mostrar_ingreso()
	menu.usuario.text = usuario
	menu.clave.text = clave
	return cuenta


static func entrar(menu: Node, usuario := "tecnico01", clave := "clave-de-prueba", rol := "tecnico") -> bool:
	var cuenta := preparar_cuenta(menu, usuario, clave, rol)
	menu.enviar.pressed.emit()
	return cuenta.ok and menu.perfil.get("id") == cuenta.id


static func banco() -> Dictionary:
	var items := []
	var fuente := {"titulo": "Fuente de prueba", "referencia": "Colección de pruebas"}
	for competencia in Banco.COMPETENCIAS:
		for dificultad in ["facil", "media", "dificil"]:
			for numero in range(2):
				items.append({"id": "%s-%s-%d" % [competencia, dificultad, numero],
					"competencia": competencia, "dificultad": dificultad, "version": "1",
					"formato": "opcion-multiple", "pregunta": "Pregunta de prueba",
					"opciones": ["Acierto de prueba", "Error de prueba"], "correcta": 0,
					"fuente": fuente, "muestra": true})
	for numero in range(2):
		items.append({"id": "panel-%d" % numero, "formato": "accion-panel",
			"competencia": "seguridad-alto-voltaje", "dificultad": "facil", "version": "1",
			"instruccion": "Activa el bloqueo simulado.", "fuente": fuente,
			"secuencia_esperada": [{"ctrl": "bloqueo", "valor": 1}]})
		items.append({"id": "caso-%d" % numero, "formato": "caso-diagnostico",
			"competencia": "diagnostico-fallas", "dificultad": "media", "version": "1",
			"sintomas": ["Síntoma de prueba"], "codigo_falla": "Prueba", "fuente": fuente,
			"ruta_ideal": ["leer"], "pasos": [{"id": "leer", "accion": "Leer",
				"resultado": "Leído", "tipo_error": "orden-incorrecto"}]})
	return {"items": items, "errores": [], "avisos": []}


static func responder(pantalla: Node, cantidad: int, fallar_primera := false) -> bool:
	empezar(pantalla)
	for indice in range(cantidad):
		if pantalla.item.is_empty():
			return false
		match pantalla.item.formato:
			"opcion-multiple":
				pantalla.opciones.get_child(1 if fallar_primera and indice == 0 else 0).pressed.emit()
			"accion-panel":
				pantalla.opciones.get_child(0).get_node("Bloqueo").button_pressed = true
				pantalla.enviar.pressed.emit()
			"caso-diagnostico":
				pantalla.opciones.get_child(0).pressed.emit()
				pantalla.enviar.pressed.emit()
	pantalla.enviar.pressed.emit()
	return pantalla.guardado


# En la ruta el mapa se ve primero; «Empezar» abre las preguntas.
static func empezar(pantalla: Node) -> Variant:
	if pantalla.get("mapa_pendiente") == true:
		pantalla.enviar.pressed.emit()
	return null
