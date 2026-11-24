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
	for id in escenario.ruta_ideal:
		motor.ejecutar(id, "virtual" if id == "reconectar" else "teclado", 10)
	motor.registrar_diagnostico("modulo", "teclado", 10)
	var conteo := {"medicion": 0, "interpretacion": 1}
	if motor.resumen().errores_arnes != conteo or not Practica.guardar(base, 1, "T-Arnés", motor, 0):
		return false
	var perfil := Consultas.tecnico(base, "T-Arnés", Base.consultar)
	var errores := []
	for intento in perfil.intentos:
		if intento.tipo_error != null:
			errores.append(intento.tipo_error)
	var cierres: Array = perfil.eventos.filter(func(evento: Dictionary) -> bool:
		return evento.accion == "diagnostico_final")
	return cierres.size() == 1 and cierres[0].tipo_error == "lectura-mal-interpretada" \
		and cierres[0].causa_elegida == "modulo" and perfil.errores_arnes == conteo \
		and errores == ["lectura-mal-interpretada", "causa-equivocada"] \
		and Dominio.calcular(perfil.intentos) == motor.puntaje() \
		and perfil.eventos[0].punto_medido == "tp1" and perfil.eventos[0].lectura_mostrada == 0.0 \
		and perfil.eventos[2]["lectura-reportada"] == "≈0 V" and perfil.eventos[2].fuente_falla == "virtual"
