@tool
extends StaticBody3D

const SIDES := 8

func _ready() -> void:
	var shape := PackedVector3Array()
	var yaw := sin(position.x * 0.827 + position.z * 0.41) * 0.55
	var stone_turn := Basis(Vector3.UP, yaw)
	for ring in 3:
		for i in SIDES:
			var angle := TAU * i / SIDES
			var p := Vector3(cos(angle), 0.0, sin(angle))
			var irregular := sin(i * 2.71 + yaw * 4.0) + cos(i * 3.1 - ring)
			var radius: float = [0.62, 0.97, 0.45][ring] + irregular * 0.058
			var height: float = [-0.045, 0.53, 1.15][ring] + irregular * (0.020 + ring * 0.038)
			shape.append(stone_turn * (p * radius * Vector3(0.97, 1.0, 1.13) + Vector3(0.092 * ring, height, -0.061 * ring)))
	shape.append(stone_turn * Vector3(0.12, 1.21 + 0.14 * yaw, -0.18))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in SIDES:
		var j := (i + 1) % SIDES
		for ring in 2:
			var a := ring * SIDES + i
			var b := ring * SIDES + j
			var hue := Color(0.25, 0.27, 0.23).lerp(Color(0.43, 0.46, 0.42), 0.60 + 0.28 * sin(i * 2.40 + ring))
			if ring == 0:
				hue = hue.lerp(Color(0.25, 0.34, 0.18), 0.12 + 0.28 * absf(sin(i * 0.91 + yaw)))
			_face(surface, [shape[a], shape[b], shape[b + SIDES]], hue)
			_face(surface, [shape[a], shape[b + SIDES], shape[a + SIDES]], hue.lightened(0.038))
		_face(surface, [shape[2 * SIDES + i], shape[2 * SIDES + j], shape[-1]], Color(0.42, 0.454, 0.40).lightened(0.063 * cos(i)))
	surface.generate_normals()
	var weathered := StandardMaterial3D.new()
	weathered.vertex_color_use_as_albedo = true
	weathered.vertex_color_is_srgb = true
	weathered.roughness = 1.0
	surface.set_material(weathered)
	$MeshInstance3D.mesh = surface.commit()
	var collider := ConvexPolygonShape3D.new()
	collider.points = shape
	$CollisionShape3D.shape = collider

func _face(surface: SurfaceTool, points: Array, color: Color) -> void:
	surface.set_color(color)
	for point in points:
		surface.add_vertex(point)
