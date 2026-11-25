extends RefCounted

const Zona = preload("res://escenas/zona_base.gd")
const GOMA := Color("#272f34")
const PLATA := Color("#d7e6db")
const DIELECTRICOS := Color("#e7652d")
const TRABAJO := Color("#79838e")


static func construir(zona: Zona, padre: Node3D, id: String) -> void:
	match id:
		"casco":
			var amarillo := Color("#ffc436")
			ovalo(zona, padre, Vector3(0, 0.015, -0.025), Vector3(0.24, 0.17, 0.24), amarillo, true)
			var ala := zona.cilindro(padre, Vector3(0, 0.012, 0.005), 0.13, 0.019, amarillo)
			ala.scale.z = 1.27
			zona.caja(padre, Vector3(0, 0.096, -0.025), Vector3(0.028, 0.018, 0.08), amarillo)
		"gafas":
			for lado in [-1, 1]:
				var x: float = lado * 0.061
				zona.caja(padre, Vector3(x, 0.064, 0.044), Vector3(0.111, 0.009, 0.014), PLATA)
				visor(zona, padre, Vector3(x, 0.034, 0.043), Vector3(0.103, 0.055, 0.009))
				zona.caja(padre, Vector3(lado * 0.112, 0.051, -0.013), Vector3(0.013, 0.013, 0.122), GOMA)
			zona.caja(padre, Vector3(0, 0.045, 0.046), Vector3(0.031, 0.015, 0.012), PLATA)
		"careta":
			var diadema := zona.cilindro(padre, Vector3(0, 0.222, -0.03), 0.133, 0.039, GOMA)
			diadema.scale.z = 0.79
			visor(zona, padre, Vector3(0, 0.112, 0.091), Vector3(0.214, 0.184, 0.012))
			for lado in [-1, 1]:
				var borde := visor(zona, padre, Vector3(lado * 0.129, 0.116, 0.074), Vector3(0.062, 0.174, 0.012))
				borde.rotation_degrees.y = lado * 38
			zona.caja(padre, Vector3(0, 0.022, 0.09), Vector3(0.215, 0.013, 0.015), GOMA)
		"guantes_dielectricos", "guantes_trabajo":
			var largo := id == "guantes_dielectricos"
			guante(zona, padre, -0.10, 1, largo)
			guante(zona, padre, 0.10, -1, largo)
		"calzado_dielectrico", "botas":
			var bota := id == "botas"
			for lado in [-1, 1]:
				var x: float = lado * 0.077
				var cuero := Color("#8e573a") if bota else Color("#181e23")
				zona.caja(padre, Vector3(x, 0.024, 0), Vector3(0.134, 0.047, 0.255), GOMA if bota else Color("#727a6a"))
				ovalo(zona, padre, Vector3(x, 0.075, 0.009), Vector3(0.126, 0.103, 0.242), cuero)
				zona.caja(padre, Vector3(x, 0.104 if bota else 0.076, -0.053),
					Vector3(0.109, 0.16 if bota else 0.096, 0.122), cuero)
				if bota:
					ovalo(zona, padre, Vector3(x, 0.065, 0.081), Vector3(0.124, 0.07, 0.101), Color("#b6a494"))
		"chaleco":
			var naranja := Color("#f87c2a")
			zona.caja(padre, Vector3(0, 0.093, 0), Vector3(0.278, 0.186, 0.048), naranja)
			for lado in [-1, 1]:
				var tirante := zona.caja(padre, Vector3(lado * 0.084, 0.215, 0), Vector3(0.085, 0.092, 0.048), naranja)
				tirante.rotation_degrees.z = lado * 14
				zona.caja(padre, Vector3(lado * 0.081, 0.143, 0.027), Vector3(0.025, 0.178, 0.006), PLATA)
			zona.caja(padre, Vector3(0, 0.066, 0.027), Vector3(0.278, 0.027, 0.006), PLATA)
			zona.caja(padre, Vector3(0, 0.093, 0.033), Vector3(0.009, 0.186, 0.006), GOMA)
		"proteccion_auditiva":
			var arco := TorusMesh.new()
			arco.inner_radius = 0.101
			arco.outer_radius = 0.12
			arco.rings = 16
			arco.ring_segments = 8
			zona.superficie(padre, Vector3(0, 0.135, -0.018), arco, GOMA).rotation_degrees.x = 90
			for lado in [-1, 1]:
				ovalo(zona, padre, Vector3(lado * 0.104, 0.078, 0.002), Vector3(0.09, 0.143, 0.11), Color("#e6a731"))
				ovalo(zona, padre, Vector3(lado * 0.074, 0.078, 0.005), Vector3(0.034, 0.124, 0.106), GOMA)


static func guante(zona: Zona, padre: Node3D, x: float, lado: int, largo: bool) -> void:
	var color := DIELECTRICOS if largo else TRABAJO
	var puno := 0.12 if largo else 0.048
	zona.caja(padre, Vector3(x, puno / 2, 0), Vector3(0.101, puno, 0.053), color.darkened(0.14))
	ovalo(zona, padre, Vector3(x, puno + 0.039, 0.005), Vector3(0.092, 0.102, 0.053), color)
	for dedo in range(4):
		var alto := 0.048 if dedo in [1, 2] else 0.036
		ovalo(zona, padre, Vector3(x + (dedo - 1.5) * 0.023, puno + 0.086, 0.005),
			Vector3(0.023, alto, 0.034), color)
	var pulgar := ovalo(zona, padre, Vector3(x + lado * 0.051, puno + 0.039, 0.014),
		Vector3(0.026, 0.059, 0.035), color)
	pulgar.rotation_degrees.z = -lado * 28


static func ovalo(zona: Zona, padre: Node3D, centro: Vector3, tam: Vector3, color: Color,
		hemisferio := false) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = 0.5
	malla.height = 1.0
	malla.radial_segments = 12
	malla.rings = 6
	malla.is_hemisphere = hemisferio
	var pieza := zona.superficie(padre, centro, malla, color)
	pieza.scale = tam
	return pieza


static func visor(zona: Zona, padre: Node3D, centro: Vector3, tam: Vector3) -> MeshInstance3D:
	var pieza := zona.caja(padre, centro, tam, Color("#a4e9ef70"))
	var material := pieza.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.21
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pieza
