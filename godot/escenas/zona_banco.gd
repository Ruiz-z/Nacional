extends "res://escenas/zona_base.gd"

var pantalla: Label3D
var estado_banco: Label3D


func _ready() -> void:
	acceso = "multimetro"
	var madera := Color("#9d7652")
	caja(self, Vector3(0, 0.88, 0), Vector3(0.85, 0.08, 1.85), madera)
	var mesa := StaticBody3D.new()
	mesa.collision_layer = 1
	add_child(mesa)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.83, 0.91, 1.83)
	colision.shape = forma
	colision.position.y = 0.455
	mesa.add_child(colision)
	for fondo in [-0.34, 0.34]:
		for lado in [-0.82, 0.82]:
			caja(self, Vector3(fondo, 0.42, lado), Vector3(0.065, 0.84, 0.065), ACERO)
	caja(self, Vector3(-0.3, 1.17, 0), Vector3(0.12, 0.48, 1.68), FONDO)
	rotulo(self, Vector3(-0.233, 1.37, 0), "BANCO DE ARNÉS · MAQUETA DIDÁCTICA", 0.00115)
	estado_banco = rotulo(self, Vector3(-0.232, 1.31, 0), "", 0.00095)
	estado_banco.modulate = Color("#edc88a")

	var colores := [Color("#303438"), Color("#ca5043"), Color("#438fa9")]
	for extremo in [-0.64, 0.64]:
		caja(self, Vector3(-0.17, 1.19, extremo), Vector3(0.16, 0.15, 0.14), ACERO)
		rotulo(self, Vector3(-0.086, 1.196, extremo), "J1" if extremo < 0 else "J2", 0.0014)
	for indice in range(3):
		var altura := 1.145 + 0.035 * indice
		var cable := cilindro(self, Vector3(-0.214, altura, 0), 0.01, 1.17, colores[indice])
		cable.rotation_degrees.x = 90.0
		var nombre := "TP%d" % indice
		var borne := pieza(self, nombre.to_lower(), nombre,
			Vector3(0.12, 1.07, 0.31 + 0.21 * indice), Vector3(0.1, 0.12, 0.13), colores[indice])
		cilindro(borne, Vector3(0, 0.055, 0), 0.027, 0.042, Color("#c0a97a"))
		rotulo(borne, Vector3(0.052, -0.006, 0), nombre, 0.0013)
	caja(self, Vector3(0.095, 0.96, 0.52), Vector3(0.28, 0.08, 0.62), ACERO)

	var medidor := pieza(self, acceso, "Multímetro · Registro y diagnóstico",
		Vector3(0.115, 1.075, -0.3), Vector3(0.16, 0.28, 0.34), Color("#edbb31"))
	caja(medidor, Vector3(0.083, 0.049, 0), Vector3(0.013, 0.109, 0.277), Color("#263d34"))
	pantalla = rotulo(medidor, Vector3(0.091, 0.049, 0), "—", 0.0023)
	pantalla.modulate = Color("#aff2b8")
	var perilla := cilindro(medidor, Vector3(0.086, -0.052, 0), 0.033, 0.022, FONDO)
	perilla.rotation_degrees.z = 90
	for lado in [-1, 1]:
		var color: Color = colores[0] if lado == -1 else colores[1]
		cilindro(medidor, Vector3(0.094, -0.12, lado * 0.074), 0.011, 0.036,
			color).rotation_degrees.z = 90
	var luz := OmniLight3D.new()
	luz.position = Vector3(0.5, 1.85, 0)
	luz.light_energy = 0.95
	luz.omni_range = 3.0
	add_child(luz)


func reflejar_estado(_estado: Dictionary, _falla: bool, _inmediato := false) -> void:
	pass


func mostrar_multimetro(lectura: String, aviso: String, fuente: String) -> void:
	pantalla.text = lectura
	estado_banco.text = "%s · Fuente: %s" % [aviso, etiqueta_fuente(fuente)]


func etiqueta_fuente(fuente: String) -> String:
	return "banco físico" if fuente == "banco" else fuente


func lectura_pieza(_componente: String) -> String:
	return "Coloca la punta negra en TP0 y la roja en TP1 o TP2."
