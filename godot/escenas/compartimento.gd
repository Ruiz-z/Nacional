extends Node3D

const Interactuable = preload("res://escenas/interactuable.gd")
const ACERO := Color("#354550")
const FONDO := Color("#202b31")
const NARANJA := Color("#ed792b")
const MARFIL := Color("#e4e8e6")
const COLORES_LED := {"Verde": Color("#50ef80"), "Ámbar": Color("#ffbd38"), "Rojo": Color("#ff4545")}

var lectura := "Ámbar"

var piezas := {}
var bisagra: Node3D
var animacion: Tween
var abierta := false
var led: MeshInstance3D
var tornillo: MeshInstance3D
var fragmento: MeshInstance3D
var chispa: MeshInstance3D


func _ready() -> void:
	caja(self, Vector3(0.04, 0, 0), Vector3(0.08, 1.02, 1.62), FONDO)
	for lado in [-1, 1]:
		caja(self, Vector3(0.20, lado * 0.49, 0), Vector3(0.40, 0.04, 1.62), ACERO)
		caja(self, Vector3(0.20, 0, lado * 0.79), Vector3(0.40, 1.02, 0.04), ACERO)
	bisagra = Node3D.new()
	bisagra.position = Vector3(0.42, 0, -0.81)
	add_child(bisagra)
	var puerta := pieza(bisagra, "compuerta", "Compuerta", Vector3(0, 0, 0.81),
		Vector3(0.07, 1.02, 1.62), Color("#b58420"))
	caja(puerta, Vector3(0.062, -0.11, 0.54), Vector3(0.07, 0.065, 0.29), FONDO)
	rotulo(puerta, Vector3(0.04, 0.17, 0), "GABINETE DE SERVICIO", 0.0035)

	var monitor := pieza(self, "monitor", "Monitor", Vector3(0.23, 0.29, 0.34),
		Vector3(0.22, 0.29, 0.65), ACERO)
	caja(monitor, Vector3(0.117, 0.030, 0), Vector3(0.018, 0.15, 0.51), FONDO)
	rotulo(monitor, Vector3(0.129, 0.034, 0), "MONITOR", 0.0027)
	led = caja(monitor, Vector3(0.125, -0.098, 0.22), Vector3(0.03, 0.042, 0.042), MARFIL)

	var cables := pieza(self, "cables", "Cables naranjas", Vector3(0.20, 0.28, -0.43),
		Vector3(0.28, 0.28, 0.53), FONDO)
	for altura in [-0.073, 0.0, 0.073]:
		cilindro(cables, Vector3(0.155, altura, 0), 0.024, 0.46, NARANJA).rotation_degrees.x = 90.0
	caja(cables, Vector3(0.16, 0, -0.23), Vector3(0.10, 0.22, 0.10), ACERO)

	var bateria := pieza(self, "bateria", "Paquete de batería", Vector3(0.22, -0.25, 0.11),
		Vector3(0.33, 0.32, 1.13), Color("#315058"))
	rotulo(bateria, Vector3(0.168, 0, 0), "PAQUETE DE BATERÍA", 0.0025)
	var terminal := pieza(self, "terminal", "Terminal", Vector3(0.22, -0.12, -0.61),
		Vector3(0.28, 0.27, 0.23), ACERO)
	tornillo = cilindro(terminal, Vector3(0.173, 0.04, 0), 0.053, 0.085, MARFIL)
	tornillo.rotation_degrees.z = 90.0
	fragmento = cilindro(terminal, Vector3(0.166, -0.04, 0.021), 0.053, 0.045, MARFIL)
	fragmento.rotation_degrees.z = 55.0
	chispa = caja(terminal, Vector3(0.177, 0.105, -0.045), Vector3(0.023, 0.073, 0.02), Color("#ffd37a"))
	chispa.rotation_degrees.x = 40.0
	var brillo := chispa.material_override as StandardMaterial3D
	brillo.emission_enabled = true
	brillo.emission = Color("#ffd37a")


func reflejar_estado(estado: Dictionary, falla: bool) -> void:
	abrir(estado.get("inspeccionado", true))
	var dano: bool = estado.get("tornillo_roto", false)
	tornillo.visible = not dano
	fragmento.visible = dano
	chispa.visible = dano
	var comprobado: bool = estado.get("indicio_confirmado", estado.get("sintomas_revisados", false))
	lectura = "Rojo" if falla or dano else ("Verde" if comprobado else "Ámbar")
	var material := led.material_override as StandardMaterial3D
	material.albedo_color = COLORES_LED[lectura]
	material.emission = material.albedo_color
	material.emission_enabled = true


func lectura_pieza(componente: String) -> String:
	match componente:
		"compuerta":
			return "Abierta" if abierta else "Cerrada"
		"monitor":
			return "LED · %s" % lectura
		"terminal":
			return "Tornillo intacto" if tornillo.visible else "Tornillo roto"
	return ""


func abrir(valor: bool) -> void:
	if valor == abierta:
		return
	abierta = valor
	if animacion != null:
		animacion.kill()
	animacion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(bisagra, "rotation:y", deg_to_rad(108.0) if abierta else 0.0, 0.42)


func pieza(padre: Node3D, id: String, nombre: String, centro: Vector3, tam: Vector3,
		color: Color) -> StaticBody3D:
	var cuerpo := Interactuable.new()
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


func cilindro(padre: Node3D, centro: Vector3, radio: float, alto: float, color: Color) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = alto
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


func rotulo(padre: Node3D, centro: Vector3, texto: String, escala: float) -> void:
	var etiqueta := Label3D.new()
	etiqueta.position = centro
	etiqueta.rotation_degrees.y = 90.0
	etiqueta.pixel_size = escala
	etiqueta.font_size = 26
	etiqueta.outline_size = 2
	etiqueta.text = texto
	padre.add_child(etiqueta)
