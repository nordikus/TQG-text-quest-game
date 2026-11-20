@tool
extends Node3D

@export var burned := false

const TIMBER := Color(0.37, 0.23, 0.125)
const END_GRAIN := Color(0.53, 0.36, 0.20)
const CHARCOAL := Color(0.11, 0.073, 0.055)
const IRON := Color(0.18, 0.17, 0.16)
const STONE := Color(0.34, 0.33, 0.31)

func _ready() -> void:
	if burned:
		_add_collapse()
	else:
		_add_shoring()
	_add_timber_shed()

func _add_shoring() -> void:
	for z in [-2.85, 2.85]:
		for x in [-1.8, 1.8]:
			var foot := Vector3(x, 0.14, z)
			var head := Vector3(x * 0.88, 5.69, z)
			_box(foot - Vector3.UP * 0.04, Vector3(0.66, 0.20, 0.63), STONE, Vector3.ZERO, true)
			_beam(foot, head, 0.34, TIMBER, true)
			_box(head - Vector3.UP * 0.20, Vector3(0.37, 0.14, 0.39), IRON)
		_beam(Vector3(-2.05, 5.77, z), Vector3(2.05, 5.77, z), 0.34, END_GRAIN)
		_beam(Vector3(-1.73, 1.3, z), Vector3(1.60, 5.48, z), 0.22, TIMBER)
		_beam(Vector3(1.73, 1.3, z + 0.13), Vector3(-1.60, 5.48, z + 0.13), 0.20, TIMBER)
	for x in [-1.57, 1.57]:
		_beam(Vector3(x, 5.6, -3.16), Vector3(x, 5.6, 3.16), 0.25, TIMBER)
		_beam(Vector3(x, 1.7, -2.8), Vector3(x, 5.46, 2.8), 0.21, END_GRAIN)

	# The same fault crosses the deck and continues up the two inner walls.
	var fault := PackedVector3Array([
		Vector3(-1.42, 6.353, -0.25), Vector3(-1.01, 6.353, -0.18),
		Vector3(-0.62, 6.354, 0.06), Vector3(-0.20, 6.354, -0.02),
		Vector3(0.12, 6.353, 0.24), Vector3(0.55, 6.353, 0.08),
		Vector3(0.89, 6.354, 0.20), Vector3(1.42, 6.353, 0.09),
	])
	_crack(fault, Vector3.FORWARD)
	_crack(PackedVector3Array([
		Vector3(-1.362, 6.36, -0.25), Vector3(-1.362, 7.02, -0.35),
		Vector3(-1.362, 7.46, -0.14), Vector3(-1.362, 8.08, -0.43),
		Vector3(-1.362, 8.87, -0.56), Vector3(-1.362, 9.47, -0.63),
	]), Vector3.FORWARD)
	_crack(PackedVector3Array([
		Vector3(1.362, 6.36, 0.09), Vector3(1.362, 6.90, -0.02),
		Vector3(1.362, 7.38, 0.24), Vector3(1.362, 8.29, 0.46),
	]), Vector3.FORWARD)

