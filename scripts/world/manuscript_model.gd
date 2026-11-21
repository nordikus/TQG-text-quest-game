@tool
extends Node3D

@export var feather := false

func _ready() -> void:
	if feather:
		_quill()
	else:
		_book()

func _book() -> void:
	var leather := _material(Color(0.34, 0.13, 0.105))
	var paper := _material(Color(0.82, 0.72, 0.49))
	var edges := _material(Color(0.65, 0.51, 0.31))
	var script_ink := _material(Color(0.245, 0.173, 0.11))
	var rubric := _material(Color(0.42, 0.16, 0.14))
	var bronze := _material(Color(0.66, 0.46, 0.19), 0.62)
	_box(Vector3(0, 0.021, 0), Vector3(0.038, 0.052, 0.428), leather)
	for side: float in [-1.0, 1.0]:
		var tilt := Vector3(0, 0, side * 0.15)
		var page := Transform3D(Basis.from_euler(tilt), Vector3(side * 0.123, 0.030, 0))
		_box(page * Vector3(0, -0.029, 0), Vector3(0.247, 0.028, 0.427), leather, tilt)
		_box(page.origin, Vector3(0.225, 0.049, 0.388), edges, tilt)
		_box(page * Vector3(0, 0.026, 0), Vector3(0.220, 0.010, 0.379), paper, tilt)
		_box(page * Vector3(-0.029, 0.032, -0.123), Vector3(0.112, 0.0015, 0.01), rubric, tilt)
		for row in 6:
			var width := 0.148 + 0.032 * sin(row * 2.31 + side)
			_box(page * Vector3(-0.084 + width * 0.5, 0.032, -0.086 + row * 0.040),
				Vector3(width, 0.0016, 0.0055), script_ink, tilt)
		for end: float in [-1.0, 1.0]:
			_box(page * Vector3(0.108 * side, -0.027, 0.189 * end), Vector3(0.052, 0.034, 0.052), bronze, tilt)
	_box(Vector3(0.018, 0.044, 0.19), Vector3(0.025, 0.008, 0.104), rubric, Vector3(-0.21, -0.13, 0))

func _quill() -> void:
	var shaft := _material(Color(0.78, 0.54, 0.29), 0.46)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in 8:
		var low := -0.178 + i * 0.058
		var upper := low + 0.058
		var width := (0.024 + 0.079 * sin(float(i + 1) / 9.0 * PI))
		var sweep := 0.12 * (upper + 0.19)
		var rib := Vector3(sweep, upper, 0)
		var base := Vector3(0.12 * (low + 0.19), low, 0)
		for side: float in [-1.0, 1.0]:
			var edge := rib + Vector3(side * width, 0.018, 0.018 * side)
			var corner := rib + Vector3(side * width * 0.95, 0.047, 0.022 * side)
			var crest := rib + Vector3(0.006, 0.054, 0)
			surface.set_color(Color(0.69, 0.36, 0.90).lerp(Color(0.91, 0.72, 1.0), (i + 1.0) / 10.0))
			for point in [base, edge, rib, rib, edge, corner, rib, corner, crest]:
				surface.add_vertex(point)
	surface.generate_normals()
	var plume := _material(Color.WHITE, 0.25)
	plume.vertex_color_use_as_albedo = true
	plume.vertex_color_is_srgb = true
	plume.cull_mode = BaseMaterial3D.CULL_DISABLED
	plume.emission_enabled = true
	plume.emission = Color(0.48, 0.17, 0.63)
	plume.emission_energy_multiplier = 0.59
	surface.set_material(plume)
	var model := MeshInstance3D.new()
	model.mesh = surface.commit()
	add_child(model)
	_box(Vector3(0.018, 0.006, 0.001), Vector3(0.019, 0.590, 0.017), shaft, Vector3(0, 0, -0.116))

func _material(color: Color, metalness := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalness
	material.roughness = 0.85
	return material

func _box(at: Vector3, size: Vector3, material: Material, rotation := Vector3.ZERO) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	var piece := MeshInstance3D.new()
	piece.mesh = box
	piece.position = at
	piece.rotation = rotation
	add_child(piece)
