extends Node3D

const Zona = preload("res://escenas/zona_base.gd")
const Inventario = preload("res://logica/simulador/inventario.gd")
const Llave = preload("res://assets/modelos/herramientas/adjustable_wrench.glb")
const Flexometro = preload("res://assets/modelos/herramientas/tape_measure.glb")
const HERRAMIENTAS := [
	["llave_torque", "calzas"],
	["manometro", "lampara", "destornillador", "llave_ajustable"],
	["multimetro", "tech_tool", "flexometro"],
]
const NOMBRES_CAJONES := ["de abajo", "del medio", "de arriba"]
const REPUESTOS := [
	["neumatico", "bolsa_aire", "amortiguador"],
	["abrazadera", "tuercas", "pastillas_freno"],
	["foco", "fusible_correcto", "fusible_equivocado"],
]
const ROJO := Color("#9f302d")
const CAUCHO := Color("#232830")
const AMARILLO := Color("#e5a936")
const GUIA := Color("#3FA9F5")
const COLOR_MANO := Color("#54f5e3")
const GUIA_TEXTO := Color("#9BD8FF")
const LIMITE_SUPERFICIE := 6
const CONSOLA := "la consola del elevador"
const UBICACION_CONSOLA := CONSOLA + ", junto a las columnas"
const MARCAS_CALZAS := "las marcas amarillas del suelo, junto a las ruedas"
const ROTULO_CAJA := "CAJA DE HERRAMIENTAS"
const ROTULO_MESA := "MESA DE TRABAJO"
const ROTULO_REPUESTOS := "REPUESTOS"
const ROTULO_CARRITO := "CARRITO"
const ROTULO_CONSOLA := "CONSOLA DEL ELEVADOR"

var inventario := Inventario.new()
var objetos := {}
var origenes := {}
var cajones: Array[Node3D] = []
var cajon_abierto := -1
var animacion: Tween
var mano := ""
var ultimo_inventario: Array = []
var objetivo := ""
var pieza_guia: Node3D
var baliza: MeshInstance3D
var contorno := StandardMaterial3D.new()
var contorno_cercano: StandardMaterial3D
var flecha: Control
var distancia_guia: Label
var nombre_guia := ""
var direccion_guia := Vector2.ZERO
var mueble_guia: Node3D
var mallas_guia: Array[MeshInstance3D] = []
var espacio_guia := 0
var tecla_guia: Label
var hud: HBoxContainer
var titulos_hud: Array[Label] = []
var estilos_casilla: Array[StyleBoxFlat] = []
var espacios_hud: Array[Label] = []
var superficies := {}
var caducidad: Timer
var alturas := {}
var ubicaciones := {}
var destinos := {}
var rotulos := {}
var mesa: Zona
var caja_roja: Zona
var estanteria: Zona
var carrito: Zona
var origen_carrito: Vector3
var lleva_carrito := false
var mesa_banco: Zona
var origen_caja_multimetro := {}


func _ready() -> void:
	crear_muebles()
	crear_guia()
	var interfaz := CanvasLayer.new()
	add_child(interfaz)
	hud = HBoxContainer.new()
	interfaz.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.offset_left = 16
	hud.offset_top = -124
	hud.add_theme_constant_override("separation", 24)
	for grupo in ["Cinturón", "Carrito"]:
		var columna := VBoxContainer.new()
		columna.add_theme_constant_override("separation", 0)
		hud.add_child(columna)
		titulos_hud.append(etiqueta(columna, grupo, 14))
		for indice in Inventario.CAPACIDAD:
			var casilla := etiqueta(columna, "", 14)
			casilla.custom_minimum_size = Vector2(220, 24)
			espacios_hud.append(casilla)
	for color in [Color("#354452"), Color("#69859b"), COLOR_MANO, GUIA]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("#111a20") if estilos_casilla.is_empty() else Color("#182c40")
		estilo.border_color = color
		estilo.set_border_width_all(1)
		estilo.content_margin_left = 6
		estilo.content_margin_right = 6
		estilos_casilla.append(estilo)
	var columna_tecla := VBoxContainer.new()
	hud.add_child(columna_tecla)
	tecla_guia = etiqueta(columna_tecla, "", 14)
	tecla_guia.modulate = GUIA_TEXTO
	tecla_guia.hide()
	flecha = Control.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(flecha)
	distancia_guia = etiqueta(flecha, "", 14)
	distancia_guia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distancia_guia.modulate = GUIA_TEXTO
	flecha.draw.connect(dibujar_flecha)
	flecha.hide()


