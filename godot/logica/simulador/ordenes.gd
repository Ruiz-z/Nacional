extends RefCounted

const Acceso = preload("res://logica/datos/acceso_sqlite.gd")
const TextoLimpio = preload("res://logica/texto_limpio.gd")

const Escenario = preload("res://logica/simulador/escenario.gd")
const RutasContenido = preload("res://logica/rutas_contenido.gd")
const Banco = preload("res://logica/competencias/banco.gd")


static func listar(ruta := "escenarios") -> Dictionary:
	var carpeta := RutasContenido.resolver(ruta, true)
	var directorio := DirAccess.open(carpeta)
	var resultado := {"ordenes": [], "errores": []}
	if directorio == null:
		resultado.errores.append("No se pudo abrir %s." % carpeta)
		return resultado
	for nombre in directorio.get_files():
		if nombre.get_extension().to_lower() != "json":
			continue
		var archivo := carpeta.path_join(nombre)
		var carga := Escenario.cargar(archivo)
		if not carga.errores.is_empty():
			resultado.errores.append_array(carga.errores)
			continue
		var datos: Dictionary = carga.escenario
		var accion: Dictionary = datos.acciones[datos.ruta_ideal[-1]]
		var titulo := TextoLimpio.limpiar(datos.titulo)
		resultado.ordenes.append({"archivo": archivo, "id": datos.id, "titulo": titulo.texto,
			"marca": titulo.etiqueta, "misiones": datos.get("indicios", []).size(),
			"zona": datos.zona, "grupo_funcion": datos.grupo_funcion, "dificultad": datos.dificultad,
			"competencia": Banco.COMPETENCIAS[accion.competencia]})
	return resultado


static func resueltas_por(tecnico: Dictionary) -> Dictionary:
	if not tecnico.has_all(["base", "id"]):
		return {}
	var filas: Variant = Acceso.consultar(tecnico.base, """
		SELECT DISTINCT escenario FROM evento
		WHERE tecnico = ? AND CASE WHEN json_valid(estado_despues) THEN
			COALESCE(json_extract(estado_despues, '$.estado.resuelto'),
				json_extract(estado_despues, '$.resuelto')) = 1 END
	""", [tecnico.id])
	var resueltas := {}
	if filas is Array:
		for fila in filas:
			resueltas[fila.escenario] = true
	return resueltas
