@tool
extends Node3D

const SIDES := 12

func _ready() -> void:
	var wall := ShaderMaterial.new()
	wall.shader = preload("res://scenes/world/castle/masonry.gdshader")
	var cap := _material(Color(0.37, 0.39, 0.35))
	var oak := _material(Color(0.33, 0.21, 0.12))
	var iron := _material(Color(0.16, 0.17, 0.17))
	_stone_ring(-0.60, 0.38, 1.36, 1.23, 0.92, wall)
	_stone_ring(0.37, 0.58, 1.27, 1.28, 0.86, cap)
	_tube(Vector3(0, -0.44, 0), 0.90, 0.89, 0.08, _material(Color(0.071, 0.055, 0.038)))

	_tube(Vector3(0, 1.35, 0), 0.073, 0.073, 2.07, iron, Vector3(0, 0, PI / 2.0))
	_tube(Vector3(0.06, 1.35, 0), 0.154, 0.154, 0.49, oak, Vector3(0, 0, PI / 2.0))
	for x in [-0.18, 0.30]:
		_tube(Vector3(x, 1.35, 0), 0.17, 0.17, 0.042, iron, Vector3(0, 0, PI / 2.0))
	for x in [-0.98, 0.98]:
		_tube(Vector3(x, 1.35, 0), 0.133, 0.133, 0.068, iron, Vector3(0, 0, PI / 2.0))
	_tube(Vector3(1.085, 1.45, 0), 0.044, 0.044, 0.24, iron)
	_tube(Vector3(1.18, 1.56, 0), 0.052, 0.052, 0.19, oak, Vector3(0, 0, PI / 2.0))
	_tube(Vector3(0.06, 0.77, 0.10), 0.016, 0.016, 1.15, _material(Color(0.49, 0.39, 0.26)))
	_tube(Vector3(0.06, 0.18, 0.10), 0.19, 0.137, 0.31, oak)
	_tube(Vector3(0.06, 0.30, 0.10), 0.195, 0.195, 0.037, iron)
	_tube(Vector3(0.06, 0.039, 0.10), 0.152, 0.152, 0.035, iron)

func _stone_ring(low: float, high: float, base_radius: float, lip_radius: float, inside: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in SIDES:
		var a := _radial(i)
		var b := _radial(i + 1)
		var low_out_a := a * base_radius + Vector3.UP * low
		var low_out_b := b * base_radius + Vector3.UP * low
		var hi_out_a := a * lip_radius + Vector3.UP * high
		var hi_out_b := b * lip_radius + Vector3.UP * high
		var low_in_a := a * inside + Vector3.UP * low
		var low_in_b := b * inside + Vector3.UP * low
		var hi_in_a := a * inside + Vector3.UP * high
		var hi_in_b := b * inside + Vector3.UP * high
		_quad(surface, low_out_a, low_out_b, hi_out_b, hi_out_a)
		_quad(surface, low_in_b, low_in_a, hi_in_a, hi_in_b)
		_quad(surface, hi_in_a, hi_out_a, hi_out_b, hi_in_b)
	surface.generate_normals()
	surface.set_material(material)
	_visual(surface.commit(), Vector3.ZERO, Vector3.ZERO)

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, b, c, a, c, d]:
		surface.add_vertex(point)

func _radial(i: int) -> Vector3:
	var angle := TAU * i / SIDES
	return Vector3(cos(angle), 0, sin(angle))

func _tube(at: Vector3, top: float, bottom: float, height: float, mat: Material, tilt := Vector3.ZERO) -> void:
	var tube := CylinderMesh.new()
	tube.top_radius = top
	tube.bottom_radius = bottom
	tube.height = height
	tube.radial_segments = SIDES
	tube.rings = 0
	tube.material = mat
	_visual(tube, at, tilt)

func _visual(mesh: Mesh, at: Vector3, tilt: Vector3) -> void:
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.position = at
	model.rotation = tilt
	add_child(model)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	return material