func etiqueta(padre: Node, texto: String, tam: int) -> Label:
	var nodo := Label.new()
	nodo.text = texto
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nodo.add_theme_font_size_override("font_size", tam)
	nodo.add_theme_color_override("font_outline_color", Color("#111a20"))
	nodo.add_theme_constant_override("outline_size", 8)
	padre.add_child(nodo)
	return nodo


func registrar_mueble(nodo: Node3D, nombre: String, descripcion: String, altura: float,
		texto_rotulo: String) -> void:
	destinos[nodo] = nombre
	ubicaciones[nodo] = descripcion
	alturas[nodo] = altura

	var rotulo := Label3D.new()
	rotulo.text = texto_rotulo
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.font = ThemeDB.fallback_font
	rotulo.font_size = 48
	rotulo.pixel_size = 0.0028
	rotulo.outline_size = 0
	rotulo.position = Vector3.UP * (altura + 0.23)
	nodo.add_child(rotulo)
	rotulos[nodo] = rotulo

	var placa := QuadMesh.new()
	var tam := rotulo.font.get_string_size(texto_rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, rotulo.font_size)
	placa.size = tam * rotulo.pixel_size + Vector2(0.12, 0.055)
	var fondo := StandardMaterial3D.new()
	fondo.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fondo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fondo.albedo_color = Color("#162027")
	fondo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fondo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	fondo.render_priority = -1
	var respaldo := MeshInstance3D.new()
	respaldo.mesh = placa
	respaldo.material_override = fondo
	respaldo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rotulo.add_child(respaldo)


func crear_muebles() -> void:
	$Banco.set_script(Zona)
	mesa = $Banco
	mesa.get_node("Tablero").scale.z = 1.16
	for nodo in mesa.get_children():
		if nodo.name.begins_with("Caja") or nodo.name.begins_with("Cinta"):
			nodo.queue_free()
	mesa.pieza(mesa, "mesa_taller", "Mesa de trabajo", Vector3(0, 1.03, 0),
		Vector3(3.45, 0.13, 1.16), Zona.ACERO).superficie.hide()
	registrar_mueble(mesa, "Mesa de trabajo", "la mesa de trabajo", 1.13, ROTULO_MESA)

	$Gabinete.set_script(Zona)
	caja_roja = $Gabinete
	caja_roja.pieza(caja_roja, "caja_taller", "Caja roja de herramientas", Vector3(0, 1.55, 0.36),
		Vector3(1.42, 0.14, 0.20), ROJO).superficie.hide()
	for fila in HERRAMIENTAS.size():
		var cajon := Node3D.new()
		caja_roja.add_child(cajon)
		cajones.append(cajon)
		for prefijo in ["Cajon", "Tirador"]:
			caja_roja.get_node(prefijo + str(fila)).reparent(cajon)
		var frente := cajon.get_node("Cajon" + str(fila)) as MeshInstance3D
		caja_roja.pieza(cajon, "cajon_taller_%d" % fila, "Cajón " + NOMBRES_CAJONES[fila],
			frente.position + Vector3.BACK * 0.027, Vector3(frente.scale.x, frente.scale.y, 0.09),
			ROJO).superficie.hide()
		var altura := frente.position.y + frente.scale.y / 2.0 - 0.105
		caja_roja.caja(cajon, Vector3(0, altura, 0.11),
			Vector3(1.20, 0.04, 0.48), Zona.FONDO)
		var ids: Array = HERRAMIENTAS[fila]
		for columna in ids.size():
			var id: String = ids[columna]
			var x := remap(columna, 0, 2, -0.42, 0.42) if ids.size() == 3 else -0.32 + (columna % 2) * 0.64
			var z := 0.24 if columna < 2 or ids.size() == 3 else 0.035
			crear_objeto(caja_roja, cajon, id, Vector3(x, altura + 0.02 + dimensiones(id).y / 2.0, z))
			mostrar_objeto(id)
	registrar_mueble(caja_roja, "Caja de herramientas",
		"la caja roja de herramientas, junto a la mesa de trabajo", 1.65, ROTULO_CAJA)

	estanteria = Zona.new()
	estanteria.name = "Estanteria"
	estanteria.position = Vector3(-8.55, 0, -8.15)
	estanteria.rotation_degrees.y = 17
	add_child(estanteria)
	for lado in [-1, 1]:
		for fondo in [-1, 1]:
			estanteria.caja(estanteria, Vector3(lado * 1.03, 1.05, fondo * 0.31),
				Vector3(0.065, 2.1, 0.065), Zona.ACERO)
	for fila in REPUESTOS.size():
		var altura := 0.24 + fila * 0.61
		estanteria.caja(estanteria, Vector3(0, altura, 0.16 - fila * 0.08), Vector3(2.12, 0.06, 0.72), Zona.ACERO)
		for columna in 3:
			var id: String = REPUESTOS[fila][columna]
			var tam := dimensiones(id)
			crear_objeto(estanteria, estanteria, id,
				Vector3((columna - 1) * 0.68, altura + 0.03 + tam.y / 2.0, 0.32 - fila * 0.13))
	registrar_mueble(estanteria, "Estantería de repuestos",
		"la estantería de repuestos, junto a la mesa de trabajo", 1.93, ROTULO_REPUESTOS)

	carrito = Zona.new()
	carrito.name = "CarritoHerramientas"
	carrito.position = Vector3(-4.2, 0, -6.4)
	add_child(carrito)
	origen_carrito = carrito.position
	carrito.pieza(carrito, "carrito_taller", "Carrito de herramientas", Vector3(0, 0.90, 0),
		Vector3(0.78, 0.075, 0.55), Zona.ACERO)
	carrito.caja(carrito, Vector3(0, 0.26, 0), Vector3(0.78, 0.06, 0.55), Zona.ACERO)
	carrito.caja(carrito, Vector3(0, 1.06, -0.27), Vector3(0.9, 0.05, 0.06), AMARILLO)
	for lado in [-1, 1]:
		for fondo in [-1, 1]:
			var esquina := Vector3(lado * 0.33, 0, fondo * 0.21)
			carrito.caja(carrito, esquina + Vector3.UP * 0.54, Vector3(0.045, 0.75, 0.045), Zona.ACERO)
			carrito.cilindro(carrito, esquina + Vector3.UP * 0.10, 0.10, 0.06, CAUCHO).rotation_degrees.z = 90
	registrar_mueble(carrito, "Carrito de herramientas", "el carrito de herramientas", 1.10, ROTULO_CARRITO)


