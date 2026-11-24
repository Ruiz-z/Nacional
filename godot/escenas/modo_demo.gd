extends VBoxContainer

signal tablero_solicitado(perfil: Dictionary)
signal escenario_solicitado(perfil: Dictionary)

const Demo = preload("res://logica/flujo/modo_demo.gd")
const Reloj = preload("res://logica/aprendizaje/reloj.gd")

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")

var base_real := "user://nacional.sqlite"
var perfil := {}


func _ready() -> void:
	FondoTarjeta.aplicar(self, 16)
	$Adelantar.pressed.connect(func(): actualizar(Demo.adelantar(base_real, 7)))
	$Restablecer.pressed.connect(func(): actualizar(Demo.restablecer(base_real)))
	$Tablero.pressed.connect(func(): tablero_solicitado.emit(perfil))
	$Escenario.pressed.connect(func(): escenario_solicitado.emit(perfil))
	actualizar(true)
	if not perfil.is_empty():
		$Adelantar.grab_focus()


func actualizar(correcto: bool) -> void:
	perfil = Demo.abrir(base_real)
	var reloj := {} if perfil.is_empty() else Reloj.estado(perfil.base, perfil.id, int(Time.get_unix_time_from_system()))
	$Estado.text = "No se pudo abrir la demo." if reloj.is_empty() else "%s · Reloj simulado: +%d días" % [
		perfil.alias, reloj.desplazamiento_dias]
	$Aviso.text = "" if correcto else "No se pudo actualizar la demo."
	for boton in [$Adelantar, $Restablecer, $Tablero, $Escenario]:
		boton.disabled = reloj.is_empty()
