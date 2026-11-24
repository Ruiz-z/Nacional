extends CharacterBody3D

const Movimiento = preload("res://logica/simulador/movimiento.gd")

const Brazos = preload("res://assets/modelos/manos/arms_low_poly.fbx")
const Llave = preload("res://assets/modelos/herramientas/adjustable_wrench.glb")
const Flexometro = preload("res://assets/modelos/herramientas/tape_measure.glb")

var activo := true
var entrada: RefCounted
var teclas := {}
var mover_stick := false
var mirar_stick := false
var mirar_raton := false
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camara: Camera3D = $Camara

var herramientas := {}


func _ready() -> void:
	var brazos := Brazos.instantiate() as Node3D
	brazos.position = Vector3(0, -0.47, -0.49)
	brazos.rotation_degrees = Vector3(-5, 180, 0)
	brazos.scale = Vector3.ONE * 0.27
	camara.add_child(brazos)

	var mano := Node3D.new()
	mano.position = Vector3(0.15, -0.32, -0.65)
	camara.add_child(mano)
	var llave := Llave.instantiate() as Node3D
	llave.scale = Vector3.ONE * 0.75
	llave.position.z = -0.035
	llave.rotation_degrees.y = -14
	mano.add_child(llave)
	var flexometro := Flexometro.instantiate() as Node3D
	flexometro.position.z = -0.03
	flexometro.rotation_degrees = Vector3(-25, 15, 0)
	mano.add_child(flexometro)

	var multimetro := Node3D.new()
	multimetro.rotation_degrees = Vector3(-12, 0, -12)
	multimetro.position.z = -0.055
	mano.add_child(multimetro)
	pieza_multimetro(multimetro, Vector3.ZERO, Vector3(0.083, 0.035, 0.135), Color("#edbb31"))
	pieza_multimetro(multimetro, Vector3(0, 0.019, -0.023), Vector3(0.057, 0.005, 0.041), Color("#365448"))
	for lado in [-1, 1]:
		var color := Color("#d13931") if lado == 1 else Color("#292a2e")
		pieza_multimetro(multimetro, Vector3(lado * 0.026, 0, -0.085), Vector3(0.012, 0.012, 0.048), color)
		pieza_multimetro(multimetro, Vector3(lado * 0.026, 0, -0.114), Vector3(0.004, 0.004, 0.022), Color.SILVER)

	herramientas = {"llave": llave, "flexometro": flexometro, "multimetro": multimetro}
	for malla in camara.find_children("*", "MeshInstance3D", true, false):
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mostrar_herramienta("")


func pieza_multimetro(padre: Node3D, centro: Vector3, tam: Vector3, color: Color) -> void:
	var pieza := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tam
	pieza.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	pieza.material_override = material
	pieza.position = centro
	padre.add_child(pieza)


func mostrar_herramienta(accion: String) -> void:
	herramientas.llave.visible = accion in ["apretar", "apretar_terminal", "reponer_pieza"]
	herramientas.flexometro.visible = accion in ["medir", "inspeccionar"]
	herramientas.multimetro.visible = accion == "evaluar_indicio"


func configurar(traductor: RefCounted) -> void:
	entrada = traductor
	for tecla in [KEY_W, KEY_A, KEY_S, KEY_D]:
		var accion: Array = entrada.buscar_asignacion("teclado", OS.get_keycode_string(tecla))
		if accion.size() > 1 and accion[0] == "mover":
			teclas[accion[1]] = tecla
	mover_stick = entrada.buscar_asignacion("control", "stick-izquierdo") == ["mover"]
	mirar_stick = entrada.buscar_asignacion("control", "stick-derecho") == ["mirar"]
	mirar_raton = entrada.buscar_asignacion("teclado", "raton") == ["mirar"]


func _input(evento: InputEvent) -> void:
	# El movimiento del ratón no pasa por el filtro anti-rebote de la entrada: se consulta el mapeo una vez.
	if activo and mirar_raton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and evento is InputEventMouseMotion:
		mirar(evento.relative * 0.003)


func mirar(giro: Vector2) -> void:
	rotation.y = wrapf(rotation.y - giro.x, -PI, PI)
	camara.rotation.x = Movimiento.cabeceo(camara.rotation.x - giro.y)


func _physics_process(delta: float) -> void:
	var direccion := Vector2.ZERO
	if activo and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		direccion = Vector2(eje_tecla("derecha") - eje_tecla("izquierda"),
			eje_tecla("atras") - eje_tecla("adelante"))
		var mandos := Input.get_connected_joypads()
		if not mandos.is_empty():
			var mando := mandos[0]
			if mover_stick:
				direccion += stick(mando, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
			if mirar_stick:
				mirar(stick(mando, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y) * delta * 2.3)
	var horizontal := Movimiento.velocidad(direccion, rotation.y)
	velocity = Vector3(horizontal.x, 0.0 if is_on_floor() else velocity.y - gravedad * delta,
		horizontal.z)
	move_and_slide()
	var limitada := Movimiento.limitar(position)
	if limitada != position:
		position = limitada


func eje_tecla(direccion: String) -> float:
	return float(teclas.has(direccion) and Input.is_physical_key_pressed(teclas[direccion]))


func stick(mando: int, eje_x: JoyAxis, eje_y: JoyAxis) -> Vector2:
	var vector := Vector2(Input.get_joy_axis(mando, eje_x), Input.get_joy_axis(mando, eje_y))
	return vector.normalized() * clampf((vector.length() - 0.2) / 0.8, 0.0, 1.0)
