@tool
extends MeshInstance3D

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_inlay(surface, 2.91, 0.355, 34)
	_inlay(surface, 2.09, 0.705, 25)
	surface.generate_normals()
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.33, 0.70, 0.62)
	bronze.emission_enabled = true
	bronze.emission = Color(0.08, 0.61, 0.51)
	bronze.emission_energy_multiplier = 0.70
	bronze.roughness = 0.69
	surface.set_material(bronze)
	mesh = surface.commit()

func _inlay(surface: SurfaceTool, radius: float, height: float, segments: int) -> void:
	var delta := TAU / segments
	for i in segments:
		var angle := i * delta
		# Leave the stone steps bare where they cross each ring.
		if absf(angle_difference(angle, PI / 2.0)) < 0.29:
			continue
		var left := angle - delta * 0.434
		var right := angle + delta * 0.434
		_strip(surface, radius, height, left, right, 0.038)
		if i % 3 != 1:
			continue
		var left_arm := _point(radius - 0.106, height, angle - delta * 0.20)
		var notch := _point(radius - 0.18, height, angle)
		var right_arm := _point(radius - 0.106, height, angle + delta * 0.20)
		_stamp(surface, left_arm, notch, right_arm, 0.034)

func _strip(surface: SurfaceTool, radius: float, height: float, start: float, finish: float, width: float) -> void:
	var a := _point(radius - width * 0.5, height, start)
	var b := _point(radius + width * 0.5, height, start)
	var c := _point(radius + width * 0.5, height, finish)
	var d := _point(radius - width * 0.5, height, finish)
	for point in [a, b, c, a, c, d]:
		surface.add_vertex(point)

func _stamp(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, width: float) -> void:
	var middle := (a + c) * 0.5
	var center := b.move_toward(middle, width)
	for point in [a, center, b, b, center, c]:
		surface.add_vertex(point)

func _point(radius: float, height: float, angle: float) -> Vector3:
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)
