extends RefCounted

const Bus = preload("res://escenas/bus.tscn")
const Rutas = preload("res://logica/rutas_contenido.gd")
const Inventario = preload("res://logica/simulador/inventario.gd")
const Acciones = preload("res://tests/acciones_taller.gd")


static func ejecutar() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	var visor := SubViewport.new()
	visor.size = Vector2i(1280, 720)
	visor.own_world_3d = true
	arbol.root.add_child(visor)
	var archivos := DirAccess.get_files_at(Rutas.resolver("escenarios", true))
	var fallo := "No se encontraron órdenes." if archivos.is_empty() else ""
	for archivo in archivos:
		if not archivo.ends_with(".json"):
			continue
		var bus := Bus.instantiate()
		bus.archivo = "escenarios/" + archivo
		bus.modo_captura = true
		visor.add_child(bus)
		bus.flashcard.confirmar()
		bus.jugador.set_physics_process(false)
		if archivo == "motor.json":
			fallo = comprobar_teclas_y_flecha(bus)
		if fallo.is_empty() and archivo == "motor.json":
			fallo = comprobar_muebles(bus)
		if fallo.is_empty():
			fallo = comprobar_requisitos(bus)
		bus.free()
		if not fallo.is_empty():
			printerr(archivo, ": ", fallo)
			break
	visor.free()
	return fallo.is_empty()


static func comprobar_teclas_y_flecha(bus: Node3D) -> String:
	var taller: Node3D = bus.taller
	var destino: Vector3 = taller.pieza_guia.global_position
	bus.jugador.ubicar(destino + Vector3(0, -1.0, 3.8))
	bus.apuntar_jugador(destino)
	taller.actualizar_flecha(bus.jugador.camara, true)
	if taller.flecha.visible:
		return "La flecha debe ocultarse cuando el cajón está en cuadro."
	bus.jugador.rotate_y(-PI / 2.0)
	taller.actualizar_flecha(bus.jugador.camara, true)
	if not taller.flecha.visible or taller.distancia_guia.text != "Caja de herramientas · 4 m" \
			or taller.flecha.position.x >= 100:
		return "La flecha debe indicar el borde izquierdo y la distancia."
	bus.jugador.rotate_y(PI)
	taller.actualizar_flecha(bus.jugador.camara, true)
	if not taller.flecha.visible or taller.flecha.position.x <= 1180:
		return "La flecha debe cambiar al borde derecho al girar la cámara."
	var suave: Color = taller.baliza.material_override.albedo_color
	tecla(bus, KEY_V)
	bus.actualizar_mision()
	if bus.guia_automatica or taller.pieza_guia != null or not taller.mallas_guia.is_empty():
		return "V debe apagar la guía automática."
	var siguiente_orden := Bus.instantiate()
	var preferencia_conservada: bool = not siguiente_orden.guia_automatica
	siguiente_orden.free()
	if not preferencia_conservada:
		return "La preferencia de V debe conservarse al abrir otra orden."
	tecla(bus, KEY_G)
	if not taller.baliza.visible or taller.baliza.material_override.albedo_color.a <= suave.a:
		return "G debe reforzar la baliza con la guía automática desactivada."
	taller.caducidad.timeout.emit()
	if taller.baliza.visible or taller.pieza_guia != null:
		return "La guía manual debe caducar."
	tecla(bus, KEY_V)
	if not bus.guia_automatica or taller.pieza_guia == null:
		return "V debe recuperar la guía automática."
	return ""


