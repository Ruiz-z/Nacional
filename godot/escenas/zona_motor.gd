extends "res://escenas/zona_base.gd"

const FUENTE := preload("res://logica/simulador/escenario.gd").FUENTE_BZR

var pantalla: Label3D
var abrazadera: Interactuable
var lectura := ""
var aviso := ""


func _ready() -> void:
	acceso = "tapa_motor"
	nombre_acceso = "la tapa del motor"
	giro_abierto = Vector3(0, 0, 105)
	# La franja de servicio queda por encima de RearLights y debajo de la luneta.
	var ancho := 1.70
	var alto := 0.87
	var centro := 0.065
	metal(caja(self, Vector3(0.017, centro, 0), Vector3(0.035, alto, ancho), FONDO))
	for lado in [-1, 1]:
		metal(caja(self, Vector3(0.10, centro + lado * 0.42, 0),
			Vector3(0.19, 0.03, ancho), ACERO))
		metal(caja(self, Vector3(0.10, centro, lado * 0.836),
			Vector3(0.19, 0.83, 0.028), ACERO))

	var motor := pieza(self, "motor_traccion", "Motor eléctrico de tracción", Vector3(0.095, -0.171, 0.36),
		Vector3(0.19, 0.30, 0.77), ACERO)
	motor.superficie.visible = false
	# La carcasa anterior atravesaba la tapa cerrada. La profundidad deja todo el motor detrás de la junta.
	var carcasa := metal(cilindro(motor, Vector3(-0.008, 0, 0), 0.128, 0.62, Color("#979fa5"), 20))
	carcasa.rotation_degrees.x = 90
	carcasa.scale.x = 0.70
	for indice in range(9):
		var aleta := metal(cilindro(motor, Vector3(-0.008, 0, (indice - 4) * 0.058),
			0.144, 0.016, Color("#687781"), 20))
		aleta.rotation_degrees.x = 90
		aleta.scale.x = 0.70
	for lado in [-1, 1]:
		var cabezal := metal(cilindro(motor, Vector3(-0.008, 0, lado * 0.325),
			0.115, 0.044, MARFIL, 16))
		cabezal.rotation_degrees.x = 90
		cabezal.scale.x = 0.76

	var inversor := pieza(self, "inversor_motor", "Inversor y cables naranja", Vector3(0.081, 0.308, 0.43),
		Vector3(0.131, 0.175, 0.59), Color("#969da2"))
	metal(inversor.superficie)
	for indice in range(8):
		caja(inversor, Vector3(0.069, 0.039, (indice - 3.5) * 0.062),
			Vector3(0.011, 0.053, 0.012), ACERO)
	for z in [-0.17, 0, 0.17]:
		metal(cilindro(inversor, Vector3(0.053, -0.095, z), 0.031, 0.035, Color("#5d6870"), 8))
		cilindro(inversor, Vector3(0.053, -0.188, z), 0.022, 0.19, NARANJA).rotation_degrees.x = 8
		metal(cilindro(inversor, Vector3(0.053, -0.283, z - 0.013), 0.029, 0.033, ACERO, 8))

	var bomba := pieza(self, "bomba_motor", "Bomba de enfriamiento", Vector3(0.085, -0.19, -0.25),
		Vector3(0.15, 0.21, 0.23), ACERO)
	bomba.superficie.visible = false
	metal(cilindro(bomba, Vector3(0.023, 0, 0), 0.098, 0.126,
		Color("#668594"), 18)).rotation_degrees.z = 90
	metal(cilindro(bomba, Vector3(0.087, 0, 0), 0.063, 0.018, MARFIL, 12)).rotation_degrees.z = 90
	for indice in range(4):
		var angulo := indice * TAU / 4
		metal(cilindro(bomba, Vector3(0.09, sin(angulo) * 0.079, cos(angulo) * 0.079),
			0.01, 0.02, ACERO, 6)).rotation_degrees.z = 90
	cilindro(bomba, Vector3(0.038, 0, -0.124), 0.032, 0.158, FONDO).rotation_degrees.x = 90
	cilindro(bomba, Vector3(0.038, 0.114, 0), 0.031, 0.12, FONDO)

	var radiador := pieza(self, "radiador_motor", "Radiador de enfriamiento", Vector3(0.09, -0.065, -0.615),
		Vector3(0.15, 0.52, 0.32), FONDO)
	for fila in range(16):
		metal(caja(radiador, Vector3(0.075, (fila - 7.5) * 0.029, 0),
			Vector3(0.017, 0.008, 0.272), Color("#838d92")))
	for lado in [-1, 1]:
		metal(caja(radiador, Vector3(0.083, 0, lado * 0.147),
			Vector3(0.024, 0.50, 0.02), MARFIL))
	abrazadera = pieza(self, "abrazadera_motor", "Abrazadera del refrigerante", Vector3(0.123, -0.03, -0.25),
		Vector3(0.085, 0.086, 0.121), MARFIL)
	metal(abrazadera.superficie)
	cilindro(abrazadera, Vector3(0.021, 0, 0), 0.034, 0.049, ACERO)

	var monitor := pieza(self, "monitor_temperatura", "Monitor de temperatura", Vector3(0.086, 0.311, -0.426),
		Vector3(0.133, 0.199, 0.57), ACERO)
	var vidrio := caja(monitor, Vector3(0.071, 0.008, 0), Vector3(0.014, 0.136, 0.48), Color("#142e30"))
	vidrio.material_override.emission_enabled = true
	vidrio.material_override.emission = Color("#183032")
	pantalla = rotulo(monitor, Vector3(0.08, 0.012, 0), "", 0.00092)

	tapa_superior("Tapa del motor eléctrico", Vector3(0.213, 0.50, 0), alto, ancho, "⚠  ALTA TENSIÓN")



func reflejar_estado(estado: Dictionary, falla: bool, inmediato := false) -> void:
	super.reflejar_estado(estado, falla, inmediato)
	var alerta: bool = estado.get("alerta_temperatura", false)
	aviso = estado.get("aviso", "") if alerta else ""
	lectura = "TEMPERATURA · ALERTA" if alerta else "TEMPERATURA · NORMAL"
	pantalla.text = "ALERTA °C" if alerta else "TEMP. NORMAL"
	pantalla.modulate = Color("#ffb850") if alerta else Color("#9de9c2")
	abrazadera.superficie.material_override.albedo_color = (
		Color("#c7483b") if estado.get("pieza_danada", false) else MARFIL)


func lectura_pieza(componente: String) -> String:
	match componente:
		"motor_traccion":
			return "Motor de hasta 200 kW · Transmisión automática de 2 velocidades\n" + FUENTE
		"inversor_motor":
			return "ESS de 600 V · BMS que supervisa el estado de las baterías\n" + FUENTE
		"monitor_temperatura":
			return "[MUESTRA] %s\nESS con control automático de temperatura\n%s" % [
				aviso if not aviso.is_empty() else lectura, FUENTE]
		"abrazadera_motor":
			return "[MUESTRA] Rango de apriete simulado"
	return super.lectura_pieza(componente)
