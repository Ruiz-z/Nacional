extends "res://escenas/zona_base.gd"

const FUENTE := preload("res://logica/simulador/escenario.gd").FUENTE_BZR

var pantalla: Label3D
var abrazadera: Interactuable
var lectura := ""
var aviso := ""


func _ready() -> void:
	acceso = "tapa_motor"
	giro_abierto = Vector3(0, 0, 105)
	# RearLights del FBX en mundo: z [-5.635,-5.620], y [0.518,0.789],
	# x [-0.995,-0.581] y [0.596,1.009]. La tapa ocupa la franja central
	# sobre las luces, bajo la ventana trasera (y >= 1.691).
	caja(self, Vector3(0.027, 0, 0), Vector3(0.05, 1.02, 1.76), FONDO)
	for lado in [-1, 1]:
		caja(self, Vector3(0.12, lado * 0.49, 0), Vector3(0.24, 0.04, 1.76), ACERO)
		caja(self, Vector3(0.12, 0, lado * 0.86), Vector3(0.24, 0.94, 0.04), ACERO)

	var motor := pieza(self, "motor_traccion", "Motor eléctrico de tracción", Vector3(0.12, -0.23, 0.36),
		Vector3(0.17, 0.35, 0.77), ACERO)
	cilindro(motor, Vector3(0.069, 0.015, 0), 0.135, 0.62, Color("#8799a6")).rotation_degrees.x = 90
	for z in [-0.23, -0.12, 0, 0.12, 0.23]:
		cilindro(motor, Vector3(0.069, 0.015, z), 0.144, 0.023, ACERO).rotation_degrees.x = 90
	rotulo(motor, Vector3(0.221, -0.045, 0), "200 kW MÁX. · 2 VELOCIDADES", 0.0015)

	var inversor := pieza(self, "inversor_motor", "Inversor y cables naranja", Vector3(0.12, 0.28, 0.43),
		Vector3(0.16, 0.23, 0.59), ACERO)
	for z in [-0.17, 0, 0.17]:
		cilindro(inversor, Vector3(0.086, -0.128, z), 0.025, 0.16, NARANJA)
	rotulo(inversor, Vector3(0.084, 0.028, 0), "ESS 600 V · BMS", 0.0016)

	var bomba := pieza(self, "bomba_motor", "Bomba de enfriamiento", Vector3(0.118, -0.24, -0.25),
		Vector3(0.15, 0.26, 0.26), ACERO)
	cilindro(bomba, Vector3(0.074, 0, 0), 0.105, 0.08, Color("#718996")).rotation_degrees.z = 90
	var radiador := pieza(self, "radiador_motor", "Radiador de enfriamiento", Vector3(0.12, -0.12, -0.62),
		Vector3(0.15, 0.48, 0.31), FONDO)
	for fila in range(8):
		caja(radiador, Vector3(0.08, -0.204 + fila * 0.058, 0), Vector3(0.02, 0.011, 0.27), ACERO)
	abrazadera = pieza(self, "abrazadera_motor", "Abrazadera del refrigerante", Vector3(0.137, 0.005, -0.25),
		Vector3(0.15, 0.13, 0.16), MARFIL)
	cilindro(abrazadera, Vector3(0.07, 0.012, 0), 0.05, 0.045, ACERO).rotation_degrees.x = 90

	var monitor := pieza(self, "monitor_temperatura", "Monitor de temperatura", Vector3(0.122, 0.28, -0.39),
		Vector3(0.16, 0.26, 0.68), ACERO)
	caja(monitor, Vector3(0.083, 0, 0), Vector3(0.015, 0.17, 0.60), Color("#142e30"))
	pantalla = rotulo(monitor, Vector3(0.094, 0, 0), "", 0.0017)
	rotulo(self, Vector3(0.08, -0.455, 0), FUENTE, 0.00155)

	bisagra = Node3D.new()
	bisagra.position = Vector3(0.25, 0.51, 0)
	add_child(bisagra)
	var tapa := pieza(bisagra, acceso, "Tapa del motor eléctrico", Vector3(0, -0.51, 0),
		Vector3(0.05, 1.02, 1.76), ACERO)
	rotulo(tapa, Vector3(0.027, 0.04, 0), "MOTOR ELÉCTRICO DE TRACCIÓN", 0.0024)
	caja(tapa, Vector3(0.034, -0.33, 0), Vector3(0.026, 0.033, 0.27), MARFIL)


func reflejar_estado(estado: Dictionary, falla: bool, inmediato := false) -> void:
	super.reflejar_estado(estado, falla, inmediato)
	var alerta: bool = estado.get("alerta_temperatura", false)
	aviso = estado.get("aviso", "") if alerta else ""
	lectura = "TEMPERATURA · ALERTA" if alerta else "TEMPERATURA · NORMAL"
	pantalla.text = lectura + "\n[MUESTRA]"
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
