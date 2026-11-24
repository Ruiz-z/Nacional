extends RefCounted


# Las rutas relativas identifican archivos dentro de contenido/.
static func resolver(ruta: String, directorio := false) -> String:
	if ruta.is_absolute_path():
		return ruta
	var relativa := ruta.trim_prefix("../contenido/").trim_prefix("contenido/")
	var junto_al_ejecutable := OS.get_executable_path().get_base_dir().path_join("contenido").path_join(relativa)
	if FileAccess.file_exists(junto_al_ejecutable) or (directorio and DirAccess.dir_exists_absolute(junto_al_ejecutable)):
		return junto_al_ejecutable
	return ProjectSettings.globalize_path("res://").path_join("../contenido").path_join(relativa).simplify_path()
