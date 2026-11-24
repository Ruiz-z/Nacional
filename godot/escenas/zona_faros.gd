extends "res://escenas/zona_base.gd"

var lentes := {}
var fusible: Interactuable
var chispa: MeshInstance3D
var continuidad := false


func _ready() -> void:
	acceso = "caja_fusibles"
	nombre_acceso = "la caja de fusibles"
	giro_abierto = Vector3(0, 0, 110)
	# FrontLights del FBX en mundo: x [-1.102,-0.734] y [0.748,1.116],
	# y [0.866,1.056], z [5.480,5.524]. El frente mira a +Z.
	for id in ["faro_izquierdo", "faro_derecho"]:
		var izquierdo: bool = id == "faro_izquierdo"
		# El alcance toca el volumen del casco en z=5.635 antes de llegar al cristal del FBX.
		# El volumen seleccionable sobresale del casco y la óptica queda sobre el faro real.
		var faro := pieza(self, id, "Faro izquierdo" if izquierdo else "Faro derecho",
			Vector3(-0.052, 0, -0.932 if izquierdo else 0.918),
			Vector3(0.118, 0.192, 0.37), FONDO)
		faro.superficie.visible = false
		var aro := metal(cilindro(faro, Vector3(-0.055, 0, 0), 0.09, 0.038, MARFIL, 24), 0.68)
		aro.rotation_degrees.z = 90
		aro.scale.z = 2.04
		var reflector := metal(cilindro(faro, Vector3(-0.031, 0, 0), 0.079, 0.02, Color("#626e77"), 24))
		reflector.rotation_degrees.z = 90
		reflector.scale.z = 2.03
		var lente := cilindro(faro, Vector3(-0.015, 0, 0), 0.073, 0.019, MARFIL, 24)
		lente.rotation_degrees.z = 90
		lente.scale.z = 2.02
		lente.material_override.roughness = 0.21
		lente.material_override.emission_energy_multiplier = 0.53
		lentes[id] = lente
	chispa = caja(piezas.faro_izquierdo, Vector3(0.012, 0.105, 0), Vector3(0.021, 0.075, 0.021),
		Color("#ffd37a"))
	chispa.rotation_degrees.x = 35
	chispa.material_override.emission_enabled = true
	chispa.material_override.emission = Color("#ffd37a")

	var ancho := 0.79
	var alto := 0.33
	metal(caja(self, Vector3(0.015, 0.085, 0), Vector3(0.04, alto, ancho), FONDO))
	for lado in [-1, 1]:
		metal(caja(self, Vector3(0.071, 0.085, lado * 0.386), Vector3(0.12, alto, 0.018), ACERO))
		metal(caja(self, Vector3(0.071, 0.085 + lado * 0.154, 0), Vector3(0.12, 0.022, ancho), ACERO))

	var conector := pieza(self, "conector_faros", "Conector del circuito", Vector3(0.071, 0.08, -0.262),
		Vector3(0.078, 0.108, 0.151), Color("#475662"))
	for altura in [-0.027, 0.027]:
		metal(cilindro(conector, Vector3(0.039, altura, 0), 0.011, 0.016, MARFIL)).rotation_degrees.z = 90
	fusible = pieza(self, "fusible_faros", "Fusibles", Vector3(0.069, 0.08, 0),
		Vector3(0.071, 0.195, 0.293), FONDO)
	var colores := [Color("#d45246"), Color("#3e8ab6"), Color("#e8bc4b"), Color("#69a57e")]
	for fila in range(2):
		for columna in range(colores.size()):
			var centro := Vector3(0.043, (fila - 0.5) * 0.075, (columna - 1.5) * 0.065)
			caja(fusible, centro, Vector3(0.026, 0.046, 0.046), colores[columna])
			for lado in [-1, 1]:
				metal(caja(fusible, centro + Vector3(0.012, lado * 0.009, 0),
					Vector3(0.005, 0.006, 0.028), MARFIL))
	var rele := pieza(self, "rele_faros", "Relé de faros", Vector3(0.078, 0.08, 0.252),
		Vector3(0.087, 0.126, 0.132), ACERO)
	rotulo(rele, Vector3(0.045, 0, 0), "RELÉ", 0.00066)
	tapa_superior("Caja de fusibles", Vector3(0.143, 0.25, 0), alto, ancho, "⚠  ELÉCTRICO")



func es_pieza_interna(componente: String) -> bool:
	return super.es_pieza_interna(componente) and not lentes.has(componente)


func reflejar_estado(estado: Dictionary, falla: bool, inmediato := false) -> void:
	super.reflejar_estado(estado, falla, inmediato)
	for id in lentes:
		var material: StandardMaterial3D = lentes[id].material_override
		material.emission_enabled = estado.get(id, true)
		material.albedo_color = MARFIL if material.emission_enabled else Color("#63747c")
		material.emission = Color("#fff0bd")
	chispa.visible = estado.get("chispa", false)
	fusible.superficie.material_override.albedo_color = (
		Color("#692d27") if estado.get("fusible_quemado", false) else FONDO)
	continuidad = estado.get("continuidad_medida", false)


func lectura_pieza(componente: String) -> String:
	if lentes.has(componente):
		return "Faro encendido" if lentes[componente].material_override.emission_enabled else "Faro apagado"
	if componente == "conector_faros" and continuidad:
		return "[MUESTRA] Circuito identificado. Compara ambos faros."
	return super.lectura_pieza(componente)
