extends "res://escenas/zona_base.gd"

const ALTURA := 1.5
const CONSOLA := "consola_elevador"
const CALZAS := "posicion_calzas"

var carga: Array[Node3D]
var bases: Array[Vector3]
var ruedas_modelo: Array[Node]
var casco: CollisionShape3D
var forma_casco: BoxShape3D
var base_casco: Vector3
var tam_casco: Vector3
var bajos: Node3D
var recorrido: Tween
var arriba := false
var calzas_colocadas := false
var trabas := {}
var mordazas := {}
var indicadores_calzas: Node3D


func _ready() -> void:
	var consola := pieza(self, CONSOLA, "Consola del elevador",
		Vector3(-2.75, 1.15, 0.1), Vector3(0.34, 0.39, 0.56), FONDO)
	caja(consola, Vector3(0, -0.69, 0), Vector3(0.15, 1.0, 0.17), ACERO)
	caja(consola, Vector3(0, -1.10, 0), Vector3(0.56, 0.09, 0.64), ACERO)
	rotulo(consola, Vector3(0.176, 0.097, 0), "ELEVADOR", 0.0032)
	for indice in range(2):
		var boton := cilindro(consola, Vector3(0.177, -0.058, 0.13 - indice * 0.26),
			0.045, 0.025, Color("#55a77a") if indice == 0 else Color("#c65c43"))
		boton.rotation_degrees.z = 90
		var signo := -1.0 if indice == 0 else 1.0
		var id := "soporte_izquierdo" if indice == 0 else "soporte_derecho"
		var columna := pieza(self, id, "Soporte izquierdo" if indice == 0 else "Soporte derecho",
			Vector3(signo * 1.76, 1.16, -1.28), Vector3(0.28, 2.32, 0.34), ACERO)
		caja(columna, Vector3(0, -1.12, 0), Vector3(0.55, 0.08, 0.68), FONDO)
		var letrero := rotulo(columna, Vector3(-signo * 0.148, 0.87, 0),
			"TRABA", 0.0022)
		letrero.rotation_degrees.y = -signo * 90
		mordazas[id] = caja(columna, Vector3(-signo * 0.36, -0.85, 0), Vector3(0.6, 0.18, 0.22), NARANJA)
		trabas[id] = false
	var marca := pieza(self, CALZAS, "Punto de colocación de calzas",
		Vector3(-1.08, 0.09, 3.60), Vector3(0.61, 0.16, 0.42), Color("#b79753"))
	for lado in [-1, 1]:
		caja(marca, Vector3(lado * 0.15, 0.082, 0),
			Vector3(0.11, 0.008, 0.30), Color("#e5b641"))
	indicadores_calzas = Node3D.new()
	marca.add_child(indicadores_calzas)
	for lado in [-1, 1]:
		caja(indicadores_calzas, Vector3(lado * 0.15, 0.08, 0),
			Vector3(0.19, 0.13, 0.31), Color("#e5b641")).rotation_degrees.x = 18
	indicadores_calzas.hide()


func configurar(nodos: Array[Node3D], colision: CollisionShape3D, zona: Node3D) -> void:
	carga = nodos
	for nodo in carga:
		bases.append(nodo.position)
	ruedas_modelo = carga[0].find_children("wheel*", "MeshInstance3D", true, false)
	casco = colision
	forma_casco = casco.shape.duplicate() as BoxShape3D
	casco.shape = forma_casco
	base_casco = casco.position
	tam_casco = forma_casco.size
	bajos = zona


func ocupado(posicion: Vector3) -> bool:
	if posicion.x > 50.0:
		return true # El interior jugable está en una coordenada separada.
	var margen := 0.3
	return absf(posicion.x) < tam_casco.x * 0.5 + margen \
		and absf(posicion.z) < tam_casco.z * 0.5 + margen


func en_movimiento() -> bool:
	return recorrido != null and recorrido.is_running()


func seguro() -> bool:
	return arriba and not en_movimiento() and not false in trabas.values()


func colocar_calzas() -> void:
	calzas_colocadas = true
	indicadores_calzas.show()


func cambiar_traba(id: String, trabar: bool) -> void:
	trabas[id] = trabar
	var brazo: MeshInstance3D = mordazas[id]
	(brazo.material_override as StandardMaterial3D).albedo_color = Color("#53a778") if trabar else NARANJA


func mover(subir: bool, inmediato := false) -> void:
	if recorrido != null:
		recorrido.kill()
	arriba = false
	bajos.habilitar(false)
	for rueda in ruedas_modelo:
		rueda.show()
	if inmediato:
		aplicar_altura(ALTURA if subir else 0.0)
		terminar_movimiento(subir)
		return
	recorrido = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	recorrido.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var altura := carga[0].position.y - bases[0].y
	recorrido.tween_method(aplicar_altura, altura, ALTURA if subir else 0.0, 0.95)
	recorrido.tween_callback(terminar_movimiento.bind(subir))


func aplicar_altura(altura: float) -> void:
	for i in range(carga.size()):
		carga[i].position = bases[i] + Vector3.UP * altura
	# Al subir, se libera el volumen que ocupaban las ruedas en la caja del casco.
	var recorte := 0.43 * altura / ALTURA
	casco.position = base_casco + Vector3.UP * (altura + recorte / 2.0)
	forma_casco.size = tam_casco - Vector3.UP * recorte
	for brazo in mordazas.values():
		brazo.position.y = -0.85 + altura


func terminar_movimiento(subir: bool) -> void:
	arriba = subir
	bajos.habilitar(subir)
	for rueda in ruedas_modelo:
		rueda.visible = not subir


func reiniciar() -> void:
	for id in trabas:
		cambiar_traba(id, false)
	calzas_colocadas = false
	indicadores_calzas.hide()
	mover(false, true)
