@tool
extends StaticBody3D

const MASONRY := preload("res://scenes/world/castle/masonry.gdshader")

@export var opening_width := 2.76
@export var opening_height := 2.84
@export var wall_depth := 1.0
@export var open_crest := false

func _ready() -> void:
	var profile := _crest_profile() if open_crest else _tower_profile()
	var masonry := ShaderMaterial.new()
	masonry.shader = MASONRY
	var exposed_stone := StandardMaterial3D.new()
	exposed_stone.albedo_color = Color(0.35, 0.36, 0.35)
	exposed_stone.roughness = 0.96

	var face := _surface(masonry)
	var edge := _surface(exposed_stone)
	var half_depth := wall_depth * 0.5
	var triangles := Geometry2D.triangulate_polygon(profile)
	for i in range(0, triangles.size(), 3):
		for index in [2, 1, 0]:
			_vertex(face, profile[triangles[i + index]], half_depth)
		for index in [0, 1, 2]:
			_vertex(face, profile[triangles[i + index]], -half_depth)
	for i in profile.size():
		var a := profile[i]
		var b := profile[(i + 1) % profile.size()]
		for point in [Vector3(a.x, a.y, half_depth), Vector3(b.x, b.y, half_depth),
				Vector3(b.x, b.y, -half_depth), Vector3(a.x, a.y, half_depth),
				Vector3(b.x, b.y, -half_depth), Vector3(a.x, a.y, -half_depth)]:
			edge.add_vertex(point)
	face.generate_normals()
	edge.generate_normals()
	var mesh := face.commit()
	edge.commit(mesh)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)
	var collider := CollisionShape3D.new()
	var shell := mesh.create_trimesh_shape()
	shell.backface_collision = true
	collider.shape = shell
	add_child(collider)
	if open_crest:
		var face_z := half_depth - 0.35
		_crest_fragment(Vector3(-1.79, 2.27, face_z), Vector3(0.45, 0.73, 0.63),
			Vector3(0.19, -0.20, -0.30), masonry)
		_crest_fragment(Vector3(1.77, 2.17, face_z + 0.16), Vector3(0.51, 0.53, 0.62),
			Vector3(-0.24, 0.27, 0.30), masonry)
		_crest_fragment(Vector3(1.06, 1.52, face_z + 0.33), Vector3(0.54, 0.33, 0.47),
			Vector3(0.32, -0.30, -0.27), exposed_stone)

func _tower_profile() -> PackedVector2Array:
	var profile := PackedVector2Array([
		Vector2(-1.38, 0), Vector2(-0.99, 0), Vector2(-1.08, 0.37),
		Vector2(-0.98, 0.74), Vector2(-1.14, 1.21), Vector2(-1.04, 1.65),
		Vector2(-1.16, 2.20), Vector2(-0.88, 2.55), Vector2(-0.43, 2.67),
		Vector2(-0.12, 2.48), Vector2(0.26, 2.54), Vector2(0.53, 2.43),
		Vector2(0.83, 2.60), Vector2(1.10, 2.14), Vector2(0.99, 1.73),
		Vector2(1.12, 1.32), Vector2(1.00, 0.78), Vector2(1.15, 0.44),
		Vector2(1.04, 0), Vector2(1.38, 0), Vector2(1.38, 2.84),
		Vector2(-1.38, 2.84),
	])
	for i in profile.size():
		profile[i] *= Vector2(opening_width / 2.76, opening_height / 2.84)
	return profile

func _crest_profile() -> PackedVector2Array:
	var profile := PackedVector2Array([
		Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(0.5, 1),
		Vector2(0.43, 0.91), Vector2(0.39, 0.74), Vector2(0.30, 0.76),
		Vector2(0.22, 0.44), Vector2(0.12, 0.38), Vector2(0.03, 0.20),
		Vector2(-0.10, 0.32), Vector2(-0.17, 0.52), Vector2(-0.26, 0.44),
		Vector2(-0.32, 0.67), Vector2(-0.41, 0.70), Vector2(-0.43, 0.92),
		Vector2(-0.5, 1),
	])
	for i in profile.size():
		profile[i] *= Vector2(opening_width, opening_height)
	return profile

func _crest_fragment(at: Vector3, size: Vector3, tilt: Vector3, material: Material) -> void:
	var stone := BoxMesh.new()
	stone.size = size
	stone.material = material
	var block := MeshInstance3D.new()
	block.mesh = stone
	block.position = at
	block.rotation = tilt
	add_child(block)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = block.transform
	add_child(collision)

func _surface(material: Material) -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	surface.set_material(material)
	return surface

func _vertex(surface: SurfaceTool, point: Vector2, depth: float) -> void:
	surface.add_vertex(Vector3(point.x, point.y, depth))
