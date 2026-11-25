extends RefCounted

# Efectos de sonido sintetizados en código: no hay archivos de audio ni licencias que atribuir.
# La tecla M silencia o activa el sonido en cualquier pantalla.

const TASA := 22050
const ARCHIVO := "user://sonido.cfg"

static var silenciado := false
static var volumen_db := -8.0
static var _cache := {}
static var _reproductor: AudioStreamPlayer
static var _clics_conectados := false


static func disponible() -> bool:
	return DisplayServer.get_name() != "headless"


static func cargar_preferencia() -> void:
	var config := ConfigFile.new()
	if config.load(ARCHIVO) == OK:
		silenciado = config.get_value("sonido", "silenciado", false) == true


static func alternar() -> bool:
	silenciado = not silenciado
	var config := ConfigFile.new()
	config.set_value("sonido", "silenciado", silenciado)
	config.save(ARCHIVO)
	if not silenciado:
		reproducir("clic")
	return silenciado


static func reproducir(nombre: String) -> void:
	if silenciado or not disponible() or not ESTILOS.has(nombre):
		return
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	if not is_instance_valid(_reproductor):
		_reproductor = AudioStreamPlayer.new()
		_reproductor.name = "Sonido"
		_reproductor.volume_db = volumen_db
		arbol.root.add_child(_reproductor)
	if not _cache.has(nombre):
		_cache[nombre] = crear(ESTILOS[nombre])
	# Cada efecto reemplaza al anterior para que no se amontonen.
	_reproductor.stream = _cache[nombre]
	_reproductor.play()


# Cada botón activo suena al pulsarlo, también los que se crean después.
static func clics_globales(arbol: SceneTree) -> void:
	if _clics_conectados:
		return
	_clics_conectados = true
	arbol.node_added.connect(func(nodo: Node):
		if nodo is BaseButton:
			nodo.pressed.connect(func(): reproducir("clic")))


# Notas: [frecuencia_inicial, frecuencia_final, duración, volumen, forma, inicio]
const ESTILOS := {
	"clic": [[1400.0, 900.0, 0.035, 0.5, "seno", 0.0]],
	"paso": [[660.0, 660.0, 0.08, 0.5, "seno", 0.0], [880.0, 880.0, 0.12, 0.5, "seno", 0.07]],
	"exito": [[523.0, 523.0, 0.1, 0.5, "seno", 0.0], [659.0, 659.0, 0.1, 0.5, "seno", 0.09],
		[784.0, 784.0, 0.22, 0.5, "seno", 0.18]],
	"victoria": [[523.0, 523.0, 0.12, 0.5, "seno", 0.0], [659.0, 659.0, 0.12, 0.5, "seno", 0.11],
		[784.0, 784.0, 0.12, 0.5, "seno", 0.22], [1047.0, 1047.0, 0.4, 0.5, "seno", 0.33]],
	"error": [[220.0, 160.0, 0.22, 0.55, "cuadrada", 0.0]],
	"aviso": [[520.0, 520.0, 0.09, 0.45, "seno", 0.0], [520.0, 520.0, 0.09, 0.45, "seno", 0.14]],
	"critico": [[180.0, 120.0, 0.25, 0.6, "cuadrada", 0.0], [180.0, 120.0, 0.25, 0.6, "cuadrada", 0.3],
		[140.0, 70.0, 0.4, 0.6, "cuadrada", 0.6]],
	"epp": [[0.0, 0.0, 0.14, 0.35, "ruido", 0.0], [300.0, 200.0, 0.05, 0.4, "seno", 0.12]],
	"epp_quitar": [[0.0, 0.0, 0.1, 0.3, "ruido", 0.0]],
	"elevador": [[70.0, 110.0, 0.95, 0.5, "diente", 0.0], [140.0, 220.0, 0.95, 0.2, "seno", 0.0]],
	"tomar": [[420.0, 520.0, 0.06, 0.45, "seno", 0.0]],
}


static func crear(notas: Array) -> AudioStreamWAV:
	var total := 0.0
	for nota in notas:
		total = maxf(total, nota[5] + nota[2])
	var muestras := PackedFloat32Array()
	muestras.resize(int(total * TASA) + 1)
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	for nota in notas:
		var inicio := int(nota[5] * TASA)
		var cantidad := int(nota[2] * TASA)
		var fase := 0.0
		for i in cantidad:
			var t := float(i) / maxf(1.0, cantidad - 1.0)
			var frecuencia: float = lerpf(nota[0], nota[1], t)
			fase += frecuencia / TASA
			var onda := 0.0
			match nota[4]:
				"seno": onda = sin(TAU * fase)
				"cuadrada": onda = 1.0 if fmod(fase, 1.0) < 0.5 else -1.0
				"diente": onda = 2.0 * fmod(fase, 1.0) - 1.0
				"ruido": onda = azar.randf_range(-1.0, 1.0)
			# Entrada y salida suaves para evitar chasquidos.
			var envolvente := minf(1.0, minf(t * 30.0, (1.0 - t) * 12.0))
			if nota[4] == "seno" or nota[4] == "ruido":
				envolvente *= 1.0 - 0.5 * t
			muestras[inicio + i] += onda * nota[3] * envolvente * 0.6
	var bytes := PackedByteArray()
	bytes.resize(muestras.size() * 2)
	for i in muestras.size():
		bytes.encode_s16(i * 2, int(clampf(muestras[i], -1.0, 1.0) * 32000.0))
	var onda_wav := AudioStreamWAV.new()
	onda_wav.format = AudioStreamWAV.FORMAT_16_BITS
	onda_wav.mix_rate = TASA
	onda_wav.data = bytes
	return onda_wav