func dimensiones(id: String) -> Vector3:
	match id:
		"neumatico", "bolsa_aire":
			return Vector3(0.48, 0.45, 0.34)
		"amortiguador":
			return Vector3(0.52, 0.14, 0.15)
		"llave_torque", "llave_ajustable", "destornillador", "lampara":
			return Vector3(0.40, 0.10, 0.15)
		"fusible_correcto", "fusible_equivocado", "foco":
			return Vector3(0.15, 0.13, 0.15)
		_:
			return Vector3(0.25, 0.14, 0.20)


func crear_objeto(zona: Zona, padre: Node3D, id: String, centro: Vector3) -> void:
	var objeto := zona.pieza(padre, id, Inventario.CATALOGO[id].nombre, centro, dimensiones(id), Zona.ACERO)
	objeto.superficie.hide()
	var visual := Node3D.new()
	visual.name = "Forma"
	objeto.add_child(visual)
	var plata := Color("#b2bec8")
	match id:
		"llave_ajustable", "flexometro":
			var modelo := (Llave if id == "llave_ajustable" else Flexometro).instantiate() as Node3D
			visual.add_child(modelo)
			modelo.scale *= 1.45
			if id == "llave_ajustable":
				modelo.rotation_degrees.y = 90
				modelo.position.x = -0.14
		"destornillador", "llave_torque", "amortiguador", "lampara":
			var color := ROJO if id == "destornillador" else CAUCHO
			if id == "lampara":
				color = AMARILLO
			zona.cilindro(visual, Vector3(-0.085, 0, 0), 0.037, 0.21, color).rotation_degrees.z = 90
			zona.cilindro(visual, Vector3(0.084, 0, 0), 0.009, 0.17, plata).rotation_degrees.z = 90
			if id == "lampara":
				zona.cilindro(visual, Vector3(0.16, 0, 0), 0.053, 0.07, AMARILLO).rotation_degrees.z = 90
				zona.cilindro(visual, Vector3(0.20, 0, 0), 0.044, 0.01, Color("#fff1c0")).rotation_degrees.z = 90
			elif id == "llave_torque":
				zona.cilindro(visual, Vector3(0.16, 0, 0), 0.037, 0.035, plata)
				zona.caja(visual, Vector3(0.16, 0.025, 0), Vector3(0.027, 0.023, 0.027), plata)
			elif id == "amortiguador":
				for extremo in [-1, 1]:
					zona.cilindro(visual, Vector3(extremo * 0.21, 0, 0), 0.043, 0.034, plata)
					zona.cilindro(visual, Vector3(extremo * 0.21, 0.018, 0), 0.018, 0.003, CAUCHO)
		"tech_tool":
			zona.caja(visual, Vector3.ZERO, Vector3(0.22, 0.045, 0.16), CAUCHO)
			zona.caja(visual, Vector3.UP * 0.023, Vector3(0.18, 0.008, 0.12), Color("#47a9a3"))
		"multimetro":
			zona.caja(visual, Vector3.ZERO, Vector3(0.13, 0.05, 0.18), AMARILLO)
			zona.caja(visual, Vector3(0, 0.026, -0.045), Vector3(0.095, 0.01, 0.06), Color("#7ba594"))
			zona.cilindro(visual, Vector3(0, 0.029, 0.03), 0.033, 0.015, CAUCHO)
		"manometro":
			zona.cilindro(visual, Vector3.ZERO, 0.069, 0.045, CAUCHO)
			zona.cilindro(visual, Vector3.UP * 0.025, 0.056, 0.006, Color.WHITE)
			zona.caja(visual, Vector3(0, 0.03, 0.014), Vector3(0.005, 0.004, 0.055), ROJO)
			zona.caja(visual, Vector3(0.09, 0, 0), Vector3(0.075, 0.018, 0.025), plata)
		"calzas":
			var prisma := PrismMesh.new()
			prisma.size = Vector3(0.105, 0.094, 0.12)
			for lado in [-1, 1]:
				zona.superficie(visual, Vector3(lado * 0.066, 0, 0), prisma, AMARILLO)
		"foco":
			zona.cilindro(visual, Vector3.DOWN * 0.03, 0.031, 0.055, plata)
			var bulbo := SphereMesh.new()
			bulbo.radius = 0.052
			bulbo.height = 0.10
			bulbo.radial_segments = 12
			bulbo.rings = 6
			zona.superficie(visual, Vector3.UP * 0.017, bulbo, Color("#fff1c0"))
		"fusible_correcto", "fusible_equivocado":
			var color := Color("#3c8bb7") if id == "fusible_correcto" else ROJO
			zona.caja(visual, Vector3.UP * 0.014, Vector3(0.10, 0.065, 0.045), color)
			for lado in [-1, 1]:
				zona.caja(visual, Vector3(lado * 0.027, -0.033, 0), Vector3(0.017, 0.035, 0.012), plata)
		"neumatico", "abrazadera":
			var aro := TorusMesh.new()
			aro.outer_radius = 0.21 if id == "neumatico" else 0.087
			aro.inner_radius = aro.outer_radius * (0.57 if id == "neumatico" else 0.81)
			aro.rings = 16
			aro.ring_segments = 10
			zona.superficie(visual, Vector3.ZERO, aro, CAUCHO if id == "neumatico" else plata).rotation_degrees.x = 90
			if id == "abrazadera":
				zona.caja(visual, Vector3(0.08, 0.025, 0), Vector3(0.044, 0.033, 0.035), plata)
		"bolsa_aire":
			for nivel in [-1, 0, 1]:
				zona.cilindro(visual, Vector3.UP * nivel * 0.088, 0.155, 0.067, CAUCHO)
			zona.cilindro(visual, Vector3.ZERO, 0.13, 0.27, plata)
		"tuercas":
			for lado in [-1, 0, 1]:
				zona.cilindro(visual, Vector3(lado * 0.07, 0, 0), 0.031, 0.043, plata, 6)
				zona.cilindro(visual, Vector3(lado * 0.07, 0.022, 0), 0.014, 0.002, CAUCHO)
		"pastillas_freno":
			for lado in [-1, 1]:
				zona.caja(visual, Vector3(0, 0, lado * 0.048), Vector3(0.16, 0.065, 0.045), CAUCHO)
				zona.caja(visual, Vector3(0, 0.041, lado * 0.048), Vector3(0.13, 0.022, 0.035), plata)
	var limites := AABB()
	for malla in visual.find_children("*", "MeshInstance3D", true, false):
		var espacio_local: Transform3D = visual.global_transform.affine_inverse() * malla.global_transform
		var caja_malla: AABB = espacio_local * malla.get_aabb()
		limites = caja_malla if limites.size == Vector3.ZERO else limites.merge(caja_malla)
	var centro_visual := limites.get_center()
	visual.position = Vector3(-centro_visual.x, -limites.position.y - dimensiones(id).y / 2.0, -centro_visual.z)
	objetos[id] = objeto
	origenes[id] = {"padre": padre, "posicion": centro, "zona": zona}


