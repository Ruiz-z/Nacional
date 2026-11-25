extends "res://escenas/graficas/grafica_base.gd"

const ALTO := 30


func _get_minimum_size() -> Vector2:
	var filas: Array = datos.get("filas", [])
	return Vector2(0, 28 + filas.size() * altura_fila())


func altura_fila() -> int:
	if datos.get("tipo") == "agrupada":
		return 74
	return 44 if datos.has("minimo") else ALTO


func dibujar() -> void:
	var agrupada: bool = datos.tipo == "agrupada"
	var porcentaje: bool = datos.has("maximo")
	var detalle: bool = datos.has("detalle")
	var izquierda := minf(240, size.x * (0.24 if detalle else 0.36))
	var reserva := 250 if detalle else (178 if agrupada else 82)
	var ancho := maxf(1, size.x - izquierda - reserva)
	var maximo: float = datos.get("maximo", 1)
	var unidad: String = datos.get("unidad", "")
	if not porcentaje:
		for fila in datos.filas:
			maximo = maxf(maximo, fila.valores[0])
	var paso := altura_fila()
	var piso: float = 26 + datos.filas.size() * paso
	var marcas_eje := [0, 50, 100] if porcentaje else [0, int(maximo)]
	for valor in marcas_eje:
		var x: float = izquierda + ancho * valor / maximo
		draw_line(Vector2(x, 24), Vector2(x, piso), REJILLA)
		rotulo(str(valor) + unidad, Rect2(x - 22, 0, 44, 22), SUAVE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in datos.filas.size():
		var fila: Dictionary = datos.filas[i]
		var y: int = 26 + i * paso
		rotulo(fila.nombre, Rect2(4, y, izquierda - 12, 22 if datos.has("minimo") else paso))
		for j in fila.valores.size():
			var valor: Variant = fila.valores[j]
			var centro: float = y + (j * 22 + 11 if agrupada else paso / 2.0)
			var etiqueta := valor_visible(valor, unidad)
			var ancho_etiqueta := 166 if agrupada else 72
			if agrupada:
				etiqueta = "%s · %s" % [datos.columnas[j], etiqueta]
			var largo := 0.0
			if valor != null:
				largo = ancho * valor / maximo
				var color: Color = TONOS[j] if agrupada else TONOS[clampi(floori((1.0 - valor / maximo) * 4), 0, 3)]
				barra(Rect2(izquierda, centro - 8, largo, 16), color)
				if largo == 0:
					draw_line(Vector2(izquierda, centro - 8), Vector2(izquierda, centro + 8), color, 2)
			var posicion_etiqueta := ancho if datos.has("minimo") else largo
			rotulo(etiqueta, Rect2(izquierda + posicion_etiqueta + 7, centro - 11, ancho_etiqueta, 22),
				SUAVE if valor == null else TEXTO)
			marca(Rect2(izquierda, centro - 10, posicion_etiqueta + ancho_etiqueta + 7, 20), fila, j)
		if detalle:
			rotulo(fila.detalle, Rect2(size.x - 175, y, 175, ALTO), SUAVE)
		elif not agrupada and datos.has("minimo"):
			# El nivel se lee junto al nombre y permanece separado de la escala.
			var zona := Rect2(4, y + 22, izquierda - 12, 22)
			rotulo(fila.detalle, zona, SUAVE)
	if datos.has("minimo"):
		var umbral: float = izquierda + ancho * datos.minimo / maximo
		draw_dashed_line(Vector2(umbral, 24), Vector2(umbral, piso), SUAVE, 1, 4)
