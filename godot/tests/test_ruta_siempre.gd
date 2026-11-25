extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Menu = preload("res://escenas/menu.tscn")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Actividad = preload("res://logica/flujo/actividad_aprendizaje.gd")


static func ejecutar() -> bool:
	return Base.con_base(comprobar)


static func comprobar(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	Pantallas.entrar(menu, "tecnico-ruta")
	var bloqueada_antes: bool = menu.botones.ruta.disabled
	var perfil: Dictionary = menu.perfil
	Registro.guardar(base, perfil.alias, {"competencia": "seguridad-alto-voltaje", "item": "x",
		"formato": "opcion-multiple", "dificultad": "facil", "respuesta": "a", "resultado": "correcto",
		"tipo_error": null, "tiempo_ms": 1, "fuente_entrada": "teclado", "momento": "pre",
		"reloj_sim": "2026-01-01T00:00:00Z", "version_contenido": "1"})
	Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", perfil.id, "diagnostico", [], 0, 1000)
	menu.actualizar()
	var abierta_despues: bool = not menu.botones.ruta.disabled
	var actividad := Actividad.new()
	actividad.base = base
	actividad.perfil = perfil
	actividad.paso = "ruta"
	var abre := actividad.preparar({}, 1000)
	Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", perfil.id, "ruta", [], 0, 2000)
	menu.actualizar()
	var abierta_tras_cerrar: bool = not menu.botones.ruta.disabled
	var otra := Actividad.new()
	otra.base = base
	otra.perfil = perfil
	otra.paso = "ruta"
	var reabre := otra.preparar({}, 3000)
	var cierre := otra.guardar(3000)
	menu.free()
	return bloqueada_antes and abierta_despues and abre and abierta_tras_cerrar and reabre \
		and cierre.get("guardado", false)