func pieza_cajon(fila: int) -> StaticBody3D:
	return caja_roja.piezas["cajon_taller_%d" % fila]


func mover_cajon(fila: int, inmediato := false) -> void:
	cajon_abierto = fila
	if animacion != null:
		animacion.kill()
		animacion = null
	for indice in cajones.size():
		var destino := 0.68 if indice == fila else 0.0
		var cajon := cajones[indice]
		if inmediato:
			cajon.position.z = destino
		elif not is_equal_approx(cajon.position.z, destino):
			if animacion == null:
				animacion = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
			animacion.tween_property(cajon, "position:z", destino, 0.35)
	for id in objetos:
		if objetos[id].zona == caja_roja:
			mostrar_objeto(id)


func ubicar_multimetro_en_banco(banco: Zona) -> void:
	mesa_banco = banco
	registrar_mueble(banco, "Banco de diagnóstico", "la mesa del banco de diagnóstico", 1.65, "BANCO DE DIAGNÓSTICO")
	origen_caja_multimetro = origenes.multimetro
	origenes.multimetro = {"padre": banco, "zona": banco, "posicion": banco.piezas.multimetro.position}
	devolver("multimetro")


func cerca(posicion: Vector3) -> bool:
	return posicion.distance_squared_to(carrito.global_position) < 9.0


