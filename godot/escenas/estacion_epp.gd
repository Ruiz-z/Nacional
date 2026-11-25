extends "res://escenas/zona_base.gd"

const Epp = preload("res://logica/simulador/epp.gd")
const Modelo = preload("res://escenas/epp_3d.gd")
const ROTULO_EPP := "EPP"
const ENTRADA := Vector3(6.75, 0, 0.12)
const LISTO := "confirmar_epp"
const TEXTO_LISTO := "Listo, empezar a trabajar"
const TURQUESA := Color("#287f7d")

signal cambiado(id: String, puesto: bool)
signal confirmado(equipo: Array, fuente: String)

var ofrecidos: Array[String] = []
var modelos := {}
var huecos := {}
var puestos := {}
var disponible := true
var estructura_metalica: Node3D


func montar(datos: Dictionary) -> void:
	position = Vector3(6.75, 0, 2.75)
	rotation.y = PI
	ofrecidos = Epp.ofrecidos(datos)
	estructura_metalica = Node3D.new()
	estructura_metalica.name = "Forma"
	add_child(estructura_metalica)
	estructura(Vector3(0, 1.07, -0.24), Vector3(1.76, 2.14, 0.07), FONDO)
	for lado in [-1, 1]:
		estructura(Vector3(lado * 0.89, 1.07, 0), Vector3(0.067, 2.14, 0.56), ACERO)
	estructura(Vector3(0, 2.11, 0), Vector3(1.76, 0.08, 0.56), ACERO)
	estructura(Vector3(0, 1.95, 0.269), Vector3(1.76, 0.075, 0.018), TURQUESA)
	for fila in range(3):
		var altura := 1.56 - fila * 0.43
		estructura(Vector3(0, altura - 0.026, 0.0), Vector3(1.76, 0.05, 0.54), ACERO)
		for columna in range(3):
			var indice := fila * 3 + columna
			if indice < ofrecidos.size():
				crear_hueco(ofrecidos[indice], Vector3((columna - 1) * 0.56, altura + 0.137, 0.0))
	estructura(Vector3(0, 0.39, 0.22), Vector3(1.83, 0.09, 0.66), ACERO.lightened(0.18))
	for lado in [-1, 1]:
		estructura(Vector3(lado * 0.76, 0.18, 0.38), Vector3(0.10, 0.36, 0.26), ACERO)
	var panel := pieza(self, LISTO, TEXTO_LISTO, Vector3(0, 0.55, 0.47), Vector3(1.12, 0.15, 0.064), TURQUESA.darkened(0.45))
	texto_frontal(panel, Vector3(0, 0, 0.034), TEXTO_LISTO, 0.00135)


func crear_hueco(id: String, centro: Vector3) -> void:
	var cuerpo := pieza(self, id, Epp.nombre(id), centro, Vector3(0.44, 0.268, 0.34), TURQUESA)
	cuerpo.superficie.hide()
	caja(cuerpo, Vector3(0, -0.13, 0), Vector3(0.40, 0.012, 0.32), FONDO.lightened(0.10))
	var modelo := Node3D.new()
	modelo.position.y = -0.123
	cuerpo.add_child(modelo)
	Modelo.construir(self, modelo, id)
	modelos[id] = modelo
	var hueco := texto_frontal(cuerpo, Vector3(0, -0.045, -0.145), "DEVOLVER", 0.0012)
	hueco.hide()
	huecos[id] = hueco


func estructura(centro: Vector3, tam: Vector3, color: Color) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = centro
	estructura_metalica.add_child(cuerpo)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	caja(cuerpo, Vector3.ZERO, tam, color)


func texto_frontal(padre: Node3D, centro: Vector3, texto: String, escala: float) -> Label3D:
	var etiqueta := Label3D.new()
	etiqueta.position = centro
	etiqueta.text = texto
	etiqueta.font_size = 32
	etiqueta.pixel_size = escala
	etiqueta.modulate = Color("#d7f9ef")
	etiqueta.outline_size = 0
	padre.add_child(etiqueta)
	return etiqueta


func elegidos() -> Array[String]:
	return ofrecidos.filter(func(id: String) -> bool: return puestos.has(id))


func interactuar(id: String, fuente: String) -> void:
	if not disponible:
		return
	if id == LISTO:
		confirmado.emit(elegidos(), fuente)
		return
	if not modelos.has(id):
		return
	var puesto := not puestos.has(id)
	if puesto:
		puestos[id] = true
	else:
		puestos.erase(id)
	modelos[id].visible = not puesto
	huecos[id].visible = puesto
	piezas[id].nombre = ("Devolver %s" % Epp.nombre(id).to_lower()) if puesto else Epp.nombre(id)
	cambiado.emit(id, puesto)


func cerrar() -> void:
	disponible = false
	for pieza_epp: Interactuable in piezas.values():
		pieza_epp.collision_layer = 0
	for hueco: Label3D in huecos.values():
		hueco.hide()
	piezas[LISTO].hide()
