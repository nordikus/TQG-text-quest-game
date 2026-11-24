@tool
extends Node3D

const MASONRY := preload("res://scenes/world/castle/masonry.gdshader")
const SLATE := preload("res://scenes/world/castle/slate_roof.gdshader")
const DECK := 18.47
const CROWN := 23.075

var _stone: ShaderMaterial
var _slate: ShaderMaterial
var _trim: StandardMaterial3D
var _recess: StandardMaterial3D

func _ready() -> void:
	_stone = ShaderMaterial.new()
	_stone.shader = MASONRY
	_slate = ShaderMaterial.new()
	_slate.shader = SLATE
	_trim = StandardMaterial3D.new()
	_trim.albedo_color = Color(0.34, 0.36, 0.36)
	_trim.roughness = 0.91
	_recess = StandardMaterial3D.new()
	_recess.albedo_color = Color(0.10, 0.123, 0.128)
	_recess.roughness = 0.9
	for x: float in [-18.9, 18.9]:
		_roof_loft(Vector3(x, DECK - 0.015, 1.0))
		_chimney(Vector3(x * 1.07, DECK, -8.55))
	_finish_crown()

func _roof_loft(at: Vector3) -> void:
	var loft := StaticBody3D.new()
	loft.position = at
	add_child(loft)
	_box(loft, Vector3(0, 0.73, 0), Vector3(17.95, 1.47, 12.2), _stone, true)
	_box(loft, Vector3(0, 0.24, 0), Vector3(18.24, 0.29, 12.48), _trim)
	_box(loft, Vector3(0, 1.43, 0), Vector3(18.76, 0.26, 13.06), _trim)
	var front_left := Vector3(-9.38, 1.55, 6.53)
	var front_right := Vector3(9.38, 1.55, 6.53)
	var back_left := Vector3(-9.38, 1.55, -6.53)
	var back_right := Vector3(9.38, 1.55, -6.53)
	var ridge_left := Vector3(-6.10, 4.05, 0)
	var ridge_right := Vector3(6.10, 4.05, 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for vertex in [front_left, ridge_left, ridge_right, front_left, ridge_right, front_right,
			back_right, ridge_right, ridge_left, back_right, ridge_left, back_left,
			front_right, ridge_right, back_right, back_left, ridge_left, front_left]:
		surface.add_vertex(vertex)
	surface.generate_normals()
	surface.set_material(_slate)
	var roof := MeshInstance3D.new()
	roof.mesh = surface.commit()
	loft.add_child(roof)
	var collider := CollisionShape3D.new()
	collider.shape = roof.mesh.create_trimesh_shape()
	loft.add_child(collider)
	_box(loft, Vector3(0, 4.05, 0), Vector3(12.38, 0.23, 0.36), _trim)
	for x: float in [-6.05, 0.0, 6.05]:
		_vent(loft, Vector3(x, 0.84, 6.12))
		_vent(loft, Vector3(x, 0.84, -6.12), PI)

func _vent(loft: Node3D, at: Vector3, yaw := 0.0) -> void:
	var opening := Node3D.new()
	opening.position = at
	opening.rotation.y = yaw
	loft.add_child(opening)
	_box(opening, Vector3.ZERO, Vector3(0.83, 0.64, 0.052), _recess)
	_box(opening, Vector3(0, 0.355, 0.06), Vector3(1.0, 0.12, 0.21), _trim)
	_box(opening, Vector3(0, -0.34, 0.06), Vector3(1.0, 0.11, 0.21), _trim)
	for y: float in [-0.18, -0.03, 0.12]:
		_box(opening, Vector3(0, y, 0.06), Vector3(0.77, 0.055, 0.08), _trim)

func _chimney(at: Vector3) -> void:
	var stack := StaticBody3D.new()
	stack.position = at
	add_child(stack)
	_box(stack, Vector3(0, 1.15, 0), Vector3(1.24, 2.30, 1.04), _stone, true)
	_box(stack, Vector3(0, 2.21, 0), Vector3(1.48, 0.23, 1.26), _trim)
	for x: float in [-0.47, 0.47]:
		_box(stack, Vector3(x, 2.51, 0), Vector3(0.23, 0.44, 0.74), _stone)
	_box(stack, Vector3(0, 2.75, 0), Vector3(1.50, 0.14, 1.24), _trim)

func _finish_crown() -> void:
	_box(self, Vector3(0, CROWN + 0.07, 6.7), Vector3(15.83, 0.16, 13.68), _slate)
	for x: float in [-7.68, 7.68]:
		_box(self, Vector3(x, CROWN + 0.45, 6.70), Vector3(0.43, 0.86, 13.7), _stone)
		_box(self, Vector3(x, CROWN + 0.91, 6.70), Vector3(0.58, 0.13, 13.74), _trim)
	for z: float in [0.10, 13.10]:
		_box(self, Vector3(0, CROWN + 0.24, z), Vector3(15.0, 0.48, 0.51), _stone)
		_box(self, Vector3(0, CROWN + 0.50, z), Vector3(15.0, 0.11, 0.61), _trim)
	for x: float in [-5.8, -2.9, 0.0, 2.9, 5.8]:
		_box(self, Vector3(x, CROWN + 0.81, 0.10), Vector3(2.2, 1.02, 0.75), _stone)

func _box(parent_node: Node3D, at: Vector3, size: Vector3, material: Material, solid := false) -> void:
	var model := MeshInstance3D.new()
	var block := BoxMesh.new()
	block.size = size
	block.material = material
	model.mesh = block
	model.position = at
	parent_node.add_child(model)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		collider.position = at
		parent_node.add_child(collider)
