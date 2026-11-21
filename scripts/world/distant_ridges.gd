@tool
extends Node3D

const SPANS := 23
const DEPTHS: Array[float] = [-1.0, -0.66, -0.35, -0.12, 0.12, 0.41, 0.67, 1.0]

func _ready() -> void:
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = 1.0
	_ridge(Vector3(-14, 0, -307), 315.0, 61.0, 92.0, 0.04, 235, stone)
	_ridge(Vector3(-167, 0, -269), 204.0, 56.0, 76.0, 0.36, 781, stone)
	_ridge(Vector3(176, 0, -271), 190.0, 66.0, 72.0, -0.33, 623, stone)
	_ridge(Vector3(-286, 0, -58), 252.0, 71.0, 80.0, 1.40, 553, stone)
	_ridge(Vector3(282, 0, -23), 230.0, 58.0, 73.0, -1.53, 903, stone)
	_ridge(Vector3(189, 0, 245), 209.0, 56.0, 64.0, 0.29, 419, stone)
	_ridge(Vector3(-170, 0, 268), 225.0, 63.0, 77.0, -0.27, 687, stone)

func _ridge(at: Vector3, width: float, depth: float, height: float, yaw: float, seed_value: int, mat: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var crest := PackedFloat32Array()
	for col in SPANS + 1:
		var u := float(col) / SPANS
		var silhouette := 0.46 + 0.17 * cos(u * 14.0) + 0.18 * sin(u * 30.0 + seed_value)
		silhouette += rng.randf_range(-0.09, 0.13)
		crest.append(height * (0.15 + maxf(0.0, sin(PI * u)) * silhouette))

	var points := PackedVector3Array()
	for row in DEPTHS.size():
		var ridge_depth := DEPTHS[row]
		for col in SPANS + 1:
			var u := float(col) / SPANS
			var cross_section := pow(1.0 - absf(ridge_depth), 1.28)
			var distance_from_edge := minf(1.0, minf(u, 1.0 - u) * 7.0)
			var slope := lerpf(-15.0, crest[col], cross_section * distance_from_edge)
			slope += sin(u * 38.0 + row * 0.70) * 5.4 * cross_section * distance_from_edge
			points.append(Vector3((u - 0.5) * width + sin(row * 1.15 + col) * 3.0,
				slope, ridge_depth * depth + sin(u * 14.5 + row * 0.24) * (4.0 + cross_section * 9.0)))

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	surface.set_material(mat)
	for row in DEPTHS.size() - 1:
		for col in SPANS:
			var i := row * (SPANS + 1) + col
			_face(surface, points[i], points[i + 1], points[i + SPANS + 1], rng)
			_face(surface, points[i + 1], points[i + SPANS + 2], points[i + SPANS + 1], rng)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.position = at
	instance.rotation.y = yaw
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func _face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, rng: RandomNumberGenerator) -> void:
	var elevation := (a.y + b.y + c.y) / 3.0
	var color := Color(0.056, 0.091, 0.106).lerp(Color(0.134, 0.197, 0.238), smoothstep(4.0, 48.0, elevation))
	surface.set_color(color * rng.randf_range(0.91, 1.08))
	for point in [a, b, c]:
		surface.add_vertex(point)
