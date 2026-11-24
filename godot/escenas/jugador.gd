extends CharacterBody3D

const Movimiento = preload("res://logica/simulador/movimiento.gd")

var activo := true
var entrada: RefCounted
var teclas := {}
var mover_stick := false
var mirar_stick := false
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camara: Camera3D = $Camara


func configurar(traductor: RefCounted) -> void:
	entrada = traductor
	for tecla in [KEY_W, KEY_A, KEY_S, KEY_D]:
		var accion: Array = entrada.buscar_asignacion("teclado", OS.get_keycode_string(tecla))
		if accion.size() > 1 and accion[0] == "mover":
			teclas[accion[1]] = tecla
	mover_stick = entrada.buscar_asignacion("control", "stick-izquierdo") == ["mover"]
	mirar_stick = entrada.buscar_asignacion("control", "stick-derecho") == ["mirar"]


func _unhandled_input(evento: InputEvent) -> void:
	if activo and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and evento is InputEventMouseMotion:
		if entrada != null and entrada.traducir("teclado", "raton", evento.relative).get("accion") == "mirar":
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
