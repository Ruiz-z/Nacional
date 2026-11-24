extends RefCounted

const Escenario = preload("res://logica/simulador/escenario.gd")


static func ejecutar() -> bool:
	var datos: Dictionary = Escenario.cargar(Escenario.AISLAMIENTO).escenario
	if datos.is_empty() or Escenario.cargar("escenarios/comunicacion.json").escenario.is_empty():
		return false
	if not comprobar_indicios(datos):
		return false
	datos.acciones.inspeccionar.componente = "inventado"
	var errores: Array = Escenario.validar(datos, "prueba.json").errores
	return errores.size() == 1 and errores[0].begins_with("prueba.json: acciones.inspeccionar.componente:")


static func comprobar_indicios(datos: Dictionary) -> bool:
	var anterior := datos.duplicate(true)
	anterior.erase("indicios")
	if not Escenario.validar(anterior, "prueba.json").errores.is_empty():
		return false
	anterior.indicios = [{"clave": "resuelto", "etiqueta": "Falla resuelta"}]
	if not Escenario.validar(anterior, "prueba.json").errores.is_empty():
		return false
	for invalidos in [null, {}, [{}], [{"clave": "sector", "etiqueta": "Sector"}],
			[{"clave": "desconocida", "etiqueta": "Paso"}],
			[{"clave": "resuelto", "etiqueta": "Paso", "ayuda": "  "}],
			[{"clave": "resuelto", "etiqueta": "Paso", "ayuda": 1}],
			[{"clave": "resuelto", "etiqueta": "  "}], [datos.indicios[0], datos.indicios[0]]]:
		anterior.indicios = invalidos
		var errores: Array = Escenario.validar(anterior, "prueba.json").errores
		if errores.size() != 1 or not errores[0].begins_with("prueba.json: indicios:"):
			return false
	return true
