extends RefCounted


static func aplicar(contenido: Control, margen: float = 24.0) -> void:
	contenido.draw.connect(func():
		var estilo := contenido.get_theme_stylebox("panel", "PanelContainer")
		contenido.draw_style_box(estilo, Rect2(Vector2.ZERO, contenido.size).grow(margen)))
