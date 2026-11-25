extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const Niveles = preload("res://logica/flujo/niveles.gd")
const Registro = preload("res://logica/aprendizaje/registro.gd")
const Ordenes = preload("res://escenas/ordenes.tscn")
const Menu = preload("res://escenas/menu.tscn")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")

const COMPETENCIA := "seguridad-alto-voltaje"


static func ejecutar() -> bool:
	return umbrales() and Base.con_base(con_base)


static func umbrales() -> bool:
	return Niveles.desbloqueada("facil", 0.0) and not Niveles.desbloqueada("media", 49.0) \
		and Niveles.desbloqueada("media", 50.0) and not Niveles.desbloqueada("dificil", 74.0) \
		and Niveles.desbloqueada("dificil", 75.0) and Niveles.nivel_abierto(10.0) == "facil" \
		and Niveles.nivel_abierto(60.0) == "media" and Niveles.nivel_abierto(90.0) == "dificil"


static func intento(valor: int, dificultad: String) -> Dictionary:
	return {"competencia": COMPETENCIA, "item": "n-" + str(valor), "formato": "opcion-multiple",
		"dificultad": dificultad, "respuesta": "a", "resultado": "correcto" if valor > 0 else "incorrecto",
		"tipo_error": null, "tiempo_ms": 1000, "fuente_entrada": "teclado", "momento": "pre",
		"reloj_sim": "2026-01-01T00:00:00Z", "version_contenido": "1"}


static func con_base(base: String) -> bool:
	var menu := Menu.instantiate()
	menu.base = base
	(Engine.get_main_loop() as SceneTree).root.add_child(menu)
	Pantallas.entrar(menu, "tecnico-niv")
	var perfil: Dictionary = menu.perfil
	var practica: Button = menu.botones.escenario
	var antes_bloqueada: bool = practica.disabled
	var dominios := Niveles.dominios(base, perfil.alias)
	if dominios[COMPETENCIA] != 0.0 or not antes_bloqueada:
		printerr("Sin diagnóstico la práctica debe estar bloqueada")
		return false
	for i in range(4):
		Registro.guardar(base, perfil.alias, intento(1, "facil"))
	if Niveles.dominios(base, perfil.alias)[COMPETENCIA] < 99.0:
		printerr("El dominio no sube con aciertos")
		return false
	var ordenes := Ordenes.instantiate()
	ordenes.tecnico = perfil.merged({"base": base})
	(Engine.get_main_loop() as SceneTree).root.add_child(ordenes)
	var bloqueadas := 0
	var correcto: bool = ordenes.catalogo.size() > 0
	for orden in ordenes.catalogo:
		var esperado: bool = orden.competencia_id != COMPETENCIA and orden.dificultad != "facil"
		correcto = correcto and ordenes.bloqueada(orden) == esperado
		bloqueadas += 1 if esperado else 0
	var libre := Ordenes.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(libre)
	var todas_abiertas: bool = libre.catalogo.all(func(o: Dictionary) -> bool: return not libre.bloqueada(o))
	menu.free()
	ordenes.free()
	libre.free()
	return correcto and bloqueadas > 0 and todas_abiertas
