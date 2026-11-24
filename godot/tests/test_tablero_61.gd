extends RefCounted

const Base = preload("res://tests/base_tablero.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	if Base.consultar(base, """
		INSERT INTO tecnico (id, alias, demo) VALUES (1, '[DEMO]', 1);
		INSERT INTO progreso VALUES (1, 'ruta', json_array('a','b'), 1);
		INSERT INTO intento (id, tecnico, competencia, item, formato, dificultad, respuesta, valor, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento, reloj_sim, version_contenido) VALUES
			(1,1,'diagnostico-fallas','a','opcion-multiple','facil','x',50,1,'incorrecto','causa','20','teclado','pre','2026-01-01','1'),
			(2,1,'diagnostico-fallas','b','caso-diagnostico','facil','x',80,1,'incorrecto','causa','30','teclado','post','2026-01-02','1'),
			(3,1,'diagnostico-fallas','b','caso-diagnostico','facil','x',40,1,'incorrecto','causa','40','teclado','retest','2026-01-08','1');
	""") == null:
		return false
	var registro = load("res://logica/tablero/registro_simulador.gd")
	if registro == null:
		return false
	var evento := {"escenario": "caso", "accion": "b", "estado_antes": {"activo": true},
		"estado_despues": {"activo": false}, "tiempo_ms": 10, "criticidad": "critica",
		"fuente_entrada": "teclado", "reloj_sim": "2026-01-02"}
	var brecha := {"competencia": "diagnostico-fallas", "caso": "caso", "causa_marcada": "a",
		"accion_ejecutada": "b", "reloj_sim": "2026-01-02"}
	if not registro.guardar(base, 1, {"eventos": [evento,
		evento.merged({"tiempo_ms": 30, "criticidad": "normal", "reloj_sim": "2026-01-03"}, true)],
		"brechas": [brecha]}, Base.consultar):
		return false
	var consultas = load("res://logica/tablero/consultas.gd")
	if consultas == null:
		return false
	var datos: Dictionary = consultas.tecnico(base, "[DEMO]", Base.consultar)
	var falla: Dictionary = datos.competencias["diagnostico-fallas"]
	return is_equal_approx(falla.dominio, 170.0 / 3) and falla.nivel == "Básico" \
		and falla.confianza == "alta" and falla.ganancia == 30 and falla.retencion == 50 \
		and falla.errores_recurrentes == {"causa": 3} and falla.brechas == 1 \
		and falla.brechas_por_momento.post == 1 and datos.faltas_criticas == {"conteo": 1, "ultima": "2026-01-02"} \
		and JSON.parse_string(datos.eventos[0].estado_despues) == {"activo": false} \
		and datos.tiempos_por_escenario == {"caso": {"b": 20.0}} \
		and datos.avance_ruta == {"completadas": 1, "pendientes": 2} and datos.retencion_simulada
