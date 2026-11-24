extends "res://escenas/zona_base.gd"

var lentes := {}
var fusible: Interactuable
var chispa: MeshInstance3D
var continuidad := false


func _ready() -> void:
	acceso = "caja_fusibles"
	giro_abierto = Vector3(0, 0, 110)
	# FrontLights del FBX en mundo: x [-1.102,-0.734] y [0.748,1.116],
	# y [0.866,1.056], z [5.480,5.524]. El frente mira a +Z.
	for id in ["faro_izquierdo", "faro_derecho"]:
		var izquierdo: bool = id == "faro_izquierdo"
		var faro := pieza(self, id, "Faro izquierdo" if izquierdo else "Faro derecho",
			Vector3(-0.072, 0, -0.932 if izquierdo else 0.918),
			Vector3(0.105, 0.21, 0.39), FONDO)
		lentes[id] = caja(faro, Vector3(0.057, 0, 0), Vector3(0.022, 0.158, 0.33), MARFIL)
	chispa = caja(piezas.faro_izquierdo, Vector3(0.086, 0.12, 0), Vector3(0.025, 0.11, 0.025),
		Color("#ffd37a"))
	chispa.rotation_degrees.x = 35
	chispa.material_override.emission_enabled = true
	chispa.material_override.emission = Color("#ffd37a")

	caja(self, Vector3(0.025, 0.05, 0), Vector3(0.07, 0.44, 1.22), FONDO)
	for lado in [-1, 1]:
		caja(self, Vector3(0.09, 0.05, lado * 0.595), Vector3(0.16, 0.44, 0.03), ACERO)
		caja(self, Vector3(0.09, 0.05 + lado * 0.205, 0), Vector3(0.16, 0.03, 1.16), ACERO)

	var conector := pieza(self, "conector_faros", "Conector del circuito", Vector3(0.104, 0.05, -0.36),
		Vector3(0.09, 0.15, 0.24), Color("#6c8490"))
	for altura in [-0.04, 0.04]:
		cilindro(conector, Vector3(0.049, altura, 0), 0.014, 0.029, MARFIL).rotation_degrees.z = 90
	fusible = pieza(self, "fusible_faros", "Fusible", Vector3(0.105, 0.05, 0),
		Vector3(0.09, 0.16, 0.19), NARANJA)
	var rele := pieza(self, "rele_faros", "Relé de faros", Vector3(0.105, 0.05, 0.35),
		Vector3(0.09, 0.16, 0.24), ACERO)
	rotulo(rele, Vector3(0.049, 0, 0), "RELÉ", 0.0014)
	bisagra = Node3D.new()
	bisagra.position = Vector3(0.19, 0.27, 0)
	add_child(bisagra)
	var tapa := pieza(bisagra, acceso, "Caja de fusibles", Vector3(0, -0.22, 0),
		Vector3(0.045, 0.44, 1.22), ACERO)
	rotulo(tapa, Vector3(0.025, 0, 0), "CAJA DE FUSIBLES", 0.0020)
	caja(tapa, Vector3(0.027, -0.17, 0), Vector3(0.025, 0.026, 0.19), MARFIL)


func reflejar_estado(estado: Dictionary, falla: bool, inmediato := false) -> void:
	super.reflejar_estado(estado, falla, inmediato)
	for id in lentes:
		var material: StandardMaterial3D = lentes[id].material_override
		material.emission_enabled = estado.get(id, true)
		material.albedo_color = MARFIL if material.emission_enabled else Color("#63747c")
		material.emission = Color("#fff0bd")
	chispa.visible = estado.get("chispa", false)
	fusible.superficie.material_override.albedo_color = FONDO if estado.get("fusible_quemado", false) else NARANJA
	continuidad = estado.get("continuidad_medida", false)


func lectura_pieza(componente: String) -> String:
	if lentes.has(componente):
		return "Faro encendido" if lentes[componente].material_override.emission_enabled else "Faro apagado"
	if componente == "conector_faros" and continuidad:
		return "[MUESTRA] Circuito identificado. Compara ambos faros."
	return super.lectura_pieza(componente)