func tomar(id: String, cerca_carrito: bool) -> String:
	if objetos.has(id) and fila_cajon(id) >= 0:
		return "Abre el cajón %s para tomar la herramienta." % detalle_cajon(id)
	var aviso := inventario.tomar(id, cerca_carrito)
	if aviso.is_empty():
		if superficies.erase(id):
			objetos[id].scale = Vector3.ONE
		mano = id
		if id in inventario.carrito:
			ordenar_carrito()
		mostrar_objeto(id)
		if objetivo == id:
			apagar_guia()
	return aviso


func objetos_en(mueble: Node3D) -> Array[String]:
	var disponibles: Array[String] = []
	for id in objetos:
		if objetos[id].zona == mueble and fila_cajon(id) < 0 \
				and id not in inventario.cinturon and id not in inventario.carrito:
			disponibles.append(id)
	return disponibles


func hay_superficie(mueble: Node3D) -> bool:
	var ocupadas := 0
	for id in superficies:
		if objetos[id].zona == mueble:
			ocupadas += 1
	return ocupadas < LIMITE_SUPERFICIE


func dejar(id: String, cerca_carrito: bool, mueble: Node3D = mesa) -> String:
	if mueble == caja_roja and Inventario.CATALOGO.get(id, {}).get("tipo") != "herramienta":
		return "La caja roja es para herramientas. Deja este objeto en otro mueble."
	var ranura := 0
	if mueble != caja_roja and mueble != mesa_banco:
		var ocupadas := []
		for otro in superficies:
			if objetos[otro].zona == mueble:
				ocupadas.append(superficies[otro])
		while ranura in ocupadas:
			ranura += 1
		if ranura >= LIMITE_SUPERFICIE:
			return "El mueble está lleno. Busca otro lugar para dejar el objeto."
	var aviso := inventario.dejar(id, cerca_carrito)
	if not aviso.is_empty():
		return aviso
	if mueble == caja_roja:
		devolver(id, origen_caja_multimetro if id == "multimetro" else {})
	elif mueble == mesa_banco:
		devolver(id)
	else:
		var objeto: StaticBody3D = objetos[id]
		if objeto.get_parent() != mueble:
			objeto.reparent(mueble, false)
		objeto.zona = mueble
		superficies[id] = ranura
		var altura := 1.12 if mueble == mesa else 0.94
		var tam := dimensiones(id)
		var escala := 1.0 if mueble == mesa else minf(1.0, minf(0.26 / tam.x, 0.23 / tam.z))
		objeto.scale = Vector3.ONE * escala
		var x := -1.40 + ranura * 0.56 if mueble == mesa else (ranura % 3 - 1) * 0.28
		var z := 0.35 if mueble == mesa else (0.13 if ranura < 3 else -0.13)
		objeto.position = Vector3(x, altura + tam.y * escala / 2.0, z)
		mostrar_objeto(id)
	ordenar_carrito()
	if mano == id:
		mano = ""
	return ""


