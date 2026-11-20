@tool
extends AnimatableBody3D

@export var panel_size := Vector3(2.4, 2.8, 0.18)
@export_enum("Left", "Right") var hinge_side := 0
@export_enum("Barracks", "Chapel", "Tower", "Keep") var style := 0
@export var has_lock_plate := false

const WOOD: Array[Color] = [
	Color(0.29, 0.17, 0.10), Color(0.35, 0.205, 0.122),
	Color(0.24, 0.14, 0.12), Color(0.32, 0.19, 0.10),
]

func _ready() -> void:
	var sign_x := 1.0 if hinge_side == 0 else -1.0
	var panel_center := panel_size.x * 0.5 * sign_x
	var blocker := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = panel_size
	if style == 3:
		# Keep the center seam easy to target with the interaction ray.
		shape.size.x += 0.05
	blocker.shape = shape
	blocker.position.x = panel_center
	add_child(blocker)

	var iron := _material(Color(0.135, 0.145, 0.16), 0.56)
	var edge := _material(WOOD[style].darkened(0.28), 0.0)
	var brass := _material(Color(0.55, 0.34, 0.11), 0.53)
	var plank_count := maxi(6, roundi(panel_size.x / 0.27))
	var plank_width := panel_size.x / plank_count
	_box(panel_size * Vector3(0.994, 1, 0.80), Vector3(panel_center, 0, 0), edge)
	for i in plank_count:
		var shade := WOOD[style].lightened(0.035 * sin(i * 2.7) + 0.028)
		var plank_x := (i + 0.5) * plank_width * sign_x
		_box(Vector3(plank_width - 0.016, panel_size.y - 0.042, panel_size.z),
			Vector3(plank_x, 0, 0), _material(shade, 0.0))

	var grip_x := (panel_size.x - 0.30) * sign_x
	var grip_y := 1.25 - panel_size.y * 0.5
	for face in [-1.0, 1.0]:
		var iron_z: float = face * (panel_size.z * 0.5 + 0.026)
		for y_ratio in [-0.33, 0.31]:
			var strap_y: float = panel_size.y * y_ratio
			_box(Vector3(panel_size.x - 0.20, 0.132, 0.055),
				Vector3(panel_center, strap_y, iron_z), iron)
			_box(Vector3(0.14, 0.29, 0.088), Vector3(sign_x * 0.115, strap_y, iron_z), iron)
			for stud in [0.26, 0.5, 0.76, 0.9]:
				_box(Vector3(0.045, 0.046, 0.04),
					Vector3(sign_x * panel_size.x * stud, strap_y, iron_z * 1.16), brass)

		var hardware := brass if style in [1, 3] else iron
		_box(Vector3(0.16, 0.24, 0.05), Vector3(grip_x, grip_y, iron_z), hardware)
		var loop := TorusMesh.new()
		loop.inner_radius = 0.067
		loop.outer_radius = 0.102
		loop.rings = 10
		loop.ring_segments = 6
		loop.material = hardware
		_add_mesh(loop, Vector3(grip_x, grip_y - 0.076, iron_z + 0.05 * face), Vector3(PI / 2, 0, 0))
		if has_lock_plate:
			_box(Vector3(0.21, 0.27, 0.054), Vector3(grip_x, grip_y - 0.31, iron_z), brass)
			_box(Vector3(0.049, 0.105, 0.012),
				Vector3(grip_x, grip_y - 0.31, iron_z + 0.031 * face), iron)

func _material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.77
	return material

func _box(size: Vector3, at: Vector3, material: Material) -> void:
	var panel := BoxMesh.new()
	panel.size = size
	panel.material = material
	_add_mesh(panel, at, Vector3.ZERO)

func _add_mesh(mesh: Mesh, at: Vector3, tilt: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.rotation = tilt
	add_child(part)
