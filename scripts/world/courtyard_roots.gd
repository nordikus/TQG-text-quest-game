@tool
extends Node3D

# Root profiles run along the west face of the barracks. Profile X is the
# along-wall offset from the door, Y is height and Z is depth into the wall.
const DOOR_CENTER := Vector3(16.05, 0, -22.6)
const ROOTS := [
	[0.57, 0.18, [Vector3(-3.20, -0.36, 0.06), Vector3(-2.28, 0.42, -0.26), Vector3(-1.35, 1.38, -0.38), Vector3(-0.72, 2.75, -0.43), Vector3(0.32, 3.53, -0.32), Vector3(1.95, 4.78, 0.12), Vector3(3.55, 5.31, 0.16)]],
	[0.62, 0.16, [Vector3(2.85, -0.30, 0.14), Vector3(1.8, 0.53, -0.31), Vector3(0.75, 1.4, -0.54), Vector3(0.18, 2.74, -0.26), Vector3(-0.7, 3.62, -0.4), Vector3(-2.2, 4.27, -0.12), Vector3(-4.55, 4.13, 0.14)]],
	[0.57, 0.16, [Vector3(-1.41, -0.30, -0.1), Vector3(-0.82, 0.62, -0.31), Vector3(0.03, 1.07, -0.26), Vector3(0.98, 2.08, -0.39), Vector3(1.29, 3.38, -0.18), Vector3(2.6, 4.18, 0.1), Vector3(4.9, 4.09, 0.14)]],
	[0.52, 0.18, [Vector3(0.48, -0.29, -0.43), Vector3(0.18, 0.52, -0.42), Vector3(-0.4, 1.43, -0.23), Vector3(-0.44, 2.57, -0.21), Vector3(-0.87, 3.7, -0.36), Vector3(-1.55, 4.76, 0.02), Vector3(-2.9, 5.49, 0.15)]],
	[0.43, 0.15, [Vector3(-2.5, -0.26, 0.13), Vector3(-1.62, 0.45, -0.19), Vector3(-1.22, 1.64, -0.57), Vector3(-0.22, 1.95, -0.63), Vector3(0.83, 2.47, -0.63), Vector3(2.37, 2.76, -0.14), Vector3(4.1, 2.35, 0.12)]],
	[0.46, 0.2, [Vector3(1.4, -0.38, -0.1), Vector3(1.23, 0.59, -0.21), Vector3(1.04, 1.59, -0.2), Vector3(1.33, 2.65, -0.28), Vector3(0.72, 3.67, -0.38), Vector3(-0.58, 4.09, 0.02)]],
	[0.32, 0.08, [Vector3(-1.09, 1.67, -0.38), Vector3(-2.17, 2.2, -0.08), Vector3(-3.55, 2.1, -0.07), Vector3(-4.65, 2.66, 0.02), Vector3(-6.25, 2.92, 0.14)]],
	[0.28, 0.08, [Vector3(1.7, 0.48, -0.33), Vector3(2.9, 1.02, 0.01), Vector3(4.42, 0.78, -0.04), Vector3(5.63, 1.24, 0.15)]],
	[0.23, 0.07, [Vector3(2.35, 2.8, -0.03), Vector3(3.43, 3.23, -0.06), Vector3(4.19, 3.15, 0.03), Vector3(5.45, 3.64, 0.11)]],
	[0.22, 0.06, [Vector3(-2.27, 4.28, 0.01), Vector3(-3.19, 4.9, -0.05), Vector3(-4.28, 4.78, 0.02), Vector3(-5.7, 5.14, 0.10)]],
]

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for root: Array in ROOTS:
		var profile: Array = root[2]
		var path := _wall_path(profile)
		_branch(surface, path, root[0], root[1])
	surface.generate_normals()
	var mesh := surface.commit()
	var bark := StandardMaterial3D.new()
	bark.vertex_color_use_as_albedo = true
	bark.vertex_color_is_srgb = true
	bark.roughness = 0.95
	var body := StaticBody3D.new()
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.material_override = bark
	body.add_child(model)
	var collision := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	# Overlapping roots fill the frame. Seal capsule-sized gaps between stems.
	var opening := BoxShape3D.new()
	opening.size = Vector3(0.22, 3.61, 2.8)
	var filler := CollisionShape3D.new()
	filler.position = DOOR_CENTER + Vector3(0.12, 2.025, 0)
	filler.shape = opening
	body.add_child(filler)
	add_child(body)

func _wall_path(profile: Array) -> PackedVector3Array:
	var controls := PackedVector3Array()
	for i in profile.size():
		var point: Vector3 = profile[i]
		if i > 0 and i < profile.size() - 1:
			point.z = minf(point.z, -0.12)
		controls.append(DOOR_CENTER + Vector3(point.z, point.y, point.x))
	var path := PackedVector3Array()
	for i in range(controls.size() - 1):
		var a := controls[i]
		var b := controls[i + 1]
		var before := controls[maxi(i - 1, 0)]
		var after := controls[mini(i + 2, controls.size() - 1)]
		for step in 3:
			path.append(a.cubic_interpolate(b, before, after, step / 3.0))
	path.append(controls[-1])
	return path

func _branch(surface: SurfaceTool, path: PackedVector3Array, base: float, tip: float) -> void:
	const SIDES := 8
	var rings: Array[PackedVector3Array] = []
	for i in path.size():
		var p: Vector3 = path[i]
		var tangent: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(0, i - 1)]).normalized()
		var side := tangent.cross(Vector3.RIGHT).normalized()
		var up := side.cross(tangent)
		var radius := lerpf(base, tip, float(i) / (path.size() - 1))
		var ring := PackedVector3Array()
		for j in SIDES:
			var angle := TAU * j / SIDES
			var ridge := 1.0 + 0.09 * sin(i * 0.58 + j * 2.7)
			ring.append(p + (up * cos(angle) + side * sin(angle)) * radius * ridge)
		rings.append(ring)
	for i in range(rings.size() - 1):
		for j in SIDES:
			var next := (j + 1) % SIDES
			var moss := maxf(0.0, cos(TAU * (j + 0.5) / SIDES)) * (0.34 + 0.30 * sin(i * 0.38 + j))
			var shade := Color(0.40, 0.24, 0.13).lerp(Color(0.38, 0.48, 0.22), moss)
			for point: Vector3 in [
				rings[i][j], rings[i + 1][j], rings[i][next],
				rings[i + 1][j], rings[i + 1][next], rings[i][next],
			]:
				surface.set_color(shade)
				surface.add_vertex(point)
