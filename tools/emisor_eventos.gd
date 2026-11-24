extends SceneTree

const EVENTOS := [
	["bloqueo", 1, 0],
	["etiquetado", 1, 60],
	["torque", 42, 120],
	["confirmar", 1, 180],
	["confirmar", 1, 240],
	["confirmar", 1, 300],
]


const BANCO := [
	["nodo_p", 0, 1000],
	["nodo_q", 1, 1000],
	["nodo_p", 1, 1100],
]


func _initialize() -> void:
	var es_banco := "--banco" in OS.get_cmdline_user_args()
	var eventos := BANCO if es_banco else EVENTOS
	if es_banco:
		print('{"v":1,"ctrl":"hb"}')
	for indice in range(eventos.size()):
		var evento: Array = eventos[indice]
		print(JSON.stringify({"v": 1, "n": indice, "t": evento[2], "ctrl": evento[0], "valor": evento[1]}))
	quit(0)
