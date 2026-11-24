extends StaticBody3D

var zona: Node3D
var componente: String
var nombre: String
var superficie: MeshInstance3D


func resaltar(activo: bool) -> void:
	if superficie == null:
		return
	var material := superficie.material_override as StandardMaterial3D
	material.emission_enabled = activo
	material.emission = Color(1.0, 0.75, 0.32)
	material.emission_energy_multiplier = 0.45
