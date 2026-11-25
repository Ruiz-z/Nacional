extends "res://escenas/graficas/grafica_base.gd"

const FILA := 46
const ESCALA := [Color("#21383e"), Color("#22474e"), Color("#24565d"), Color("#27636a"), Color("#286e74")]


func _get_minimum_size() -> Vector2:
	return Vector2(0, 28 + datos.get("filas", []).size() * FILA)


func dibujar() -> void:
	var izquierda := minf(240, size.x * 0.28)
	var ancho: float = (size.x - izquierda) / datos.columnas.size()
	for j in datos.columnas.size():
		rotulo(datos.columnas[j], Rect2(izquierda + j * ancho + 2, 0, ancho - 4, 26), SUAVE,
			HORIZONTAL_ALIGNMENT_CENTER)
	for i in datos.filas.size():
		var fila: Dictionary = datos.filas[i]
		var y: int = 28 + i * FILA
		rotulo(fila.nombre, Rect2(4, y + 1, izquierda - 10, 22))
		rotulo(fila.detalle, Rect2(4, y + 22, izquierda - 10, 21), SUAVE)
		for j in fila.valores.size():
			var valor: Variant = fila.valores[j]
			var rect := Rect2(izquierda + j * ancho + 1, y + 1, ancho - 2, FILA - 2)
			var color: Color = Color("#263136") if valor == null else ESCALA[mini(4, int(valor / 20.0))]
			draw_rect(rect, color)
			rotulo(valor_visible(valor, " %"), rect, TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
			marca(rect, fila, j)
