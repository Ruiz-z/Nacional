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
