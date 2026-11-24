extends RefCounted

const Entrada = preload("res://logica/entrada/entrada.gd")
const Protocolo = preload("res://logica/entrada/protocolo.gd")
const Escenario = preload("res://logica/simulador/escenario.gd")
const Motor = preload("res://logica/simulador/motor.gd")

static func ejecutar() -> bool:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var salida: Array = []
	var argumentos := ["--headless", "--no-header", "-s", raiz.path_join("tools/emisor_eventos.gd")]
	if OS.execute(OS.get_executable_path(), argumentos, salida, true) != 0 or salida.is_empty():
		return false

	var datos := Escenario.cargar(raiz.path_join("contenido/escenarios/aislamiento.json"))
	if not datos.errores.is_empty():
		return false
	var motor := Motor.new(datos.escenario)
	var entrada := Entrada.new()
	var protocolo := Protocolo.new()
	var pasos := ["inspeccionar", "evaluar_indicio", "confirmar_solucion"]
	var anterior := 0
	for linea in str(salida[0]).split("\n", false):
		var evento := protocolo.recibir(linea, "virtual")
		if evento.is_empty():
			return false
		var accion: Dictionary = entrada.procesar_lote([evento])[0]
		if accion.accion == "confirmar":
			if pasos.is_empty() or not motor.ejecutar(pasos.pop_front(), accion.fuente_entrada,
					evento.t - anterior).aplicada:
				return false
			anterior = evento.t

	var resultados := motor.resultados("2026-11-24")
	return protocolo.errores().is_empty() and pasos.is_empty() and motor.fin() == "resuelto" \
		and resultados.eventos.back().fuente_entrada == "virtual" and motor.puntaje() == 100
