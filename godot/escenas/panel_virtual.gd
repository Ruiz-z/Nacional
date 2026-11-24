extends VBoxContainer

signal accion_recibida(accion: Dictionary)

const FondoTarjeta = preload("res://escenas/fondo_tarjeta.gd")
const LEDS := {
	"Energizado": Color("#f2b705"),
	"Bloqueado": Color("#3fae6a"),
	"Falla": Color("#d64545"),
}
const ZONA_MINIMA := 40
const ZONA_MAXIMA := 60
const Conexion = preload("res://logica/entrada/conexion_panel.gd")
const Entrada = preload("res://logica/entrada/entrada.gd")

var conexion := Conexion.new()
var entrada := Entrada.new()
var secuencia := 0


func _ready() -> void:
	if get_parent() == get_tree().root:
		FondoTarjeta.aplicar(self, 16)
	$Torque.draw.connect(dibujar_zona)
	$Lectura.draw.connect(dibujar_perilla)
	$Zona.text = "Zona segura simulada · %d–%d" % [ZONA_MINIMA, ZONA_MAXIMA]
	for led in [$Energizado, $Bloqueado, $Falla]:
		led.draw.connect(dibujar_led.bind(led))
	$Bloqueo.toggled.connect(func(activo: bool): emitir("bloqueo", int(activo)))
	$Etiquetado.toggled.connect(func(activo: bool): emitir("etiquetado", int(activo)))
	$Torque.value_changed.connect(func(valor: float):
		$Lectura.text = "%d / 100" % valor
		$Lectura.queue_redraw())
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
		var texto := "sin datos" if estado == null else ("encendido" if estado else "apagado")
		led.text = "     %s · %s" % [led.name, texto]
		led.set_meta("activo", estado == true)
		led.queue_redraw()


func dibujar_zona() -> void:
	# El intervalo 40–60 proviene del caso de prueba de torque simulado (RF-49).
	var barra: HSlider = $Torque
	var ancho := barra.size.x - 16.0
	barra.draw_rect(Rect2(8.0 + ancho * ZONA_MINIMA / barra.max_value, barra.size.y - 4.0,
		ancho * (ZONA_MAXIMA - ZONA_MINIMA) / barra.max_value, 4.0),
		Color("#3fae6a"))


func dibujar_led(led: Label) -> void:
	var centro := Vector2(7, led.size.y * 0.5)
	var color: Color = LEDS[led.name]
	led.draw_circle(centro, 5.0, color, led.get_meta("activo", false), 1.5, true)


func dibujar_perilla() -> void:
	var lectura: Label = $Lectura
	var centro := Vector2(lectura.size.x - 20.0, lectura.size.y * 0.5)
	var angulo := lerpf(-2.35, 2.35, $Torque.ratio) - PI / 2.0
	lectura.draw_circle(centro, 17.0, Color("#12161b"), true, -1.0, true)
	lectura.draw_circle(centro, 17.0, Color("#647f98"), false, 2.0, true)
	lectura.draw_line(centro, centro + Vector2.from_angle(angulo) * 12.0, Color("#e8edf2"), 2.0, true)