func ordenar_carrito() -> void:
	for indice in inventario.carrito.size():
		var id := inventario.carrito[indice]
		var objeto: StaticBody3D = objetos[id]
		if objeto.get_parent() != carrito:
			objeto.reparent(carrito, false)
		objeto.zona = carrito
		objeto.position = Vector3(-0.20 + float(indice % 2) * 0.40,
			0.30 + dimensiones(id).y / 2.0, 0.12 - floorf(float(indice) / 2.0) * 0.26)


func consumir(requiere: Dictionary, cerca_carrito: bool) -> void:
	inventario.consumir(requiere, cerca_carrito)
	for id in requiere.get("piezas", []):
		devolver(id)
		if mano == id:
			mano = ""

	ordenar_carrito()


func devolver(id: String, destino: Dictionary = {}) -> void:
	superficies.erase(id)
	var objeto: StaticBody3D = objetos[id]
	var origen: Dictionary = origenes[id] if destino.is_empty() else destino
	if objeto.get_parent() != origen.padre:
		objeto.reparent(origen.padre, false)
	objeto.scale = Vector3.ONE
	objeto.position = origen.posicion
	objeto.zona = origen.zona
	mostrar_objeto(id)


func mostrar_objeto(id: String) -> void:
	var objeto: StaticBody3D = objetos[id]
	objeto.visible = id not in inventario.cinturon \
		and objeto.zona != mesa_banco and (objeto.zona != caja_roja or cajones.find(objeto.get_parent()) == cajon_abierto)
	objeto.set_deferred("collision_layer", 2 if objeto.visible and id not in inventario.carrito else 0)
	if id == "multimetro" and mesa_banco != null:
		var en_mesa: bool = objeto.zona == mesa_banco and id not in inventario.cinturon and id not in inventario.carrito
		mesa_banco.mostrar_multimetro(en_mesa)


func reiniciar() -> void:
	apagar_guia()
	mano = ""
	lleva_carrito = false
	carrito.position = origen_carrito
	inventario.reiniciar()
	mover_cajon(-1, true)
	for id in objetos:
		devolver(id)


func seleccionar(paso: int, cerca_carrito: bool) -> void:
	var lista := inventario.accesibles(cerca_carrito)
	if not lista.is_empty():
		var indice := lista.find(mano)
		mano = lista[posmod(indice + paso if indice >= 0 else (0 if paso > 0 else -1), lista.size())]


func objeto_en_espacio(numero: int) -> String:
	var almacen := inventario.cinturon if numero <= 4 else inventario.carrito
	var indice := 1 if numero <= 4 else 5
	for id in almacen:
		if indice == numero:
			return id
		indice += Inventario.CATALOGO[id].espacio
	return ""


func espacio_de(id: String) -> int:
	for numero in range(1, 9):
		if objeto_en_espacio(numero) == id:
			return numero
	return 0