static func comprobar_muebles(bus: Node3D) -> String:
	var taller: Node3D = bus.taller
	bus.jugador.ubicar(taller.carrito.global_position + Vector3.BACK)
	for id in ["lampara", "multimetro", "flexometro", "llave_ajustable", "destornillador"]:
		if not Acciones.tomar(bus, id):
			return "No se pudo llenar el cinturón y usar el carrito."
	Acciones.tecla(bus, 1)
	if taller.espacio_guia != 5 or taller.tecla_guia.text != "Pulsa 5":
		return "El carrito cercano debe indicar su espacio numerado."
	bus.jugador.ubicar(taller.carrito.global_position + Vector3.BACK * 5.0)
	bus.actualizar_mision()
	if taller.mueble_guia != taller.carrito or not comprobar_marca(bus, taller.objetos.destornillador):
		return "El carrito lejano debe marcarse en el taller."
	if not taller.dejar("destornillador", true, taller.mesa).is_empty():
		return "No se pudo dejar el destornillador en la mesa."
	bus.actualizar_mision()
	if not comprobar_marca(bus, taller.mesa.piezas.mesa_taller):
		return "La guía debe marcar la mesa para liberar espacio en el cinturón."
	if not taller.dejar("llave_ajustable", true, taller.mesa).is_empty():
		return "No se pudo liberar un espacio del cinturón."
	bus.actualizar_mision()
	if taller.mueble_guia != taller.mesa or not comprobar_marca(bus, taller.objetos.destornillador):
		return "La guía debe seguir al destornillador a la mesa."
	return ""


static func comprobar_requisitos(bus: Node3D) -> String:
	var taller: Node3D = bus.taller
	var grupos_por_mision: Array = bus.acciones_mision.values()
	var rotulos: Array[String] = [
		"CAJA DE HERRAMIENTAS", "MESA DE TRABAJO", "REPUESTOS", "CARRITO", "CONSOLA DEL ELEVADOR"
	]
	if bus.datos.zona == "banco":
		rotulos.append("BANCO DE DIAGNÓSTICO")
	for rotulo: Label3D in taller.rotulos.values():
		if not rotulo.is_visible_in_tree() or rotulo.billboard != BaseMaterial3D.BILLBOARD_ENABLED \
				or not rotulo.get_child(0) is MeshInstance3D:
			return "El rótulo %s debe estar visible, con fondo, y mirar a la cámara." % rotulo.text
		rotulos.erase(rotulo.text)
	if not rotulos.is_empty():
		return "Faltan rótulos: " + ", ".join(rotulos)
	var elevador: Node3D = bus.get_node("Elevador")
	if bus.datos.zona == "bajos":
		if not Acciones.tomar(bus, "calzas"):
			return "No se pudieron tomar las calzas para comprobar su ubicación."
		bus.actualizar_mision(true)
		if not bus.hud_mision.filas.any(func(paso: Dictionary) -> bool:
				return paso.texto == "Coloca las calzas sobre las marcas amarillas del suelo, junto a las ruedas."):
			return "Falta la ubicación de las calzas."
		taller.reiniciar()
		elevador.colocar_calzas()
		elevador.mover(true, true)
		for soporte in elevador.trabas:
			elevador.cambiar_traba(soporte, true)
	# Aísla cada grupo real en el HUD para recorrer sus requisitos desde el inventario vacío.
	bus.misiones = [{"clave": "prueba_guia", "etiqueta": "Guía"}]
	for grupos in grupos_por_mision:
		for grupo in grupos:
			taller.reiniciar()
			bus.acciones_mision[0] = [grupo]
			bus.firma_mision.clear()
			bus.actualizar_mision(true)
			var id: String = grupo.ids[0]
			var fallo := comprobar_textos(bus)
			if not fallo.is_empty():
				return id + ": " + fallo
			var requiere: Dictionary = bus.requisitos(id)
			var herramientas: Array = [requiere.herramienta] if requiere.has("herramienta") else requiere.get("herramientas", [])
			for objeto in herramientas + requiere.get("piezas", []):
				var mueble: Node3D = taller.origenes[objeto].zona
				var esperado: Node3D = taller.objetos[objeto]
				if taller.fila_cajon(objeto) >= 0:
					var fila: int = taller.cajones.find(taller.origenes[objeto].padre)
					esperado = taller.pieza_cajon(fila)
					if not comprobar_marca(bus, esperado) or not bus.hud_mision.filas.any(
							func(paso: Dictionary) -> bool: return paso.texto.begins_with("Abre el cajón") and not paso.hecho):
						return "%s: cajón incorrecto para %s." % [id, objeto]
					Acciones.abrir_cajon(bus, fila)
					bus.actualizar_mision()
					esperado = taller.objetos[objeto]
					if not bus.hud_mision.filas.any(func(paso: Dictionary) -> bool:
							return paso.texto.begins_with("Toma " + Inventario.nombre_con_articulo(objeto)) and not paso.hecho):
						return "%s: insiste en abrir un cajón que ya está abierto." % id
				elif mueble == taller.mesa_banco:
					esperado = mueble.piezas[objeto]
				if taller.objetivo != objeto or not comprobar_marca(bus, esperado) or not taller.baliza.visible:
					return "%s: marca incorrecta para tomar %s." % [id, objeto]
				if not Acciones.tomar(bus, objeto):
					return "%s: no se pudo tomar %s." % [id, objeto]
				bus.actualizar_mision()
				if taller.objetivo == objeto or taller.mallas_guia.any(
						func(malla: MeshInstance3D) -> bool: return esperado.is_ancestor_of(malla)):
					return "%s: la marca de %s siguió activa tras tomarlo." % [id, objeto]
				if objeto not in herramientas:
					continue
				Acciones.tecla(bus, 4)
				var espacio: int = taller.espacio_de(objeto)
				if taller.espacio_guia != espacio or taller.tecla_guia.text != "Pulsa %d" % espacio \
						or not taller.espacios_hud[espacio - 1].has_theme_stylebox_override("normal") \
						or not comprobar_marca(bus, null):
					return "%s: espacio incorrecto para %s." % [id, objeto]
				Acciones.tecla(bus, espacio)
			if id.begins_with("medir_tp"):
				if not comprobar_marca(bus, bus.zona_activa.piezas.tp0):
					return "%s: falta la marca para la punta negra." % id
				bus.motor.mediciones.punta_negra = "tp0"
				bus.actualizar_mision()
				if not comprobar_marca(bus, bus.zona_activa.piezas[grupo.regla.componente]):
					return "%s: falta la marca para la punta roja." % id
				bus.motor.mediciones.reiniciar_puntas()
	return ""


