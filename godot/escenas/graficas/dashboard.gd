extends VBoxContainer

const Base = preload("res://escenas/graficas/grafica_base.gd")
const Barras = preload("res://escenas/graficas/barras.gd")
const Linea = preload("res://escenas/graficas/linea.gd")
const Mapa = preload("res://escenas/graficas/mapa_calor.gd")
const Apilada = preload("res://escenas/graficas/apilada.gd")
const UI = preload("res://escenas/cuenta_ui.gd")
const SEMIBOLD = preload("res://assets/fuentes/Poppins-SemiBold.ttf")

var bloques: Array[Dictionary] = []


func cargar(modelo: Dictionary) -> void:
	add_theme_constant_override("separation", 14)
	var fichas := HBoxContainer.new()
	fichas.add_theme_constant_override("separation", 14)
	add_child(fichas)
	for ficha in modelo.fichas:
		var cuerpo := panel(fichas)
		etiqueta(cuerpo, ficha[0], 14, Base.SUAVE)
		etiqueta(cuerpo, ficha[1], 18, Base.TEXTO, true)
	var fila: HBoxContainer
	for datos in modelo.graficas:
		var ancho_completo: bool = datos.tipo == "mapa" or datos.has("detalle")
		if ancho_completo:
			agregar_grafica(self, datos)
			fila = null
		else:
			if fila == null or fila.get_child_count() == 2:
				fila = HBoxContainer.new()
				fila.add_theme_constant_override("separation", 14)
				add_child(fila)
			agregar_grafica(fila, datos)


func agregar_grafica(padre: Container, datos: Dictionary) -> void:
	var cuerpo := panel(padre)
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	cuerpo.add_child(cabecera)
	var titulo := etiqueta(cabecera, datos.titulo, 17, Base.TEXTO, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if datos.filas.is_empty():
		var vacio := etiqueta(cuerpo, datos.vacio, 14, Base.SUAVE)
		bloques.append({"datos": datos, "vacio": vacio})
		return
	var boton := Button.new()
	boton.text = "Ver como tabla"
	UI.estilizar_boton(boton)
	boton.add_theme_font_size_override("font_size", 14)
	boton.custom_minimum_size.y = 34
	boton.toggle_mode = true
	cabecera.add_child(boton)
	etiqueta(cuerpo, datos.lectura, 14, Base.SUAVE)

	var visual := VBoxContainer.new()
	cuerpo.add_child(visual)
	var grafica: Control
	match datos.tipo:
		"linea":
			grafica = Linea.new()
		"mapa":
			grafica = Mapa.new()
		"apilada", "medidor":
			grafica = Apilada.new()
		_:
			grafica = Barras.new()
	if datos.tipo == "linea":
		var leyenda := HFlowContainer.new()
		leyenda.add_theme_constant_override("h_separation", 14)
		visual.add_child(leyenda)
		for i in datos.columnas.size():
			if not datos.filas.any(func(fila: Dictionary) -> bool: return fila.valores[i] != null):
				continue
			var entrada := HBoxContainer.new()
			leyenda.add_child(entrada)
			var muestra := ColorRect.new()
			muestra.color = Base.SERIES[i]
			muestra.custom_minimum_size = Vector2(10, 10)
			muestra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			entrada.add_child(muestra)
			# Sin ajuste de línea: en un contenedor de flujo la etiqueta se parte letra por letra.
			etiqueta(entrada, datos.columnas[i], 14, Base.SUAVE).autowrap_mode = TextServer.AUTOWRAP_OFF
	grafica.datos = datos
	visual.add_child(grafica)
	var tabla := crear_tabla(datos)
	tabla.hide()
	cuerpo.add_child(tabla)
	boton.accessibility_description = datos.titulo
	boton.toggled.connect(func(activo: bool):
		tabla.visible = activo
		visual.visible = not activo
		boton.text = "Ver gráfica" if activo else "Ver como tabla")
	bloques.append({"datos": datos, "grafica": grafica, "tabla": tabla, "boton": boton})


func crear_tabla(datos: Dictionary) -> GridContainer:
	var tabla := GridContainer.new()
	var detalle: String = datos.get("detalle", "")
	if detalle.is_empty():
		match datos.tipo:
			"linea": detalle = "Fecha y evaluación"
			"mapa": detalle = "Estado"
			"barras":
				if datos.has("minimo"):
					detalle = "Nivel"
	var cabecera: Array = ["Sesión" if datos.tipo == "linea" else "Nombre"] + datos.columnas
	if not detalle.is_empty():
		cabecera.append(detalle)
	tabla.columns = cabecera.size()
	tabla.add_theme_constant_override("h_separation", 10)
	tabla.add_theme_constant_override("v_separation", 8)
	for texto in cabecera:
		etiqueta(tabla, texto, 14, Base.SUAVE, true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for fila in datos.filas:
		etiqueta(tabla, fila.nombre, 14, Base.TEXTO)
		for valor in fila.valores:
			etiqueta(tabla, Base.valor_visible(valor, datos.get("unidad", "")), 14, Base.TEXTO)
		if not detalle.is_empty():
			etiqueta(tabla, fila.detalle, 14, Base.SUAVE)
	return tabla


func panel(padre: Container) -> VBoxContainer:
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Base.FONDO
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 12
	caja.add_theme_stylebox_override("panel", estilo)
	padre.add_child(caja)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 7)
	caja.add_child(cuerpo)
	return cuerpo


func etiqueta(padre: Container, texto: String, puntos: int, color: Color, negrita: bool = false) -> Label:
	var etiqueta_nueva := Label.new()
	etiqueta_nueva.text = texto
	etiqueta_nueva.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_nueva.add_theme_font_override("font", SEMIBOLD if negrita else Base.FUENTE)
	etiqueta_nueva.add_theme_font_size_override("font_size", puntos)
	etiqueta_nueva.add_theme_color_override("font_color", color)
	padre.add_child(etiqueta_nueva)
	return etiqueta_nueva
