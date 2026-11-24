extends RefCounted

static func ejecutar() -> bool:
	var sesion = load("res://logica/aprendizaje/sesion.gd")
	if sesion == null:
		return false
	var primera := "seguridad-alto-voltaje"
	var segunda := "diagnostico-fallas"
	var lecciones := []
	for indice in range(3):
		lecciones.append({"competencia": segunda if indice == 1 else primera,
			"explicacion": "Texto de prueba", "fuente": "Etiqueta de prueba", "minutos": 4,
			"items": [{"id": "a%d" % indice}, {"id": "b%d" % indice}]})
	var preparada: Dictionary = sesion.preparar([primera, segunda], lecciones)
	if preparada.lecciones.size() != 3 or not preparada.avisos.is_empty():
		return false
	if sesion.preparar([primera, segunda], lecciones.slice(0, 2)).avisos.is_empty():
		return false
	var intentos := []
	for leccion in preparada.lecciones:
		for item in leccion.items:
			intentos.append({"competencia": leccion.competencia, "item": item.id, "valor": 100,
				"peso": 1, "formato": "opcion-multiple"})
	if not sesion.cerrar(preparada, intentos.slice(0, 5), [], 1).is_empty():
		return false
	var cierre: Dictionary = sesion.cerrar(preparada, intentos, [], 1)
	return cierre.dominios[primera] == 100 and cierre.dominios[segunda] == 100 \
		and cierre.ruta[0] != primera