func actualizar_hud(cerca_carrito: bool, visible_hud: bool) -> void:
	if not cerca_carrito and mano in inventario.carrito:
		mano = ""
	hud.visible = visible_hud
	var firma := [mano, inventario.cinturon, inventario.carrito, cerca_carrito, espacio_guia]
	if firma == ultimo_inventario:
		return
	ultimo_inventario = firma.duplicate(true)
	titulos_hud[0].text = "Cinturón %d/%d" % [
		Inventario.espacio(inventario.cinturon), Inventario.CAPACIDAD]
	titulos_hud[1].text = "Carrito %d/%d%s" % [
		Inventario.espacio(inventario.carrito), Inventario.CAPACIDAD, "" if cerca_carrito else " · lejos"]
	var color_carrito := Color.WHITE if cerca_carrito else Color("#98a2ad")
	titulos_hud[1].modulate = color_carrito
	var restantes := 0
	var estilo: StyleBoxFlat
	var color := Color.WHITE
	for numero in range(1, 9):
		var id := objeto_en_espacio(numero)
		var casilla := espacios_hud[numero - 1]
		var continuacion := restantes > 0
		if continuacion:
			casilla.text = ""
		else:
			var objeto := Inventario.objeto(id)
			var tamano: int = objeto.get("espacio", 1)
			restantes = tamano
			var nombre: String = objeto.get("nombre", "—")
			casilla.text = "%d %s%s" % [numero, nombre, " ×%d" % tamano if tamano > 1 else ""]
			color = color_carrito if numero > 4 else Color.WHITE
			estilo = estilos_casilla[0 if id.is_empty() else 1]
			if not id.is_empty() and mano == id:
				color = COLOR_MANO
				estilo = estilos_casilla[2]
			if numero == espacio_guia:
				color = GUIA_TEXTO
				estilo = estilos_casilla[3]
		var borde := estilo
		if continuacion or restantes > 1:
			borde = estilo.duplicate()
			borde.border_width_top = 0 if continuacion else 1
			borde.border_width_bottom = 0 if restantes > 1 else 1
			borde.content_margin_top = 1
			borde.content_margin_bottom = 1
		casilla.modulate = color
		casilla.add_theme_stylebox_override("normal", borde)
		restantes -= 1
	tecla_guia.visible = espacio_guia > 0
	tecla_guia.text = "Pulsa %d" % espacio_guia


func crear_guia() -> void:
	baliza = estanteria.cilindro(self, Vector3.ZERO, 0.28, 2.1, Color(GUIA, 0.10), 16)
	var material := baliza.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	baliza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	baliza.hide()
	contorno.albedo_color = GUIA
	contorno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	contorno.cull_mode = BaseMaterial3D.CULL_FRONT
	contorno.grow = true
	contorno.grow_amount = 0.014
	contorno.emission_enabled = true
	contorno.emission = GUIA
	contorno_cercano = contorno.duplicate() as StandardMaterial3D
	contorno_cercano.no_depth_test = true
	contorno_cercano.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	contorno_cercano.albedo_color = Color(GUIA, 0.14)
	caducidad = Timer.new()
	caducidad.one_shot = true
	caducidad.wait_time = 30.0
	add_child(caducidad)
	caducidad.timeout.connect(apagar_guia)


func mueble_de(id: String) -> Node3D:
	return carrito if id in inventario.carrito else objetos[id].zona


func ubicacion(id: String) -> String:
	var lugar: String = ubicaciones[mueble_de(id)]
	var cajon := detalle_cajon(id)
	return lugar if cajon.is_empty() else "%s, en el cajón %s" % [lugar, cajon]


func detalle_cajon(id: String) -> String:
	var fila := cajones.find(objetos[id].get_parent())
	return NOMBRES_CAJONES[fila] if fila >= 0 else ""


func fila_cajon(id: String) -> int:
	var fila := cajones.find(objetos[id].get_parent())
	return fila if fila != cajon_abierto else -1


func instruccion_tomar(id: String, hecho := false) -> String:
	var nombre := Inventario.nombre_con_articulo(id)
	var carga: int = Inventario.CATALOGO[id].espacio
	var espacio := " (ocupa %s)" % Inventario.cantidad_espacios(carga) if carga > 1 else ""
	var cajon := detalle_cajon(id)
	if not cajon.is_empty():
		if not hecho and fila_cajon(id) >= 0:
			return "Abre el cajón %s de la caja roja de herramientas para tomar %s." % [cajon, nombre]
		return "Toma %s del cajón %s de la caja roja de herramientas." % [nombre, cajon]
	return "Toma %s en %s%s." % [nombre, ubicacion(id), espacio]


func senalar(id: String, pieza: Node3D = null, manual := true, columna := true, destino := "") -> void:
	var mueble: Node3D
	var fila := -1
	if pieza == null:
		mueble = mueble_de(id)
		fila = fila_cajon(id)
		if fila >= 0:
			pieza = pieza_cajon(fila)
		elif mueble == mesa_banco:
			pieza = mesa_banco.piezas[id]
		else:
			pieza = objetos[id]
	if objetivo != id or pieza_guia != pieza or mueble_guia != mueble:
		apagar_guia()
		objetivo = id
		pieza_guia = pieza
		mueble_guia = mueble
		var forma := pieza.get_node_or_null("Forma")
		if fila >= 0:
			mallas_guia.append(cajones[fila].get_node("Cajon%d" % fila))
			mallas_guia.append(cajones[fila].get_node("Tirador%d" % fila))
		elif pieza == mesa.piezas.mesa_taller:
			mallas_guia.append(mesa.get_node("Tablero"))
		else:
			for malla in (forma if forma != null else pieza).find_children("*", "MeshInstance3D", true, false):
				if malla.visible:
					mallas_guia.append(malla)
		for malla in mallas_guia:
			malla.material_overlay = contorno
	nombre_guia = destinos.get(mueble, destinos.get(pieza, destino if not destino.is_empty() else pieza.nombre))
	if manual:
		caducidad.start()
	var material := baliza.material_override as StandardMaterial3D
	var reforzada := not caducidad.is_stopped()
	var color := Color(GUIA, 0.34 if reforzada else 0.10)
	if material.albedo_color != color:
		material.albedo_color = color
	baliza.visible = columna or reforzada
	colocar_baliza()


