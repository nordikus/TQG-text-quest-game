@tool
extends StaticBody3D

const MASONRY := preload("res://scenes/world/castle/masonry.gdshader")

@export var opening_width := 2.76

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var fracture := SurfaceTool.new()
	fracture.begin(Mesh.PRIMITIVE_TRIANGLES)
	fracture.set_smooth_group(-1)
	# Profiles are in the plane of the original wall, measured along Z and Y.
	var profile := PackedVector2Array([
		Vector2(-1.38, 20.13), Vector2(-0.92, 20.13), Vector2(-1.04, 20.50),
		Vector2(-0.93, 20.87), Vector2(-1.12, 21.34), Vector2(-0.99, 21.78),
		Vector2(-1.12, 22.33), Vector2(-0.88, 22.68), Vector2(-0.43, 22.80),
		Vector2(-0.12, 22.61), Vector2(0.26, 22.67), Vector2(0.53, 22.56),
		Vector2(0.83, 22.73), Vector2(1.01, 22.27), Vector2(0.89, 21.86),
		Vector2(1.05, 21.45), Vector2(0.94, 20.91), Vector2(1.11, 20.57),
		Vector2(1.01, 20.13), Vector2(1.38, 20.13), Vector2(1.38, 22.97),
		Vector2(-1.38, 22.97),
	])
	for index in profile.size():
		profile[index].x *= opening_width / 2.76
	_build_edge(surface, fracture, profile)
	surface.generate_normals()
	fracture.generate_normals()
	var mesh := surface.commit()
	fracture.commit(mesh)
	var material := ShaderMaterial.new()
	material.shader = MASONRY
	mesh.surface_set_material(0, material)
	var exposed_stone := StandardMaterial3D.new()
	exposed_stone.albedo_color = Color(0.44, 0.43, 0.39)
	exposed_stone.roughness = 0.96
	exposed_stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(1, exposed_stone)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)
	var collider := CollisionShape3D.new()
	var shell := mesh.create_trimesh_shape()
	shell.backface_collision = true
	collider.shape = shell
	add_child(collider)

func _build_edge(surface: SurfaceTool, fracture: SurfaceTool, profile: PackedVector2Array) -> void:
	var indices := Geometry2D.triangulate_polygon(profile)
	for i in range(0, indices.size(), 3):
		for offset in [0, 1, 2]:
			_vertex(surface, profile[indices[i + offset]], -4.807)
		for offset in [2, 1, 0]:
			_vertex(surface, profile[indices[i + offset]], -3.795)
	var reverse := Geometry2D.is_polygon_clockwise(profile)
	for i in profile.size():
		var a := profile[i]
		var b := profile[(i + 1) % profile.size()]
		if reverse:
			var swap := a
			a = b
			b = swap
		for point in [Vector3(-4.807, a.y, a.x), Vector3(-3.795, a.y, a.x), Vector3(-4.807, b.y, b.x),
				Vector3(-4.807, b.y, b.x), Vector3(-3.795, a.y, a.x), Vector3(-3.795, b.y, b.x)]:
			fracture.add_vertex(point)

func _vertex(surface: SurfaceTool, point: Vector2, depth: float) -> void:
	surface.add_vertex(Vector3(depth, point.y, point.x))
