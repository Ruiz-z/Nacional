extends RefCounted

const VELOCIDAD := 3.0
const RADIO := 0.30
const FACTOR_CORRER := 1.7
const FACTOR_AGACHADO := 0.5
const SALTO := 3.7
const ALTURA_OJOS := 1.7
const ALTURA_OJOS_AGACHADO := 1.15
const MINIMO := Vector2(-18.28, -10.88)
const MAXIMO := Vector2(18.28, 21.0)
const TALLER := Rect2(MINIMO, MAXIMO - MINIMO)


# Agacharse manda sobre correr: quien va agachado camina despacio.
static func factor(correr: bool, agachado: bool) -> float:
	if agachado:
		return FACTOR_AGACHADO
	return FACTOR_CORRER if correr else 1.0


static func velocidad(direccion: Vector2, giro: float, multiplicador := 1.0) -> Vector3:
	var eje := direccion.limit_length()
	return Vector3(eje.x, 0, eje.y).rotated(Vector3.UP, giro) * VELOCIDAD * multiplicador


static func limitar(posicion: Vector3, limites := TALLER) -> Vector3:
	return Vector3(clampf(posicion.x, limites.position.x + RADIO, limites.end.x - RADIO), posicion.y,
		clampf(posicion.z, limites.position.y + RADIO, limites.end.y - RADIO))


static func cabeceo(angulo: float) -> float:
	return clampf(angulo, deg_to_rad(-85.0), deg_to_rad(85.0))
