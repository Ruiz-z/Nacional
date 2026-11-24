extends RefCounted

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
		resultado.ordenes.append({"archivo": archivo, "titulo": datos.titulo.trim_prefix("[MUESTRA]").strip_edges(),
			"zona": datos.zona, "dificultad": datos.dificultad,
			"competencia": Banco.COMPETENCIAS[accion.competencia]})
	return resultado
