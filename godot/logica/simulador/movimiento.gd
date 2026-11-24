extends RefCounted

const VELOCIDAD := 3.0
const RADIO := 0.30
const MINIMO := Vector2(-18.28, -10.88)
const MAXIMO := Vector2(18.28, 21.0)


static func velocidad(direccion: Vector2, giro: float) -> Vector3:
	var eje := direccion.limit_length()
	return Vector3(eje.x, 0, eje.y).rotated(Vector3.UP, giro) * VELOCIDAD


static func limitar(posicion: Vector3) -> Vector3:
	return Vector3(clampf(posicion.x, MINIMO.x + RADIO, MAXIMO.x - RADIO), posicion.y,
		clampf(posicion.z, MINIMO.y + RADIO, MAXIMO.y - RADIO))


static func cabeceo(angulo: float) -> float:
	return clampf(angulo, deg_to_rad(-85.0), deg_to_rad(85.0))
