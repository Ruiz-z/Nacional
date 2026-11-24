extends RefCounted

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
		resultado.ordenes.append({"archivo": archivo, "titulo": TextoLimpio.limpiar(datos.titulo).texto,
			"marca": TextoLimpio.limpiar(datos.titulo).etiqueta,
			"zona": datos.zona, "grupo_funcion": datos.grupo_funcion, "dificultad": datos.dificultad,
			"competencia": Banco.COMPETENCIAS[accion.competencia]})
	return resultado
