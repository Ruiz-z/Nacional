extends "res://escenas/zona_base.gd"

const COLORES_LED := {"Verde": Color("#50ef80"), "Ámbar": Color("#ffbd38"), "Rojo": Color("#ff4545")}

var lectura := "Ámbar"

var lectura_pantalla: Label3D
var led: MeshInstance3D
var tornillo: MeshInstance3D
var fragmento: MeshInstance3D
var chispa: MeshInstance3D


func _ready() -> void:
	caja(self, Vector3(0.015, 0, 0), Vector3(0.03, 0.80, 1.0), FONDO)
	for lado in [-1, 1]:
		caja(self, Vector3(0.12, lado * 0.375, 0), Vector3(0.24, 0.05, 1.0), ACERO)
		caja(self, Vector3(0.12, 0, lado * 0.475), Vector3(0.24, 0.70, 0.05), ACERO)
	bisagra = Node3D.new()
	bisagra.position = Vector3(0.225, 0, -0.45)
	add_child(bisagra)
	var puerta := pieza(bisagra, "compuerta", "Compuerta", Vector3(0, 0, 0.45),
		Vector3(0.05, 0.70, 0.90), NARANJA)
	caja(puerta, Vector3(0.032, -0.03, 0.36), Vector3(0.035, 0.033, 0.10), FONDO)
	for altura in [-0.24, 0.24]:
		cilindro(bisagra, Vector3(0, altura, 0), 0.027, 0.09, ACERO)

	var monitor := pieza(self, "monitor", "Monitor de aislamiento", Vector3(0.125, 0.20, 0.23),
		Vector3(0.15, 0.22, 0.34), ACERO)
	var pantalla := caja(monitor, Vector3(0.080, 0.021, 0), Vector3(0.01, 0.106, 0.28),
		Color("#286044"))
	lectura_pantalla = rotulo(monitor, Vector3(0.087, 0.021, 0), "AISL. —", 0.0013)
	var luz := pantalla.material_override as StandardMaterial3D
	luz.emission_enabled = true
	luz.emission = luz.albedo_color
	led = caja(monitor, Vector3(0.082, -0.074, 0.11), Vector3(0.015, 0.03, 0.03), MARFIL)

	var cables := pieza(self, "cables", "Cables y contactor", Vector3(0.10, 0.15, -0.20),
		Vector3(0.15, 0.22, 0.44), FONDO)
	cables.superficie.visible = false
	cables.superficie = caja(cables, Vector3(0.01, 0, 0.105), Vector3(0.14, 0.19, 0.17), Color("#131719"))
	for altura in [-0.055, 0.055]:
		cilindro(cables, Vector3(0.08, altura, 0.055), 0.022, 0.025, MARFIL).rotation_degrees.z = 90
		cilindro(cables, Vector3(0.085, altura, -0.061), 0.016, 0.24, NARANJA).rotation_degrees.x = 90
		cilindro(cables, Vector3(0.085, altura - 0.06, -0.181), 0.016, 0.12, NARANJA)

	var bateria := pieza(self, "bateria", "Paquete de batería", Vector3(0.12, -0.19, 0.10),
		Vector3(0.17, 0.24, 0.64), Color("#555f65"))
	for indice in range(4):
		var z := -0.24 + indice * 0.16
		caja(bateria, Vector3(0.073, 0.028, z), Vector3(0.043, 0.14, 0.13), Color("#818b90"))
		caja(bateria, Vector3(0.098, 0.063, z), Vector3(0.012, 0.022, 0.065), ACERO)
	var terminal := pieza(self, "terminal", "Terminal", Vector3(0.13, -0.12, -0.34),
		Vector3(0.18, 0.17, 0.16), ACERO)
	cilindro(terminal, Vector3(0.089, 0.014, 0), 0.048, 0.027, MARFIL).rotation_degrees.z = 90
	tornillo = cilindro(terminal, Vector3(0.112, 0.014, 0), 0.032, 0.034, MARFIL, 6)
	tornillo.rotation_degrees.z = 90
	fragmento = cilindro(terminal, Vector3(0.111, -0.048, 0.027), 0.028, 0.027, MARFIL, 6)
	fragmento.rotation_degrees.z = 55
	chispa = caja(terminal, Vector3(0.124, 0.066, -0.045), Vector3(0.018, 0.077, 0.014), Color("#ffd37a"))
	chispa.rotation_degrees.x = 40
	var brillo := chispa.material_override as StandardMaterial3D
	brillo.emission_enabled = true
	brillo.emission = Color("#ffd37a")
	caja(chispa, Vector3(0, 0.015, 0.006), Vector3(0.016, 0.013, 0.05), Color("#ffd37a"))
	abrir(false, true)


func reflejar_estado(estado: Dictionary, falla: bool, inmediato := false) -> void:
	super.reflejar_estado(estado, falla, inmediato)
	var dano: bool = estado.get("tornillo_roto", false)
	tornillo.visible = not dano
	fragmento.visible = dano
	chispa.visible = dano
	var comprobado: bool = estado.get("indicio_confirmado", estado.get("sintomas_revisados", false))
	lectura = "Rojo" if falla or dano else ("Verde" if comprobado else "Ámbar")
	lectura_pantalla.text = "AISL. BAJA" if lectura == "Rojo" else ("AISL. OK" if comprobado else "AISL. —")
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
