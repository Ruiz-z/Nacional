extends "res://escenas/zona_base.gd"

const EJES := {"delantero": 3.008, "trasero": -2.713}
const LADOS := {"derecho": 1.0, "izquierdo": -1.0}
const CAUCHO := Color("#24282a")
const PLATA := Color("#a5afb2")

var estado_orden := {}


static func componente_valido(id: Variant) -> bool:
	if id == "consola_elevador":
		return true
	for eje in EJES:
		for lado in LADOS:
			var rueda := "%s_%s" % [eje, lado]
			if id in ["neumatico_" + rueda, "disco_" + rueda, "pastillas_" + rueda]:
				return true
			if eje == "trasero" and id in ["bolsa_" + rueda, "amortiguador_" + rueda]:
				return true
			for numero in range(1, 6):
				if id == "tuerca_%s_%d" % [rueda, numero]:
					return true
	return false


func _ready() -> void:
	for eje in EJES:
		var z: float = EJES[eje]
		cilindro(self, Vector3(0, 0.42, z), 0.09, 1.78, ACERO).rotation_degrees.z = 90
		for lado in LADOS:
			crear_rueda(eje, lado, z, LADOS[lado])
	luz_servicio = OmniLight3D.new()
	luz_servicio.position = Vector3(0, 0.27, -0.5)
	luz_servicio.light_color = Color("#fff1d9")
	luz_servicio.light_energy = 0.75
	luz_servicio.omni_range = 6.0
	add_child(luz_servicio)
	habilitar(false)


func crear_rueda(eje: String, lado: String, z: float, signo: float) -> void:
	var id := "%s_%s" % [eje, lado]
	var nombre := " · rueda %s %s" % ["delantera" if eje == "delantero" else "trasera",
		"derecha" if lado == "derecho" else "izquierda"]
	var rueda := pieza(self, "neumatico_" + id, "Neumático" + nombre,
		Vector3(signo * 1.03, 0.42, z), Vector3(0.30, 0.82, 0.82), CAUCHO)
	rueda.superficie.hide()
	cilindro(rueda, Vector3.ZERO, 0.42, 0.316, CAUCHO, 24).rotation_degrees.z = 90
	metal(cilindro(rueda, Vector3(-signo * 0.15, 0, 0), 0.26, 0.035, PLATA, 20)).rotation_degrees.z = 90
	var disco := pieza(self, "disco_" + id, "Disco de freno" + nombre,
		Vector3(signo * 0.78, 0.42, z), Vector3(0.035, 0.42, 0.42), PLATA)
	disco.superficie.hide()
	metal(cilindro(disco, Vector3.ZERO, 0.25, 0.045, PLATA, 20)).rotation_degrees.z = 90
	for i in range(5):
		var angulo := TAU * i / 5.0
		var numero := i + 1
		var tuerca := pieza(self, "tuerca_%s_%d" % [id, numero], "Tuerca %d%s" % [numero, nombre],
			Vector3(signo * 0.728, 0.42 + cos(angulo) * 0.157, z - signo * sin(angulo) * 0.157),
			Vector3(0.058, 0.077, 0.077), PLATA)
		tuerca.superficie.hide()
		cilindro(tuerca, Vector3.ZERO, 0.039, 0.058, PLATA, 6).rotation_degrees.z = 90
		var etiqueta := rotulo(tuerca, Vector3(-signo * 0.036, 0, 0), str(numero), 0.00125)
		etiqueta.rotation_degrees.y = -signo * 90
		etiqueta.modulate = Color("#162027")
		etiqueta.outline_size = 0
	pieza(self, "pastillas_" + id, "Pastillas de freno" + nombre,
		Vector3(signo * 0.73, 0.48, z + 0.28), Vector3(0.16, 0.15, 0.13), Color("#a55c36"))
	if eje == "trasero":
		var bolsa := pieza(self, "bolsa_" + id, "Bolsa de aire" + nombre,
			Vector3(signo * 0.61, 0.51, z + 0.56), Vector3(0.32, 0.33, 0.32), CAUCHO)
		bolsa.superficie.hide()
		cilindro(bolsa, Vector3.ZERO, 0.128, 0.33, CAUCHO)
		for altura in [-0.11, 0.0, 0.11]:
			cilindro(bolsa, Vector3(0, altura, 0), 0.16, 0.083, FONDO)
		var amortiguador := pieza(self, "amortiguador_" + id, "Amortiguador" + nombre,
			Vector3(signo * 0.58, 0.57, z - 0.54), Vector3(0.17, 0.48, 0.17), NARANJA)
		amortiguador.superficie.hide()
		cilindro(amortiguador, Vector3.UP * 0.12, 0.048, 0.25, PLATA)
		cilindro(amortiguador, Vector3.DOWN * 0.09, 0.081, 0.29, NARANJA)
		amortiguador.rotation_degrees.x = -17


func habilitar(valor: bool) -> void:
	visible = valor
	for objetivo in piezas.values():
		objetivo.collision_layer = 2 if valor else 0


func reflejar_estado(estado: Dictionary, _falla: bool, _inmediato := false) -> void:
	estado_orden = estado


func lectura_pieza(_componente: String) -> String:
	return "[MUESTRA] " + estado_orden.get("aviso", "")
