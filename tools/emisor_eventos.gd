extends SceneTree

const EVENTOS := [
	["bloqueo", 1, 0],
	["etiquetado", 1, 60],
	["torque", 42, 120],
	["confirmar", 1, 180],
	["confirmar", 1, 240],
	["confirmar", 1, 300],
]


func _initialize() -> void:
	for indice in range(EVENTOS.size()):
		var evento: Array = EVENTOS[indice]
		print(JSON.stringify({"v": 1, "n": indice, "t": evento[2], "ctrl": evento[0], "valor": evento[1]}))
	quit(0)
