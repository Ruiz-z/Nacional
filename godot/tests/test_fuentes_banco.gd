extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const PruebaCarga = preload("res://tests/test_carga_banco.gd")


static func ejecutar() -> bool:
	var item := PruebaCarga.item()
	if not acepta(item):
		return false
	item.competencia = "seguridad-alto-voltaje"
	if acepta(item):
		return false

	item.fuente = {"origen": "NFPA 70E", "titulo": "NFPA 70E", "seccion": "120",
		"referencia": "Edición de prueba"}
	if not acepta(item):
		return false
	item.muestra = false
	if acepta(item):
		return false
	item.fuente.origen = "material-oficial"
	if not acepta(item):
		return false
	item.fuente.origen = "blog"
	if acepta(item):
		return false
	item.fuente.origen = "material-oficial"
	item.fuente.seccion = ""
	return not acepta(item)


static func acepta(item: Dictionary) -> bool:
	var resultado := Banco.validar_texto(JSON.stringify({"items": [item]}), "fuentes.json")
	return resultado.items.size() == 1 and resultado.errores.is_empty()
