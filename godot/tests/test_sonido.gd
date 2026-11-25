extends RefCounted

const Sonido = preload("res://logica/sonido.gd")


static func ejecutar() -> bool:
	for nombre in Sonido.ESTILOS:
		var onda := Sonido.crear(Sonido.ESTILOS[nombre])
		var duracion := float(onda.data.size()) / 2.0 / Sonido.TASA
		if onda.data.size() < 200 or duracion > 1.5:
			printerr("Sonido fuera de rango: ", nombre)
			return false
		var pico := 0
		for i in range(0, onda.data.size(), 2):
			pico = maxi(pico, absi(onda.data.decode_s16(i)))
		if pico < 3000 or pico > 32000:
			printerr("Volumen incorrecto: ", nombre, " ", pico)
			return false
	# En las pruebas sin pantalla reproducir no debe fallar ni crear nodos.
	Sonido.reproducir("clic")
	return true
