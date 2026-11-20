@tool
extends Node3D

const EAVE := 24.12
const RADIUS := 5.12
const START_ANGLE := PI / 4.0
const ROOF_ARC := 3.0 * PI / 2.0
const SEGMENTS := 18

func _ready() -> void:
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	roof.set_smooth_group(-1)
	var peak := Vector3(0, EAVE + 4.9, 0)
	for index in SEGMENTS:
		var a := _eave_point(index)
		var b := _eave_point(index + 1)
		roof.set_color(Color(0.19, 0.24, 0.33).lightened(0.055 * sin(index * 2.0)))
		for point in [a, b, peak]:
			roof.add_vertex(point)
	roof.generate_normals()
	var tiles := StandardMaterial3D.new()
	tiles.vertex_color_use_as_albedo = true
	tiles.vertex_color_is_srgb = true
	tiles.cull_mode = BaseMaterial3D.CULL_DISABLED
	tiles.roughness = 0.89
	var roof_mesh := roof.commit()
	roof_mesh.surface_set_material(0, tiles)
	var model := MeshInstance3D.new()
	model.mesh = roof_mesh
	var structure := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shell := roof_mesh.create_trimesh_shape()
	shell.backface_collision = true
	collision.shape = shell
	structure.add_child(model)
	structure.add_child(collision)
	add_child(structure)

	var oak := _material(Color(0.23, 0.145, 0.092))
	for i in [0, 3, 6, 9, 12, 15, SEGMENTS]:
		_beam(_eave_point(i) + Vector3.DOWN * 0.075, peak, 0.18, oak)
	for i in SEGMENTS:
		_beam(_eave_point(i), _eave_point(i + 1), 0.19, oak)
	for z in [-3.2, 3.2]:
		_beam(Vector3(3.2, EAVE - 0.14, z), Vector3(3.45, EAVE + 0.44, z), 0.20, oak)
	_add_spyglass(oak)

func _eave_point(index: int) -> Vector3:
	var angle := START_ANGLE + ROOF_ARC * index / SEGMENTS
	return Vector3(cos(angle) * RADIUS, EAVE, sin(angle) * RADIUS)

func _add_spyglass(oak: Material) -> void:
	var bronze := _material(Color(0.53, 0.345, 0.16), 0.65)
	var dark_brass := _material(Color(0.31, 0.235, 0.14), 0.52)
	var lens := _material(Color(0.15, 0.39, 0.47), 0.28)
	var mount := Vector3(2.97, 21.39, 1.62)
	for offset in [Vector3(-0.3, 0, -0.18), Vector3(0.25, 0, -0.23), Vector3(0.02, 0, 0.31)]:
		_beam(Vector3(mount.x, 20.16, mount.z) + offset, mount, 0.105, oak)
	var axis := Vector3(0.32, 0.93, -0.15).normalized()
	_tube(mount + axis * 0.10, axis, 0.14, 1.56, bronze)
	_tube(mount + axis * 0.79, axis, 0.175, 0.23, dark_brass)
	_tube(mount + axis * 0.913, axis, 0.132, 0.02, lens)
	_tube(mount - axis * 0.68, axis, 0.098, 0.27, dark_brass)

func _tube(center: Vector3, axis: Vector3, radius: float, height: float, material: Material) -> void:
	var tube := CylinderMesh.new()
	tube.top_radius = radius
	tube.bottom_radius = radius
	tube.height = height
	tube.radial_segments = 12
	tube.rings = 0
	_part(center, axis, tube, material)

func _beam(a: Vector3, b: Vector3, width: float, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, a.distance_to(b), width)
	_part((a + b) * 0.5, (b - a).normalized(), mesh, material)

func _part(center: Vector3, axis: Vector3, mesh: PrimitiveMesh, material: Material) -> void:
	var part := MeshInstance3D.new()
	var tangent := axis.cross(Vector3.BACK).normalized()
	if tangent.length_squared() < 0.001:
		tangent = axis.cross(Vector3.RIGHT).normalized()
	part.transform = Transform3D(Basis(tangent, axis, tangent.cross(axis)), center)
	mesh.material = material
	part.mesh = mesh
	add_child(part)

func _material(color: Color, metalness := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalness
	material.roughness = 0.67
	return material
