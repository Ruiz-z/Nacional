extends "res://escenas/graficas/grafica_base.gd"


func _get_minimum_size() -> Vector2:
	return Vector2(0, 225)


func dibujar() -> void:
	var filas: Array = datos.filas
	var trama := Rect2(55, 14, size.x - 263, size.y - 50)
	for valor in [0, 25, 50, 75, 100]:
		var y: float = trama.end.y - trama.size.y * valor / 100.0
		draw_line(Vector2(trama.position.x, y), Vector2(trama.end.x, y), REJILLA)
		rotulo("%d %%" % valor, Rect2(0, y - 11, 49, 22), SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
	var finales: Array[Dictionary] = []
	var puntos: Array[Dictionary] = []
	for j in datos.columnas.size():
		var anterior := Vector2.ZERO
		var ultimo_valor := 0.0
		var tiene_punto := false
		for i in filas.size():
			var fila: Dictionary = filas[i]
			var valor: Variant = fila.valores[j]
			if valor == null:
				continue
			# Separa los puntos del mismo valor para que cada serie tenga su propio tooltip.
			var indice_par: int = fila.valores.slice(0, j).count(valor)
			var desfase: float = (indice_par - (fila.valores.count(valor) - 1) * 0.5) * 10
			var centro := Vector2(x_sesion(trama, filas.size(), i) + desfase,
				trama.end.y - trama.size.y * valor / 100.0)
			if tiene_punto:
				draw_line(anterior, centro, SERIES[j], 2, true)
			puntos.append({"centro": centro, "fila": fila, "serie": j})
			anterior = centro
			ultimo_valor = valor
			tiene_punto = true
		if tiene_punto:
			finales.append({"punto": anterior, "serie": j, "valor": ultimo_valor})
	finales.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.punto.y < b.punto.y)
	var siguiente := trama.position.y
	for i in finales.size():
		var final_serie: Dictionary = finales[i]
		var j: int = final_serie.serie
		var y := clampf(final_serie.punto.y, siguiente, trama.end.y - (finales.size() - i - 1) * 23)
		siguiente = y + 23
		draw_polyline(PackedVector2Array([final_serie.punto, Vector2(trama.end.x + 16, y),
			Vector2(trama.end.x + 22, y)]), SERIES[j], 1, true)
		var etiqueta := "%s · %s" % [datos.columnas[j], valor_visible(final_serie.valor, " %")]
		rotulo(etiqueta, Rect2(trama.end.x + 26, y - 11, 182, 22))
	for dato in puntos:
		var centro: Vector2 = dato.centro
		punto(centro, SERIES[dato.serie])
		marca(Rect2(centro - Vector2(7, 7), Vector2(14, 14)), dato.fila, dato.serie)
	var indices := [0]
	if filas.size() > 2 and trama.size.x >= 240:
		indices.append(floori((filas.size() - 1) / 2.0))
	if filas.size() > 1:
		indices.append(filas.size() - 1)
	for i in indices:
		var x := x_sesion(trama, filas.size(), i)
		rotulo(filas[i].nombre, Rect2(x - 45, trama.end.y + 9, 90, 22), SUAVE, HORIZONTAL_ALIGNMENT_CENTER)


func x_sesion(trama: Rect2, cantidad: int, indice: int) -> float:
	return trama.get_center().x if cantidad == 1 else trama.position.x + trama.size.x * indice / (cantidad - 1)