func _add_collapse() -> void:
	for z in [-2.85, 2.85]:
		for x in [-1.8, 1.8]:
			var foot := Vector3(x, 0.13, z)
			var length := 0.75 if x * z > 0.0 else 1.42
			var tip := Vector3(x * 0.93, length, z + 0.08)
			_box(foot - Vector3.UP * 0.06, Vector3(0.66, 0.20, 0.63), STONE)
			_beam(foot, tip, 0.34, CHARCOAL)
			_beam(tip - Vector3.UP * 0.05, tip + Vector3(-0.07, 0.19, 0.04), 0.20, CHARCOAL.darkened(0.22))
		_beam(Vector3(-1.45, 0.23, z), Vector3(1.5, 0.39, z - 0.85), 0.26, CHARCOAL)
	_beam(Vector3(-2.0, 0.31, -3.0), Vector3(-0.17, 0.62, 0.45), 0.28, CHARCOAL)
	_beam(Vector3(1.0, 0.32, 2.9), Vector3(0.14, 0.5, -0.9), 0.30, CHARCOAL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 749
	for i in 18:
		var center := Vector3(rng.randf_range(-1.9, 1.9), rng.randf_range(0.19, 0.56),
			rng.randf_range(-2.4, 2.5))
		var size := Vector3(rng.randf_range(0.35, 1.16), rng.randf_range(0.28, 0.61),
			rng.randf_range(0.45, 1.24))
		var tilt := Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))
		_box(center, size, STONE.darkened(rng.randf_range(0.0, 0.28)), tilt, true)
	_box(Vector3(-0.1, 0.37, -0.8), Vector3(2.8, 0.48, 0.86), STONE, Vector3(0.21, -0.43, 0.11), true)

func _add_timber_shed() -> void:
	var origin := Vector3(5.6, 0, 6.8)
	for x in [-1.43, 1.43]:
		for z in [-1.8, 1.8]:
			var foot := origin + Vector3(x, 0.05, z)
			var height: float = 2.08 + x * 0.22
			var post_color := TIMBER
			if burned:
				height = 0.26 + 0.38 * absf(sin(z + x))
				post_color = CHARCOAL
			_beam(foot, foot + Vector3.UP * height, 0.18, post_color, not burned)
	if burned:
		for i in 7:
			var start := origin + Vector3(-1.55 + i * 0.18, 0.13 + i * 0.04, -1.8 + 0.19 * i)
			_beam(start, start + Vector3(1.25 + sin(i), 0.13, 1.1 - 0.12 * i), 0.16, CHARCOAL)
		return
	for i in 10:
		var x := -1.56 + 0.35 * i
		_box(origin + Vector3(x, 2.14 + x * 0.22, 0), Vector3(0.37, 0.13, 4.09),
			TIMBER.lightened(0.075 + 0.05 * sin(i * 1.73)), Vector3(0, 0, 0.216))
	for z in [-1.68, 1.68]:
		_beam(origin + Vector3(-1.62, 1.77, z), origin + Vector3(1.62, 2.47, z), 0.16, END_GRAIN)
	for row in 4:
		for i in 5 - row:
			_box(origin + Vector3(-0.56 + 0.22 * i, 0.18 + 0.14 * row, 0.15 + 0.07 * sin(i + row)),
				Vector3(0.21, 0.124, 3.14 - 0.17 * sin(i + row)), END_GRAIN.darkened(0.12 * (i % 3)))

func _crack(path: PackedVector3Array, side: Vector3) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		var w_a := side * (0.018 + 0.016 * sin(i * 2.4))
		var w_b := side * (0.018 + 0.016 * sin((i + 1) * 2.4))
		for point in [a - w_a, b - w_b, a + w_a, b - w_b, b + w_b, a + w_a]:
			tool.add_vertex(point)
	tool.generate_normals()
	var mat := _material(Color(0.10, 0.085, 0.075))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var line := MeshInstance3D.new()
	line.mesh = tool.commit()
	line.material_override = mat
	add_child(line)

func _beam(a: Vector3, b: Vector3, width: float, color: Color, solid := false) -> void:
	var direction := (b - a).normalized()
	var axis := Vector3.BACK if absf(direction.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT
	var cross := direction.cross(axis).normalized()
	var frame := Basis(cross, direction, cross.cross(direction))
	_box((a + b) * 0.5, Vector3(width, a.distance_to(b), width), color, frame.get_euler(), solid)

func _box(at: Vector3, size: Vector3, color: Color, tilt := Vector3.ZERO, solid := false) -> void:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.position = at
	body.rotation = tilt
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	var model := MeshInstance3D.new()
	model.mesh = mesh
	body.add_child(model)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	add_child(body)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.96
	return mat
