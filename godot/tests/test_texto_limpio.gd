extends RefCounted

const Texto = preload("res://logica/texto_limpio.gd")
const Rutas = preload("res://logica/rutas_contenido.gd")
const MenuPieza = preload("res://logica/simulador/menu_pieza.gd")
const Motor = preload("res://logica/simulador/motor.gd")
const Actividad = preload("res://escenas/actividad_aprendizaje.tscn")
const Tarjeta = preload("res://escenas/flashcard.tscn")
const PROHIBIDAS := ["[muestra]", "[demo]", " — ", ";", "se requiere",
	"el participante", "maqueta virtual", "sector simulado", "indicio"]
const CAMPOS := ["titulo", "descripcion", "etiqueta", "ayuda", "aviso", "motivo",
	"explicacion_seguridad", "explicacion_causa", "pregunta", "opciones", "sintomas",
	"codigo_falla", "accion", "resultado", "instruccion", "explicacion", "indicio",
	"costo", "tiempo", "riesgo", "causas", "fuente"]


static func ejecutar() -> bool:
	var carpeta := Rutas.resolver("escenarios", true)
	var archivos := DirAccess.get_files_at(carpeta)
	if archivos.is_empty():
		return false
	for nombre in archivos:
		if nombre.get_extension() != "json":
			continue
		var ruta := carpeta.path_join(nombre)
		var escenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		if not recorrer(escenario, ruta):
			return false
		var motor := Motor.new(escenario)
		for regla in escenario.acciones.values() + escenario.recuperaciones.values():
			for entrada in MenuPieza.entradas(motor, escenario, regla.componente):
				if not revisar(entrada.titulo, ruta) or not revisar(entrada.descripcion, ruta):
					return false
	var ruta_banco := Rutas.resolver("banco.json")
	var banco: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta_banco))
	if not recorrer(banco, ruta_banco) or not revisar_banco(banco.items):
		return false
	if Texto.limpiar("[DEMO] Taller-01") != {"texto": "Taller-01", "etiqueta": "Demo"}:
		return false
	var tarjeta := Tarjeta.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(tarjeta)
	tarjeta.encolar({"tipo": "cierre", "titulo": "[MUESTRA] Cierre", "texto": "[MUESTRA] Revisa el foco.",
		"donde": "", "fuente": "[MUESTRA] valor de ejemplo, sin fuente oficial"})
	var marca: Label = tarjeta.get_node("%Marca")
	var correcto: bool = marca.visible and marca.text == "Ejemplo didáctico" \
		and marca.theme_type_variation == &"ChipOrden" and marca.get_parent() == tarjeta.chip.get_parent() \
		and marca.get_index() == tarjeta.chip.get_index() + 1 \
		and tarjeta.cuerpo.text == "Revisa el foco." and tarjeta.titulo.text == "Cierre" \
		and tarjeta.fuente.text == "Fuente: ejemplo didáctico, sin fuente oficial"
	tarjeta.free()
	return correcto


static func recorrer(valor: Variant, ruta: String, visible := false, es_fuente := false) -> bool:
	if valor is Dictionary:
		for clave in valor:
			if not recorrer(valor[clave], ruta + "/" + str(clave),
					visible or clave in CAMPOS, es_fuente or clave == "fuente"):
				return false
	elif valor is Array:
		for elemento in valor:
			if not recorrer(elemento, ruta, visible, es_fuente):
				return false
	elif valor is String and visible:
		return revisar(Texto.fuente(valor) if es_fuente else Texto.linea(valor), ruta)
	return true


static func revisar(texto: String, ruta: String) -> bool:
	for prohibida in PROHIBIDAS:
		if prohibida in texto.to_lower():
			printerr(ruta, ": ", texto)
			return false
	return true



static func revisar_banco(items: Array) -> bool:
	var pantalla := Actividad.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(pantalla)
	pantalla.actividad.items = items
	var correcto := true
	for item in items:
		pantalla.mostrar_item()
		if item.formato == "caso-diagnostico":
			for paso in item.pasos:
				pantalla.agregar_paso(paso)
		var ruta: String = item.id
		correcto = revisar_nodo(pantalla, ruta) \
			and (not item.muestra or pantalla.contenido.get_node("Marca").text == "Ejemplo didáctico")
		if not correcto:
			break
		pantalla.actividad.intentos.append({})
	pantalla.free()
	return correcto


static func revisar_nodo(nodo: Node, ruta: String) -> bool:
	if nodo is Label or nodo is RichTextLabel or nodo is Button:
		if not revisar(nodo.text, ruta):
			return false
	for hijo in nodo.get_children():
		if not revisar_nodo(hijo, ruta):
			return false
	return true
