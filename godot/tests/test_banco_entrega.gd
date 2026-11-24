extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Practica = preload("res://logica/simulador/practica.gd")
const Consultas = preload("res://logica/tablero/consultas.gd")
const Dominio = preload("res://logica/aprendizaje/dominio.gd")


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if Base.consultar(base, "INSERT INTO tecnico (id, alias) VALUES (1, 'T-Arnés');") == null:
		return false
	var escenario: Dictionary = Escenario.cargar("escenarios/modulo_auxiliar.json").escenario
	var motor := Motor.new(escenario)
	for id in ["medir_tp2", "diagnosticar_senal", "medir_tp1", "reportar_tp1_0",
			"reportar_tp2_5", "diagnosticar_modulo"]:
		motor.ejecutar(id, "teclado", 10)
	motor.ejecutar("reconectar", "virtual", 10)
	var conteo := {"medicion": 1, "interpretacion": 1}
	if motor.resumen().errores_arnes != conteo or not Practica.guardar(base, 1, "T-Arnés", motor, 0):
		return false
	var perfil := Consultas.tecnico(base, "T-Arnés", Base.consultar)
	var errores := []
	for intento in perfil.intentos:
		if intento.tipo_error != null:
			errores.append(intento.tipo_error)
	return perfil.errores_arnes == conteo \
		and errores == ["punto-de-medicion-incorrecto", "lectura-mal-interpretada"] \
		and Dominio.calcular(perfil.intentos) == motor.puntaje() \
		and perfil.eventos[0].punto_medido == "tp2" and perfil.eventos[0].lectura_mostrada == 5.0 \
		and perfil.eventos[3]["lectura-reportada"] == "≈0 V" and perfil.eventos[3].fuente_falla == "virtual"
