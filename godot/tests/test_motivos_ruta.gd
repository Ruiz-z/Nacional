extends RefCounted

const Ruta = preload("res://logica/aprendizaje/ruta.gd")


static func fila(competencia: String, tipo: Variant, sesion := 0) -> Dictionary:
	return {"competencia": competencia, "tipo_error": tipo, "sesion": sesion, "resultado": "incorrecto", "valor": 0}


static func ejecutar() -> bool:
	var orden := ["seguridad-alto-voltaje", "diagnostico-fallas", "sistema-electrico-bateria", "electronica-conectividad"]
	var dominios := {"seguridad-alto-voltaje": 20.0, "diagnostico-fallas": 55.0,
		"sistema-electrico-bateria": 80.0, "electronica-conectividad": 70.0}
	var intentos := [fila("seguridad-alto-voltaje", "falta-critica"),
		fila("diagnostico-fallas", "punto-de-medicion-incorrecto"), fila("diagnostico-fallas", "punto-de-medicion-incorrecto"),
		fila("diagnostico-fallas", "paso-omitido"),
		fila("electronica-conectividad", "diagnostico-vs-accion", 1), fila("electronica-conectividad", "diagnostico-vs-accion", 1)]
	var m := Ruta.motivos(orden, dominios, intentos, 1)
	return m.size() == 4 \
		and m[0].motivo == "Tuviste una falta crítica reciente." and m[0].refuerzo.is_empty() \
		and m[1].motivo.contains("medir en el punto equivocado") and m[1].refuerzo == Ruta.REFUERZOS["punto-de-medicion-incorrecto"] \
		and m[2].motivo == "Tu dominio es de 80 %." \
		and m[3].motivo.begins_with("Respondiste bien en teoría")
