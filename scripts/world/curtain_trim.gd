@tool
extends StaticBody3D

@export var length := 12.0
@export var width := 3.5
@export var outer_edge := -1.45
@export var stone: Material
@export var cap_stone: Material

const MERLON_WIDTH := 1.68
const MERLON_DEPTH := 0.78
const MERLON_HEIGHT := 0.98

func _ready() -> void:
	_block(Vector3(width + 0.23, 0.22, length), Vector3(0, -0.035, 0), cap_stone)
	var count := maxi(1, roundi(length / 2.7))
	var spacing := length / count
	var merlon_width := minf(MERLON_WIDTH, spacing * 0.65)
	for i in count:
		var at := Vector3(outer_edge, 0.49, (i + 0.5) * spacing - length * 0.5)
		var size := Vector3(MERLON_DEPTH, MERLON_HEIGHT, merlon_width)
		_block(size, at, stone)
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = at
		add_child(collision)
		_block(Vector3(0.91, 0.14, merlon_width + 0.12), at + Vector3.UP * 0.47, cap_stone)

func _block(size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	add_child(part)
