extends RefCounted

const Banco = preload("res://logica/competencias/banco.gd")
const PruebaCarga = preload("res://tests/test_carga_banco.gd")


static func ejecutar() -> bool:
	var banco: GDScript = Banco
	if not banco.has_method("consultar"):
		return false
	var item := PruebaCarga.item()
	var facil := item.duplicate()
	facil.merge({"id": "facil", "dificultad": "facil"}, true)
	var otra_competencia := item.duplicate()
	otra_competencia.merge({"id": "otra", "competencia": "electronica-conectividad"}, true)
	var invalido := item.duplicate()
	invalido.merge({"id": "invalido", "fuente": ""}, true)
	var dificil := item.duplicate()
	dificil.merge({"id": "dificil", "dificultad": "dificil"}, true)
	var resultado := Banco.validar_texto(JSON.stringify({"items":
		[item, facil, otra_competencia, invalido, dificil]}), "consulta.json")
	var consulta: Array = banco.call("consultar", resultado, item.competencia, "media")
	return consulta.size() == 1 and consulta[0].id == item.id and consulta[0].fuente == item.fuente \
		and resultado.errores.size() == 1 and resultado.get("avisos", []).size() == 4 \
		and banco.call("consultar", resultado, item.competencia, "dificil").size() == 1 \
		and banco.call("consultar", resultado, "seguridad-alto-voltaje", "media").is_empty()