func colocar_baliza() -> void:
	var base := pieza_guia.global_position
	if mueble_guia != null:
		base = mueble_guia.global_position + Vector3.UP * alturas[mueble_guia]
	baliza.global_position = base + Vector3.UP * 1.05


func senalar_espacio(numero: int, manual: bool) -> void:
	if espacio_guia != numero:
		apagar_guia()
		espacio_guia = numero
	if manual:
		caducidad.start()


func apagar_guia() -> void:
	for malla in mallas_guia:
		if is_instance_valid(malla):
			malla.material_overlay = null
	mallas_guia.clear()
	pieza_guia = null
	mueble_guia = null
	objetivo = ""
	espacio_guia = 0
	baliza.hide()
	flecha.hide()
	caducidad.stop()


func actualizar_flecha(camara: Camera3D, mostrar: bool) -> void:
	if pieza_guia == null:
		flecha.hide()
		return
	var punto := pieza_guia.global_position
	var distancia := camara.global_position.distance_to(punto)
	var contorno_visible: Material = contorno_cercano if distancia < 3.0 else null
	if contorno.next_pass != contorno_visible:
		contorno.next_pass = contorno_visible
	if not mostrar:
		flecha.hide()
		return
	colocar_baliza()
	var rect := camara.get_viewport().get_visible_rect()
	var detras := camara.is_position_behind(punto)
	var proyectado := camara.unproject_position(punto)
	if not detras and rect.has_point(proyectado):
		flecha.hide()
		return
	var local := camara.to_local(punto)
	var direccion := Vector2(local.x, -local.y) if detras else proyectado - rect.get_center()
	direccion_guia = direccion.normalized() if direccion.length_squared() > 0.0001 else Vector2.RIGHT
	var margen := (rect.size / 2.0 - Vector2(35, 48)).max(Vector2.ONE)
	var borde := minf(margen.x / maxf(absf(direccion_guia.x), 0.001),
		margen.y / maxf(absf(direccion_guia.y), 0.001))
	flecha.position = rect.get_center() + direccion_guia * borde
	distancia_guia.text = "%s · %d m" % [nombre_guia, roundi(distancia)]
	distancia_guia.size = distancia_guia.get_minimum_size()
	var texto := flecha.position - direccion_guia * 26.0 - distancia_guia.size / 2.0
	if absf(direccion_guia.x) > 0.5:
		texto.x -= signf(direccion_guia.x) * distancia_guia.size.x / 2.0
	distancia_guia.position = texto.clamp(rect.position + Vector2(8, 8),
		rect.end - distancia_guia.size - Vector2(8, 8)) - flecha.position
	flecha.queue_redraw()
	flecha.show()


func dibujar_flecha() -> void:
	var lado := direccion_guia.orthogonal() * 10.0
	var base := -direccion_guia * 8.0
	flecha.draw_colored_polygon(PackedVector2Array([direccion_guia * 14.0, base + lado, base - lado]), GUIA)


func mover_carrito(jugador: Vector3, delta: float) -> void:
	var distancia := carrito.global_position.distance_to(jugador)
	if distancia < 1.28:
		return
	var avance := minf(3.8 * delta, distancia - 1.28)
	var destino := carrito.global_position.move_toward(Vector3(jugador.x, 0, jugador.z), avance)
	var consulta := PhysicsRayQueryParameters3D.create(carrito.global_position + Vector3.UP * 0.45,
		destino + Vector3.UP * 0.45, 1)
	if carrito.get_world_3d().direct_space_state.intersect_ray(consulta).is_empty():
		carrito.global_position = destino
