extends "res://escenas/zona_base.gd"

const FUENTE := preload("res://logica/simulador/escenario.gd").FUENTE_BZR
const MINIMO := Vector2(-1.55, -5.7)
const MAXIMO := Vector2(1.55, 5.7)
const ENTRADA := Vector3(0.25, 0, -3.65)
const CABINA := Vector3(0.35, 0, -3.95)
const AZUL := Color("#38586a")
const CIELO := Color("#8fc8ed")
const PASAMANOS := Color("#d4aa58")

var pantalla: Label3D
var falla_red := false


func _ready() -> void:
	acceso = "monitor"
	bloque(Vector3(0, -0.08, 0), Vector3(3.3, 0.16, 11.6), Color("#677178"))
	bloque(Vector3(0, 2.59, 0), Vector3(3.3, 0.18, 11.6), MARFIL)
	caja(self, Vector3(0, 0.005, 0.5), Vector3(1.05, 0.01, 10.4), Color("#808990"))
	for lado in [-1, 1]:
		bloque(Vector3(lado * 1.6, 1.25, 0), Vector3(0.1, 2.5, 11.6), MARFIL)
		bloque(Vector3(0, 1.25, lado * 5.75), Vector3(3.1, 2.5, 0.1), MARFIL)
		cilindro(self, Vector3(lado * 0.64, 2.24, 0.6), 0.027, 8.7, PASAMANOS).rotation_degrees.x = 90
		for fila in range(6):
			var z := -2.25 + fila * 1.28
			var x: float = lado * 1.53
			caja(self, Vector3(x, 1.76, z), Vector3(0.06, 0.84, 1.12), ACERO)
			panel_cielo(Vector3(x - lado * 0.04, 1.76, z), Vector3(0.025, 0.72, 1.01))
			bloque(Vector3(lado * 1.04, 0.34, z), Vector3(0.9, 0.68, 0.49), FONDO)
			for ancho in [0.81, 1.27]:
				asiento(lado * ancho, z)
			if fila % 2 == 0:
				cilindro(self, Vector3(lado * 0.64, 1.37, z + 0.35), 0.024, 1.76, PASAMANOS)
		var luz := OmniLight3D.new()
		luz.position = Vector3(0, 2.25, lado * 3.0)
		luz.omni_range = 9
		luz.light_energy = 1.1
		add_child(luz)

	var puerta := pieza(self, "puerta_salida", "Puerta de salida", Vector3(1.48, 1.13, ENTRADA.z),
		Vector3(0.1, 2.26, 1.03), ACERO)
	panel_cielo(puerta.position + Vector3(-0.07, 0.42, 0), Vector3(0.02, 0.9, 0.8))
	rotulo(puerta, Vector3(-0.085, 0.94, 0), "SALIDA", 0.0036).rotation_degrees.y = -90
	caja(puerta, Vector3(-0.09, -0.09, 0), Vector3(0.08, 0.055, 0.73), PASAMANOS)

	panel_cielo(Vector3(0, 1.88, -5.66), Vector3(2.75, 0.94, 0.025))
	bloque(Vector3(0, 0.42, -5.42), Vector3(2.6, 0.84, 0.48), ACERO)
	var tablero := pieza(self, "monitor", "Tablero de instrumentos", Vector3(0.16, 1.34, -5.37),
		Vector3(1.45, 0.41, 0.25), FONDO)
	caja(tablero, Vector3(0, 0, 0.137), Vector3(1.38, 0.32, 0.03), Color("#132c30"))
	pantalla = rotulo(tablero, Vector3(0, 0, 0.156), "", 0.00235)
	pantalla.rotation_degrees.y = 0
	var fuente := rotulo(self, Vector3(0, 2.38, -5.64), FUENTE, 0.0029)
	fuente.rotation_degrees.y = 0
	fuente.modulate = FONDO
	var modulo := pieza(self, "cables", "Módulo de red", Vector3(0.29, 0.68, -5.1),
		Vector3(0.39, 0.26, 0.17), AZUL)
	rotulo(modulo, Vector3(0, 0.035, 0.088), "MÓDULO DE RED", 0.0015).rotation_degrees.y = 0
	for x in [-0.11, 0, 0.11]:
		caja(modulo, Vector3(x, -0.064, 0.09), Vector3(0.06, 0.039, 0.035), MARFIL)
	var fusibles := pieza(self, "fusibles_cabina", "Fusibles de cabina", Vector3(0.91, 0.68, -5.1),
		Vector3(0.32, 0.22, 0.16), FONDO)
	for x in [-0.09, 0, 0.09]:
		caja(fusibles, Vector3(x, 0, 0.088), Vector3(0.052, 0.096, 0.03), PASAMANOS)
	asiento(-0.91, -4.54)
	bloque(Vector3(-0.91, 0.35, -4.54), Vector3(0.44, 0.7, 0.48), FONDO)
	var aro := TorusMesh.new()
	aro.inner_radius = 0.145
	aro.outer_radius = 0.18
	aro.rings = 20
	aro.ring_segments = 10
	superficie(self, Vector3(-0.9, 1.11, -5.05), aro, FONDO).rotation_degrees.x = 56
	caja(self, Vector3(-0.9, 1.11, -5.05), Vector3(0.29, 0.045, 0.055), FONDO)
	for x in [-0.99, -0.8]:
		caja(self, Vector3(x, 0.16, -5.12), Vector3(0.095, 0.05, 0.14), ACERO).rotation_degrees.x = 25
	reflejar_estado({}, false)


func asiento(x: float, z: float) -> void:
	caja(self, Vector3(x, 0.49, z), Vector3(0.41, 0.11, 0.43), AZUL)
	caja(self, Vector3(x, 0.82, z + 0.24), Vector3(0.41, 0.72, 0.105), AZUL)


func bloque(centro: Vector3, tam: Vector3, color: Color) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = centro
	add_child(cuerpo)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	caja(cuerpo, Vector3.ZERO, tam, color)


func panel_cielo(centro: Vector3, tam: Vector3) -> void:
	var vidrio := caja(self, centro, tam, CIELO)
	vidrio.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func reflejar_estado(estado: Dictionary, _falla: bool, _inmediato := false) -> void:
	falla_red = estado.has("resuelto") and not estado.resuelto
	pantalla.text = "BMS · ESS 600 V · " + ("SIN COMUNICACIÓN" if falla_red else "NORMAL")
	pantalla.modulate = Color("#ffab82") if falla_red else Color("#a5edcb")


func lectura_pieza(componente: String) -> String:
	match componente:
		"monitor": return "[MUESTRA] " + pantalla.text
		"cables": return "[MUESTRA] Módulo de red bajo el tablero."
		"fusibles_cabina": return "[MUESTRA] Fusibles de los circuitos de cabina."
	return ""
