extends "res://escenas/graficas/grafica_base.gd"


func _get_minimum_size() -> Vector2:
	return Vector2(0, 24 + datos.get("columnas", []).size() * 25 + (25 if datos.get("tipo") == "medidor" else 0))


func color_segmento(i: int) -> Color:
	var colores: Array = datos.get("colores", [])
	return TONOS[i] if colores.is_empty() else Color(colores[i])


func dibujar() -> void:
	var fila: Dictionary = datos.filas[0]
	var total := 0
	for valor in fila.valores:
		total += int(valor)
	var x := 4.0
	var ancho := size.x - 8
	var partes: int = fila.valores.count(0)
	var disponible: float = ancho - (fila.valores.size() - partes - 1) * 2
	if datos.tipo == "medidor":
		barra(Rect2(4, 4, ancho, 16), Color("#31464c"))
	for i in fila.valores.size():
		var valor: int = fila.valores[i]
		var color := color_segmento(i)
		if valor > 0 and total > 0:
			var largo: float = disponible * valor / total
			barra(Rect2(x, 4, largo, 16), color, 4)
			marca(Rect2(x, 3, largo, 18), fila, i)
			x += largo + 2
		var y: int = 24 + i * 25
		draw_rect(Rect2(4, y + 7, 10, 10), color)
		rotulo("%s · %d" % [datos.columnas[i], valor], Rect2(23, y, size.x - 27, 24))
		marca(Rect2(4, y, size.x - 8, 24), fila, i)
	if datos.tipo == "medidor":
		rotulo("%s del total revisado" % valor_visible(100.0 * fila.valores[0] / total, " %"),
			Rect2(4, 24 + datos.columnas.size() * 25, size.x - 8, 24), SUAVE)
