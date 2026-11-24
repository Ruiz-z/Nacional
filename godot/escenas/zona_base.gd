extends Node3D

const Interactuable = preload("res://escenas/interactuable.gd")
const ACERO := Color("#354550")
const FONDO := Color("#202b31")
const NARANJA := Color("#ed792b")
const MARFIL := Color("#e4e8e6")

var acceso := "compuerta"
var piezas := {}
var bisagra: Node3D
var animacion: Tween
var luz_servicio: OmniLight3D
var abierta := false
var giro_abierto := Vector3(0, 100, 0)


func reflejar_estado(estado: Dictionary, _falla: bool, inmediato := false) -> void:
	abrir(estado.get("inspeccionado", false), inmediato)


func lectura_pieza(componente: String) -> String:
	if componente == acceso:
		return "Abierta" if abierta else "Cerrada"
	return ""


func abrir(valor: bool, inmediato: bool) -> void:
	if valor == abierta and not inmediato:
		return
	abierta = valor
	if luz_servicio != null:
		luz_servicio.visible = abierta
	if animacion != null:
		animacion.kill()
	var destino := giro_abierto if abierta else Vector3.ZERO
	if inmediato:
		bisagra.rotation_degrees = destino
		return
	animacion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(bisagra, "rotation_degrees", destino, 0.42)


func pieza(padre: Node3D, id: String, nombre: String, centro: Vector3, tam: Vector3,
		color: Color) -> Interactuable:
	var cuerpo := Interactuable.new()
	cuerpo.zona = self
	cuerpo.componente = id
	cuerpo.nombre = nombre
	cuerpo.position = centro
	cuerpo.collision_layer = 2
	cuerpo.collision_mask = 0
	padre.add_child(cuerpo)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	cuerpo.superficie = caja(cuerpo, Vector3.ZERO, tam, color)
	piezas[id] = cuerpo
	return cuerpo


func caja(padre: Node3D, centro: Vector3, tam: Vector3, color: Color) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	return superficie(padre, centro, malla, color)


func cilindro(padre: Node3D, centro: Vector3, radio: float, alto: float, color: Color, lados := 12) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = alto
	malla.radial_segments = lados
	malla.rings = 0
	return superficie(padre, centro, malla, color)


func superficie(padre: Node3D, centro: Vector3, malla: Mesh, color: Color) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	objeto.mesh = malla
	objeto.material_override = material
	objeto.position = centro
	padre.add_child(objeto)
	return objeto


func rotulo(padre: Node3D, centro: Vector3, texto: String, escala: float) -> Label3D:
	var etiqueta := Label3D.new()
	etiqueta.position = centro
	etiqueta.rotation_degrees.y = 90.0
	etiqueta.pixel_size = escala
	etiqueta.font_size = 26
	etiqueta.outline_size = 2
	etiqueta.text = texto
	padre.add_child(etiqueta)
	return etiqueta


func metal(objeto: MeshInstance3D, pulido := 0.45) -> MeshInstance3D:
	var material := objeto.material_override as StandardMaterial3D
	material.metallic = pulido
	material.roughness = 0.34
	return objeto


func tapa_superior(nombre: String, eje: Vector3, alto: float, ancho: float,
		advertencia: String) -> void:
	bisagra = Node3D.new()
	bisagra.position = eje
	add_child(bisagra)
	var tapa := pieza(bisagra, acceso, nombre, Vector3(0, -alto / 2, 0),
		Vector3(0.048, alto, ancho), Color("#f3f3ee"))
	caja(tapa, Vector3(-0.023, 0, 0), Vector3(0.02, alto + 0.018, ancho + 0.018), FONDO)
	caja(tapa, Vector3(-0.036, 0, 0), Vector3(0.01, alto - 0.055, ancho - 0.055), Color("#b9bebd"))
	var altura_manija := -alto / 2 + 0.06
	for lado in [-1, 1]:
		caja(tapa, Vector3(0.035, altura_manija, lado * 0.064), Vector3(0.029, 0.026, 0.024), FONDO)
		metal(cilindro(bisagra, Vector3(0.012, 0, lado * ancho * 0.33),
			0.018, 0.1, Color("#687177"))).rotation_degrees.x = 90
	metal(cilindro(tapa, Vector3(0.052, altura_manija, 0), 0.011, 0.15, ACERO)).rotation_degrees.x = 90
	var centro_aviso := Vector3(0.025, -alto * 0.14, ancho * 0.31)
	caja(tapa, centro_aviso, Vector3(0.003, 0.05, 0.16), Color("#eac556"))
	var aviso := rotulo(tapa, centro_aviso + Vector3(0.002, 0, 0), advertencia, 0.00041)
	aviso.modulate = Color("#272211")
	aviso.outline_size = 0

	luz_servicio = OmniLight3D.new()
	luz_servicio.position = Vector3(eje.x + 0.16, eje.y - 0.075, 0)
	luz_servicio.light_color = Color("#fff1d9")
	luz_servicio.light_energy = 0.62
	luz_servicio.omni_range = maxf(ancho, 0.95)
	luz_servicio.hide()
	add_child(luz_servicio)
