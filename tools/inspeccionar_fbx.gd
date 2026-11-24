extends SceneTree

# godot --headless --path godot -s ../tools/inspeccionar_fbx.gd
func _initialize() -> void:
	inspeccionar.call_deferred()


func inspeccionar() -> void:
	var escena := preload("res://escenas/bus.tscn").instantiate()
	var autobus := escena.get_node("Autobus") as Node3D
	print("BUS.fbx: posición ", autobus.position, ", escala ", autobus.scale,
		", rotación ", autobus.rotation_degrees)
	autobus.owner = null
	escena.remove_child(autobus)
	root.add_child(autobus)
	recorrer(autobus)
	autobus.free()
	escena.free()
	quit()


func recorrer(nodo: Node) -> void:
	print(nodo.get_path())
	if nodo is MeshInstance3D and nodo.mesh != null:
		print("  AABB mundial ", nodo.global_transform * nodo.get_aabb())
		for indice in range(nodo.mesh.get_surface_count()):
			var material: Material = nodo.get_active_material(indice)
			print("  Superficie ", indice, " · ", nodo.mesh.surface_get_name(indice),
				" · material ", material.resource_name if material != null else "sin material")
			var vertices: PackedVector3Array = nodo.mesh.surface_get_arrays(indice)[Mesh.ARRAY_VERTEX]
			var limites := {}
			for vertice in vertices:
				var punto: Vector3 = nodo.global_transform * vertice
				var lado := "x < 0" if punto.x < 0 else "x >= 0"
				limites[lado] = limites.get(lado, AABB(punto, Vector3.ZERO)).expand(punto)
			print("    AABB por costado ", limites)
			if nodo.name == "Bus_Body" and nodo.mesh.surface_get_name(indice) == "Windows":
				imprimir_islas(nodo.global_transform, vertices,
					nodo.mesh.surface_get_arrays(indice)[Mesh.ARRAY_INDEX])
	for hijo in nodo.get_children():
		recorrer(hijo)


func imprimir_islas(transformacion: Transform3D, vertices: PackedVector3Array,
		indices: PackedInt32Array) -> void:
	# Une vértices duplicados del vidrio para obtener los límites de cada paño.
	var vecinos := {}
	for i in range(0, indices.size(), 3):
		var triangulo: Array[Vector3] = []
		for j in range(3):
			triangulo.append((transformacion * vertices[indices[i + j]]).snapped(Vector3.ONE * 0.001))
		for punto in triangulo:
			if not vecinos.has(punto):
				vecinos[punto] = []
			vecinos[punto].append_array(triangulo)
	for origen in vecinos.keys():
		if not vecinos.has(origen):
			continue
		var pendientes := [origen]
		var caja := AABB(origen, Vector3.ZERO)
		while not pendientes.is_empty():
			var punto: Vector3 = pendientes.pop_back()
			if vecinos.has(punto):
				pendientes.append_array(vecinos[punto])
				vecinos.erase(punto)
				caja = caja.expand(punto)
		print("    Paño de vidrio ", caja)
