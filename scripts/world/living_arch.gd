@tool
extends Node3D

@export var crown_height := 4.5
@export var span := 6.6

func _ready() -> void:
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.252, 0.167, 0.092)
	bark.roughness = 0.97
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.256, 0.46, 0.18)
	leaves.roughness = 0.89
	for side in [-1, 1]:
		var from := Vector3(-side * span * 0.5, -0.15, -side * 0.46)
		var turn := Vector3(-side * span * 0.54, crown_height * 0.82, side * 0.29)
		var crown := Vector3(side * span * 0.28, crown_height, side * 0.53)
		var previous := from
		for index in range(1, 10):
			var t := float(index) / 9
			var next := from.lerp(turn, t).lerp(turn.lerp(crown, t), t)
			_branch_segment(previous, next, lerpf(0.40, 0.082, t), bark)
			if t > 0.48:
				var tuft := SphereMesh.new()
				tuft.radius = 0.43 + 0.17 * sin(index * 1.87 + side)
				tuft.height = tuft.radius * 1.44
				tuft.radial_segments = 6
				tuft.rings = 3
				tuft.material = leaves
				_place(tuft, next + Vector3(side * 0.09, 0.20, side * 0.32))
			previous = next

func _branch_segment(from: Vector3, to: Vector3, radius: float, material: Material) -> void:
	var delta := to - from
	var branch := CylinderMesh.new()
	branch.height = delta.length() + 0.14
	branch.bottom_radius = radius * 1.12
	branch.top_radius = radius
	branch.radial_segments = 7
	branch.material = material
	var mesh := _place(branch, from.lerp(to, 0.5))
	mesh.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))

func _place(mesh: Mesh, point: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = point
	add_child(instance)
	return instance
