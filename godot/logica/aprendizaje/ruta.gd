extends RefCounted

static func ordenar(dominios: Dictionary, intentos: Array, sesion: int) -> Array:
	var orden := dominios.keys()
	var criticas := pendientes_criticas(intentos)
	var brechas := {}
	for intento in intentos:
		if intento.get("tipo_error") == "diagnostico-vs-accion" and intento.get("sesion") == sesion:
			brechas[intento.competencia] = brechas.get(intento.competencia, 0) + 1
	orden.sort_custom(func(a: String, b: String) -> bool:
		var prioridad_a := prioridad(a, dominios[a], criticas, brechas)
		var prioridad_b := prioridad(b, dominios[b], criticas, brechas)
		for indice in range(prioridad_a.size()):
			if prioridad_a[indice] != prioridad_b[indice]:
				return prioridad_a[indice] > prioridad_b[indice]
		return a < b)
	return orden


static func prioridad(competencia: String, dominio: float, criticas: Dictionary, brechas: Dictionary) -> Array:
	var peso := 2 if competencia == "seguridad-alto-voltaje" else 1
	return [int(criticas.has(competencia)), int(brechas.get(competencia, 0) >= 2),
		(100.0 - dominio) * peso, -dominio]


static func pendientes_criticas(intentos: Array) -> Dictionary:
	var pendientes := {}
	for intento in intentos:
		if intento.get("tipo_error") == "falta-critica":
			pendientes[intento.competencia] = true
		elif intento.get("resultado") == "correcto" or intento.get("valor") == 100:
			pendientes.erase(intento.competencia)
	return pendientes


static func critica_reciente(intentos: Array, competencia: String, sesion: int) -> bool:
	for intento in intentos:
		var numero: int = intento.get("sesion", -1)
		if intento.competencia == competencia and intento.get("tipo_error") == "falta-critica" \
				and numero >= maxi(0, sesion - 2) and numero <= sesion:
			return true
	return false


static func aprobada(dominio: float, tiene_critica_reciente: bool) -> bool:
	return dominio >= 70 and not tiene_critica_reciente


# Práctica que se recomienda según el error que más se repite.
const REFUERZOS := {
	"punto-de-medicion-incorrecto": "Practica la referencia: punta negra en TP0 y roja en el borne que mides.",
	"valor-fuera-de-rango": "Practica comparar la lectura del multímetro con lo que anotas y con la escala.",
	"lectura-mal-interpretada": "Practica comparar dos patrones de lectura que dan el mismo síntoma.",
	"paso-omitido": "Practica el orden: mide, anota, interpreta y verifica antes de cerrar.",
	"orden-incorrecto": "Practica el orden de los pasos del procedimiento de diagnóstico.",
	"causa-equivocada": "Practica descartar causas con una medición antes de elegir una.",
	"herramienta-equivocada": "Practica elegir la herramienta que pide cada paso.",
	"paso-innecesario": "Practica ir directo a los pasos que aportan evidencia.",
}


const NOMBRES_ERROR := {
	"punto-de-medicion-incorrecto": "medir en el punto equivocado",
	"valor-fuera-de-rango": "anotar un valor fuera de rango",
	"lectura-mal-interpretada": "interpretar mal una lectura",
	"paso-omitido": "omitir un paso",
	"orden-incorrecto": "alterar el orden de los pasos",
	"causa-equivocada": "elegir la causa equivocada",
	"herramienta-equivocada": "usar la herramienta equivocada",
	"paso-innecesario": "hacer pasos innecesarios",
}


# Motivo y práctica sugerida de cada tema de la ruta, en el orden recibido.
static func motivos(orden: Array, dominios: Dictionary, intentos: Array, sesion: int) -> Array:
	var criticas := pendientes_criticas(intentos)
	var resultado := []
	for competencia in orden:
		var motivo := "Tu dominio es de %d %%." % roundi(dominios.get(competencia, 0.0))
		var refuerzo := ""
		var conteo := {}
		var brechas := 0
		for intento in intentos:
			if intento.competencia != competencia:
				continue
			var tipo: Variant = intento.get("tipo_error")
			if tipo == "diagnostico-vs-accion" and intento.get("sesion") == sesion:
				brechas += 1
			elif tipo is String and REFUERZOS.has(tipo):
				conteo[tipo] = conteo.get(tipo, 0) + 1
		if criticas.has(competencia):
			motivo = "Tuviste una falta crítica reciente."
		elif brechas >= 2:
			motivo = "Respondiste bien en teoría, pero fallaste al aplicarlo."
		elif not conteo.is_empty():
			var frecuente: String = conteo.keys().reduce(func(a: String, b: String) -> String:
				return a if conteo[a] >= conteo[b] else b)
			motivo = "Lo que más repetiste fue %s." % NOMBRES_ERROR[frecuente]
			refuerzo = REFUERZOS[frecuente]
		resultado.append({"competencia": competencia, "motivo": motivo, "refuerzo": refuerzo})
	return resultado
