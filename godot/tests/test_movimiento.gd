extends RefCounted


static func ejecutar() -> bool:
	var movimiento := load("res://logica/simulador/movimiento.gd") as GDScript
	if movimiento == null:
		return false
	return movimiento.velocidad(Vector2(0, -1), PI / 2).is_equal_approx(Vector3(-3, 0, 0)) \
		and is_equal_approx(movimiento.velocidad(Vector2(1, 1), 0).length(), 3.0) \
		and movimiento.limitar(Vector3(40, 0.2, -30)).is_equal_approx(Vector3(17.98, 0.2, -10.58)) \
		and is_equal_approx(movimiento.cabeceo(PI), deg_to_rad(85.0))
