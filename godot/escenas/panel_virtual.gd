extends VBoxContainer

signal accion_recibida(accion: Dictionary)

const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const Entrada = preload("res://logica/entrada/entrada.gd")

var conexion := Conexion.new()
var entrada := Entrada.new()
var secuencia := 0


func _ready() -> void:
	$Bloqueo.toggled.connect(func(activo: bool): emitir("bloqueo", int(activo)))
	$Etiquetado.toggled.connect(func(activo: bool): emitir("etiquetado", int(activo)))
	$Torque.value_changed.connect(func(valor: float): $Lectura.text = "Torque: %d / 100" % valor)
	$AplicarTorque.pressed.connect(func(): emitir("torque", $Torque.value))
	$Confirmar.pressed.connect(func(): emitir("confirmar", 1))
	$Cancelar.pressed.connect(func(): emitir("cancelar", 1))
	mostrar_leds({})


func emitir(control: String, valor: float) -> void:
	secuencia += 1
	var tiempo := Time.get_ticks_msec()
	var linea := JSON.stringify({"v": conexion.protocolo.VERSION, "ctrl": control,
		"valor": valor, "n": secuencia, "t": tiempo})
	recibir(linea, "virtual", tiempo)


func recibir(linea: String, fuente: String, tiempo: int) -> void:
	var evento := conexion.recibir(linea, fuente, tiempo)
	if evento.is_empty():
		return
	for accion in entrada.procesar_lote([evento]):
		accion_recibida.emit(accion)


func mostrar_leds(estados: Dictionary) -> void:
	for led in [$Energizado, $Bloqueado, $Falla]:
		var estado: Variant = estados.get(String(led.name).to_lower())
		led.text = "%s: %s" % [led.name, "sin datos" if estado == null else (
			"● encendido" if estado else "○ apagado")]