static func comprobar_textos(bus: Node3D) -> String:
	var taller: Node3D = bus.taller
	var lugares := {
		"bajos": "debajo del autobús",
		"motor": "compartimiento del motor",
		"faros": "autobús",
		"gabinete": "gabinete de baterías",
		"cabina": "cabina",
		"banco": "banco de diagnóstico",
	}
	for paso in bus.hud_mision.filas:
		var texto: String = paso.texto
		if texto.contains("_") or texto.contains(" · "):
			return "El subpaso contiene un identificador o un separador: " + texto
		if texto.begins_with("Toma "):
			var id: String = paso.guia.objeto
			var mueble: Node3D = taller.mueble_de(id)
			var nombre: String = taller.ubicaciones[mueble].get_slice(",", 0)
			if not texto.begins_with("Toma " + Inventario.nombre_con_articulo(id)) \
					or not texto.contains(nombre.trim_prefix("la ").trim_prefix("el ")) \
					or not taller.rotulos.has(mueble):
				return "Falta el artículo o la ubicación de " + texto
		if texto.contains("Elige "):
			if texto.begins_with("Apunta ") and (not texto.begins_with("Apunta al ") \
					and not texto.begins_with("Apunta a la ") and not texto.begins_with("Apunta a las ") \
					and not texto.begins_with("Apunta a los ")):
				return "Falta el artículo de la pieza en " + texto
			if not [lugares[bus.datos.zona], "compartimiento de los faros", "consola del elevador"].any(
					func(lugar: String) -> bool: return texto.contains(lugar)):
				return "Falta el lugar en " + texto
	return ""


static func comprobar_marca(bus: Node3D, esperado: Node3D) -> bool:
	var taller: Node3D = bus.taller
	if taller.pieza_guia != esperado or (esperado != null and taller.espacio_guia != 0):
		return false
	var marcadas := bus.find_children("*", "MeshInstance3D", true, false).filter(
		func(malla: MeshInstance3D) -> bool: return malla.material_overlay == taller.contorno)
	return marcadas.size() == taller.mallas_guia.size() and (esperado == null or not marcadas.is_empty())


static func tecla(bus: Node3D, codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.pressed = true
	bus.get_viewport().push_input(evento, true)
