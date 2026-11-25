extends RefCounted

# Datos de la vista operativa del admin: salud de las cuentas, del contenido y de los respaldos.
# No calcula dominio ni ruta; solo cuenta lo que ya está guardado.
const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const Cuentas = preload("res://logica/flujo/cuentas.gd")


# `items`: preguntas del banco; `foundry`: si hay servicio configurado; `respaldo`: ruta del archivo de respaldo.
static func resumen(base: String, items: Array, foundry: bool, respaldo: String,
		consultar: Callable = Acceso.consultar) -> Dictionary:
	var cuentas := {"tecnico": 0, "jefe": 0, "admin": 0}
	var heredadas := 0
	for cuenta in Cuentas.listar(base, consultar):
		cuentas[cuenta.rol] += 1
		if cuenta.heredada:
			heredadas += 1
	var actividad: Variant = consultar.call(base, """
		SELECT tecnico.alias, max(intento.reloj_sim) AS ultima, count(intento.id) AS intentos
		FROM tecnico LEFT JOIN intento ON intento.tecnico = tecnico.id
		WHERE tecnico.demo = 0 AND tecnico.rol = 'tecnico' AND tecnico.clave_hash <> ''
		GROUP BY tecnico.id ORDER BY tecnico.alias;
	""")
	var tecnicos := []
	var con_actividad := 0
	for fila in ([] if actividad == null else actividad):
		var activo: bool = int(fila.intentos) > 0
		con_actividad += 1 if activo else 0
		tecnicos.append({"alias": fila.alias, "intentos": int(fila.intentos),
			"ultima": fila.ultima if activo else ""})
	var pendientes := items.filter(func(item: Dictionary) -> bool: return item.get("revisado", false) != true)
	var existe := FileAccess.file_exists(respaldo)
	return {"cuentas": cuentas, "heredadas": heredadas, "tecnicos": tecnicos,
		"con_actividad": con_actividad, "sin_actividad": tecnicos.size() - con_actividad,
		"preguntas": items.size(), "pendientes_revision": pendientes.size(),
		"foundry": foundry,
		"respaldo": {"existe": existe, "fecha": fecha_de(respaldo) if existe else ""}}


static func fecha_de(ruta: String) -> String:
	var tiempo := Time.get_datetime_dict_from_unix_time(FileAccess.get_modified_time(ruta))
	return "%04d-%02d-%02d %02d:%02d" % [tiempo.year, tiempo.month, tiempo.day, tiempo.hour, tiempo.minute]
