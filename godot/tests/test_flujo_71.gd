extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Alias = preload("res://logica/flujo/alias.gd")

static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var flujo = load("res://logica/flujo/recorrido.gd")
	if flujo == null:
		return false
	if flujo.estado(base, 0, 0, Base.consultar).habilitados != ["alias", "modo_demo"]:
		return false
	var alta := Alias.alta(base, "T-71", Base.consultar)
	if not alta.ok:
		return false
	var id: int = alta.id
	var inicial: Dictionary = flujo.estado(base, id, 0, Base.consultar)
	if inicial.siguiente != "diagnostico" or "ruta" in inicial.habilitados:
		return false
	for paso in ["ruta", "escenario", "post", "retest", "tablero"]:
		if Base.consultar(base, """
			INSERT INTO progreso (tecnico, paso_actual) VALUES (?, ?)
			ON CONFLICT(tecnico) DO UPDATE SET paso_actual = excluded.paso_actual;
		""", [id, paso]) == null:
			return false
		if flujo.estado(base, id, 0, Base.consultar).siguiente != paso:
			return false
	if Base.consultar(base, """
		UPDATE progreso SET paso_actual = 'retest';
		INSERT INTO intento (id, tecnico, competencia, item, formato, dificultad, respuesta, valor, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento, reloj_sim, version_contenido) VALUES
			(1,1,'diagnostico-fallas','a','opcion-multiple','facil','x',50,1,'incorrecto',NULL,20,'teclado','post','1970-01-02T00:00:00Z','1');
	""") == null:
		return false
	var espera: Dictionary = flujo.estado(base, id, 86400, Base.consultar)
	return espera.dias_para_retest == 7 and "retest" not in espera.habilitados \
		and "retest" in flujo.estado(base, id, 8 * 86400, Base.consultar).habilitados
