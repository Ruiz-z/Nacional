extends Node3D

const Zona = preload("res://escenas/zona_base.gd")
const Inventario = preload("res://logica/simulador/inventario.gd")
const Llave = preload("res://assets/modelos/herramientas/adjustable_wrench.glb")
const Flexometro = preload("res://assets/modelos/herramientas/tape_measure.glb")
const HERRAMIENTAS := [
	["calzas", "lampara"], ["manometro", "llave_torque"],
	["multimetro", "flexometro"], ["llave_ajustable", "destornillador", "tech_tool"],
]
const REPUESTOS := [
	["neumatico", "bolsa_aire", "amortiguador"],
	["abrazadera", "tuercas", "pastillas_freno"],
	["foco", "fusible_correcto", "fusible_equivocado"],
]
const ROJO := Color("#9f302d")
const CAUCHO := Color("#232830")
const AMARILLO := Color("#e5a936")
const GUIA := Color("#54f5e3")
const LIMITE_SUPERFICIE := 6

var inventario := Inventario.new()
var objetos := {}
var origenes := {}
var cajones: Array[Node3D] = []
var cajones_abiertos := false
var animacion: Tween
var mano := ""
var ultimo_inventario: Array = []
var objetivo := ""
var baliza: MeshInstance3D
var contorno := StandardMaterial3D.new()
var flecha: Label
var hud: HBoxContainer
var espacios_hud: Array[Label] = []
var superficies := {}
var caducidad: Timer
var alturas := {}
var ubicaciones := {}
var mesa: Zona
var caja_roja: Zona
var estanteria: Zona
var carrito: Zona
var origen_carrito: Vector3
var lleva_carrito := false


func _ready() -> void:
	crear_muebles()
	crear_guia()
	var interfaz := CanvasLayer.new()
	add_child(interfaz)
	hud = HBoxContainer.new()
	interfaz.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hud.offset_left = 16
	hud.offset_top = -116
	hud.add_theme_constant_override("separation", 24)
	for grupo in ["Cinturón", "Carrito"]:
		var columna := VBoxContainer.new()
		columna.add_theme_constant_override("separation", 0)
		hud.add_child(columna)
		etiqueta(columna, grupo, 14)
		for indice in Inventario.CAPACIDAD:
			espacios_hud.append(etiqueta(columna, "", 14))
	flecha = etiqueta(interfaz, "▲", 32)
	flecha.modulate = GUIA
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


func registrar_mueble(zona: Zona, descripcion: String, altura: float) -> void:
	ubicaciones[zona] = descripcion
	alturas[zona] = altura


func crear_muebles() -> void:
	$Banco.set_script(Zona)
	mesa = $Banco
	mesa.get_node("Tablero").scale.z = 1.16
	for nodo in mesa.get_children():
		if nodo.name.begins_with("Caja") or nodo.name.begins_with("Cinta"):
			nodo.queue_free()
	mesa.pieza(mesa, "mesa_taller", "Mesa de trabajo", Vector3(0, 1.03, 0),
		Vector3(3.45, 0.13, 1.16), Zona.ACERO).superficie.hide()
	registrar_mueble(mesa, "la mesa de trabajo, al fondo a la izquierda", 1.13)

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
		var tirador := cajon.get_node("Tirador" + str(fila)) as MeshInstance3D
		caja_roja.pieza(cajon, "cajon_taller_%d" % fila, "Cajón de herramientas",
			tirador.position, Vector3(0.89, 0.055, 0.055), Zona.ACERO).superficie.hide()
		var altura := 0.27 + fila * 0.255
		caja_roja.caja(cajon, Vector3(0, altura - 0.075, 0.11),
			Vector3(1.20, 0.04, 0.48), Zona.FONDO)
		var ids: Array = HERRAMIENTAS[fila]
		for columna in ids.size():
			var id: String = ids[columna]
			crear_objeto(caja_roja, cajon, id, Vector3(
				remap(columna, 0, ids.size() - 1, -0.46, 0.46) if ids.size() == 3 else -0.32 + columna * 0.64,
				altura - 0.055 + dimensiones(id).y / 2.0, 0.25))
	cambiar_cajones(false, true)
	registrar_mueble(caja_roja, "la caja roja de herramientas, junto a la mesa", 1.65)

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
	var rotulo := estanteria.rotulo(estanteria, Vector3(0, 1.92, 0.31), "REPUESTOS", 0.005)
	rotulo.rotation_degrees.y = 0
	registrar_mueble(estanteria, "la estantería de piezas, a la izquierda de la mesa", 2.08)

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
	registrar_mueble(carrito, "el carrito de herramientas, en el taller", 1.12)


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


func cambiar_cajones(abrir: bool, inmediato := false) -> void:
	cajones_abiertos = abrir
	if animacion != null:
		animacion.kill()
	if not inmediato:
		animacion = create_tween().set_parallel()
	for fila in cajones.size():
		var destino := 0.55 + (cajones.size() - 1 - fila) * 0.25 if abrir else 0.0
		if inmediato:
			cajones[fila].position.z = destino
		else:
			animacion.tween_property(cajones[fila], "position:z", destino, 0.30)
	for id in objetos:
		if objetos[id].zona == caja_roja:
			mostrar_objeto(id)


func cerca(posicion: Vector3) -> bool:
	return posicion.distance_squared_to(carrito.global_position) < 9.0


