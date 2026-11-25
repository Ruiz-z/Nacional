extends RefCounted

const Datos = preload("res://logica/tablero/datos_graficas.gd")
const Banco = preload("res://logica/competencias/banco.gd")


static func ejecutar() -> bool:
	var vacio := Datos.tecnico({})
	if vacio.fichas.size() != 4 or vacio.fichas[0][1] != "Pendiente" \
			or not vacio.graficas.all(func(grafica: Dictionary) -> bool: return grafica.filas.is_empty()):
		return false

	var ids: Array = Banco.COMPETENCIAS.keys()
	var perfil := {
		"alias": "Taller-03", "estado": "con_sesiones",
		"competencias": {
			ids[0]: {"dominio": 69, "nivel": "Básico", "ganancia": -10, "retencion": "pendiente",
				"dominios_evaluaciones": {"pre": 79, "post": 69}},
			ids[1]: {"dominio": 70, "nivel": "Competente", "ganancia": 20, "retencion": 100},
			ids[2]: {"dominio": 0, "nivel": "Novato"},
			ids[3]: {"dominio": 100, "nivel": "Experto"}},
		"faltas_criticas": {"conteo": 0},
		"recomendacion": {"estado": "Con alertas", "prioridad": 1},
		"intentos": [intento(ids[0], 69, "2026-01-02", "sesion-2", "paso-omitido"),
			intento(ids[0], 100, "2026-01-01", "sesion-1", "lectura-equivocada"),
			intento(ids[3], 0, "2026-01-02", "sesion-2", "paso-omitido"),
			intento("tema-desconocido", 100, "2026-01-02", "sesion-2", "")]}
	var personal := Datos.tecnico(perfil)
	var dominio: Dictionary = personal.graficas[0]
	var linea: Dictionary = personal.graficas[2]
	if personal.fichas != [["Dominio global", "59.8 %"], ["Ganancia indicativa", "5.0 pts"],
		["Retención simulada", "100.0 %"], ["Faltas críticas", "0"]]:
		return false
	if dominio.minimo != 70 or dominio.filas[2].valores != [0.0] or dominio.filas[3].valores != [100.0] \
			or not dominio.lectura.begins_with("Diagnóstico está por debajo") \
			or personal.graficas[1].filas[0].valores != [79.0, 69.0, null]:
		return false
	if linea.columnas.size() != 4 or linea.filas.size() != 2 or linea.filas[0].valores != [100.0, null, null, null] \
			or linea.filas[1].valores != [69.0, null, null, 0.0] or personal.graficas[3].filas[0].valores != [2]:
		return false

	var sin_base := Datos.tecnico({"competencias": {ids[0]: {"retencion": "no calculable"}}})
	if sin_base.fichas[2][1] != "No calculable":
		return false

	var alta := {"alias": "Taller-10", "recomendacion": {"estado": "Con falta crítica", "prioridad": 0}}
	var antes := {"alias": "Taller-02", "recomendacion": {"estado": "Con alertas", "prioridad": 1}}
	var incompleto := {"alias": "Taller-01", "recomendacion": {"estado": "Sin completar", "prioridad": 2}}
	var listo := {"alias": "Taller-04", "recomendacion": {"estado": "Sin alertas", "prioridad": 3}}
	var equipo := Datos.equipo([perfil, listo, incompleto, alta, antes])
	var mapa: Array = equipo.graficas[0].filas
	if not Datos.equipo([]).graficas[1].filas.is_empty() or Datos.equipo([perfil]).graficas[0].filas.size() != 1:
		return false
	if mapa.map(func(fila: Dictionary) -> String: return fila.nombre) \
			!= ["Taller-10", "Taller-02", "Taller-03", "Taller-01", "Taller-04"] \
			or mapa[0].valores != [null, null, null, null] or equipo.graficas[1].filas[0].valores != [1, 2, 1, 1]:
		return false

	var resumen := {"tecnicos": [{"alias": "Primero", "intentos": 0, "ultima": ""},
		{"alias": "Segundo", "intentos": 2, "ultima": "2026-01-01T10:00:00Z"}],
		"cuentas": {"tecnico": 2, "jefe": 0, "admin": 1}, "preguntas": 3, "pendientes_revision": 3,
		"foundry": false, "respaldo": {"existe": false}}
	var admin := Datos.admin(resumen)
	if admin.graficas[0].filas[0].nombre != "Segundo" or admin.graficas[0].filas[1].detalle != "Sin actividad" \
			or admin.graficas[2].filas[0].valores != [0, 3]:
		return false
	resumen.pendientes_revision = 0
	return Datos.admin(resumen).graficas[2].filas[0].valores == [3, 0]


static func intento(competencia: String, valor: int, fecha: String, sesion: String, error: String) -> Dictionary:
	return {"competencia": competencia, "valor": valor, "peso": 1, "formato": "opcion-multiple",
		"tipo_error": error, "reloj_sim": fecha, "momento": "post", "sesion_id": sesion}