func tomar(id: String, cerca_carrito: bool) -> String:
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
		if objetos[id].zona == mueble and id not in inventario.cinturon and id not in inventario.carrito:
			disponibles.append(id)
	return disponibles


func dejar(id: String, cerca_carrito: bool, mueble: Node3D = mesa) -> String:
	if mueble == caja_roja and Inventario.CATALOGO.get(id, {}).get("tipo") != "herramienta":
		return "La caja roja es para herramientas. Deja este objeto en otro mueble."
	var ranura := 0
	if mueble != caja_roja:
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


func devolver(id: String) -> void:
	superficies.erase(id)
	var objeto: StaticBody3D = objetos[id]
	var origen: Dictionary = origenes[id]
	if objeto.get_parent() != origen.padre:
		objeto.reparent(origen.padre, false)
	objeto.scale = Vector3.ONE
	objeto.position = origen.posicion
	objeto.zona = origen.zona
	mostrar_objeto(id)


func mostrar_objeto(id: String) -> void:
	var objeto: StaticBody3D = objetos[id]
	objeto.visible = id not in inventario.cinturon \
		and (objeto.zona != caja_roja or cajones_abiertos)
	objeto.set_deferred("collision_layer", 2 if objeto.visible and id not in inventario.carrito else 0)


func reiniciar() -> void:
	apagar_guia()
	mano = ""
	lleva_carrito = false
	carrito.position = origen_carrito
	inventario.reiniciar()
	cambiar_cajones(false, true)
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
	var firma := [mano, inventario.cinturon, inventario.carrito, cerca_carrito]
	if firma == ultimo_inventario:
		return
	ultimo_inventario = firma.duplicate(true)
	for numero in range(1, 9):
		var id := objeto_en_espacio(numero)
		var etiqueta_espacio := espacios_hud[numero - 1]
		etiqueta_espacio.text = "%d %s" % [numero, Inventario.CATALOGO.get(id, {}).get("nombre", "—")]
		etiqueta_espacio.modulate = Color("#98a2ad") if numero > 4 and not cerca_carrito else Color.WHITE
		if not id.is_empty() and id == mano:
			etiqueta_espacio.modulate = GUIA


func nombres(ids: Array[String]) -> String:
	var lista := PackedStringArray()
	for id in ids:
		lista.append(Inventario.CATALOGO[id].nombre)
	return ", ".join(lista) if not lista.is_empty() else "Vacío"


func crear_guia() -> void:
	baliza = estanteria.cilindro(self, Vector3.ZERO, 0.28, 2.1, Color(GUIA, 0.25), 16)
	var material := baliza.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	baliza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	baliza.hide()
	contorno.albedo_color = GUIA
	contorno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	contorno.cull_mode = BaseMaterial3D.CULL_FRONT
	contorno.grow = true
	contorno.grow_amount = 0.005
	caducidad = Timer.new()
	caducidad.one_shot = true
	caducidad.wait_time = 30.0
	add_child(caducidad)
	caducidad.timeout.connect(apagar_guia)


func mueble_de(id: String) -> Node3D:
	return carrito if id in inventario.carrito else objetos[id].zona


func ubicacion(id: String) -> String:
	return ubicaciones[mueble_de(id)]


func senalar(id: String) -> void:
	apagar_guia()
	objetivo = id
	var pieza: StaticBody3D = objetos[id]
	var mueble := mueble_de(id)
	for malla in pieza.get_node("Forma").find_children("*", "MeshInstance3D", true, false):
		malla.material_overlay = contorno
	baliza.position = to_local(mueble.global_position) + Vector3.UP * (alturas[mueble] + 1.02)
	baliza.show()
	caducidad.start()


func apagar_guia() -> void:
	if not objetivo.is_empty():
		for malla in objetos[objetivo].get_node("Forma").find_children("*", "MeshInstance3D", true, false):
			malla.material_overlay = null
	objetivo = ""
	baliza.hide()
	flecha.hide()
	caducidad.stop()


func actualizar_flecha(camara: Camera3D, mostrar: bool) -> void:
	if objetivo.is_empty() or not mostrar:
		flecha.hide()
		return
	var pieza: StaticBody3D = objetos[objetivo]
	if pieza.zona == carrito:
		baliza.position = to_local(carrito.global_position) + Vector3.UP * (alturas[carrito] + 1.02)
	var punto := pieza.global_position
	if not pieza.visible:
		punto = baliza.global_position - Vector3.UP
	var rect := camara.get_viewport().get_visible_rect()
	if not camara.is_position_behind(punto) and rect.has_point(camara.unproject_position(punto)):
		flecha.hide()
		return
	var local := camara.to_local(punto)
	var direccion := Vector2(local.x, -local.y)
	if direccion.length_squared() < 0.0001:
		direccion = Vector2.DOWN
	direccion = direccion.normalized()
	var margen := (rect.size / 2.0 - Vector2(65, 80)).max(Vector2.ONE)
	var distancia := minf(margen.x / maxf(absf(direccion.x), 0.001), margen.y / maxf(absf(direccion.y), 0.001))
	flecha.pivot_offset = flecha.size / 2.0
	flecha.position = rect.get_center() + direccion * distancia - flecha.pivot_offset
	flecha.rotation = direccion.angle() + PI / 2.0
	flecha.show()


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
