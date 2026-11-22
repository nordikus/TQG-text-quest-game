@tool
extends StaticBody3D

const FLOOR_HEIGHT := 6.35
const HALF_WIDTH := 10.16
const FRONT := 12.73

@export var stone: Material
@export var dressed_stone: Material
@export var oak: Material

func _ready() -> void:
	_row(Vector3(HALF_WIDTH * 2.0, 0.23, 1.91), [Vector3(0, FLOOR_HEIGHT - 0.115, 13.685)], stone, true)
	_row(Vector3(20.42, 0.12, 0.17), [Vector3(0, 6.28, FRONT)], dressed_stone)
	_row(Vector3(19.95, 0.09, 0.12), [Vector3(0, 6.16, FRONT + 0.01)], dressed_stone)

	var supports: Array[Vector3] = []
	for x: float in [-8.82, -4.26, 4.26, 8.82]:
		supports.append(Vector3(x, 0, 14.42))
	_support_row(supports, Vector3(0.86, 0.22, 0.52), 0.36, 0.0, dressed_stone, true)
	_support_row(supports, Vector3(0.67, 4.96, 0.37), 2.93, 0.0, stone, true)
	_support_row(supports, Vector3(0.77, 0.28, 0.50), 5.38, -0.10, dressed_stone)
	_support_row(supports, Vector3(0.83, 0.21, 0.84), 5.59, -0.26, stone)
	_support_row(supports, Vector3(0.91, 0.21, 1.14), 5.78, -0.43, stone)
	_support_row(supports, Vector3(0.98, 0.27, 1.58), 5.99, -0.63, stone)

	var balusters: Array[Vector3] = []
	for i in range(-13, 14):
		balusters.append(Vector3(i * 0.70, 6.78, FRONT + 0.17))
	_row(Vector3(0.112, 0.75, 0.112), balusters, oak, true)
	_row(Vector3(19.76, 0.13, 0.16), [Vector3(0, 7.20, FRONT + 0.17)], oak, true)
	_row(Vector3(19.76, 0.105, 0.147), [Vector3(0, 6.43, FRONT + 0.17)], oak)
	_row(Vector3(0.38, 0.84, 0.38), [Vector3(-9.95, 6.77, FRONT + 0.17), Vector3(9.95, 6.77, FRONT + 0.17)],
		dressed_stone, true)
	_row(Vector3(0.48, 0.13, 0.48), [Vector3(-9.95, 7.22, FRONT + 0.17), Vector3(9.95, 7.22, FRONT + 0.17)], dressed_stone)

	# A small writing shelf is tucked against the wall inside the gallery.
	_row(Vector3(1.19, 0.115, 0.54), [Vector3(6.65, 7.11, 14.335)], oak, true)
	_row(Vector3(0.13, 0.72, 0.39), [Vector3(6.20, 6.708, 14.415), Vector3(7.10, 6.708, 14.415)], oak)

func _support_row(supports: Array[Vector3], size: Vector3, height: float, offset: float,
		material: Material, solid := false) -> void:
	var positions: Array[Vector3] = []
	for support in supports:
		positions.append(support + Vector3(0, height, offset))
	_row(size, positions, material, solid)

func _row(size: Vector3, positions: Array[Vector3], material: Material, solid := false) -> void:
	var block := BoxMesh.new()
	block.size = size
	block.material = material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = block
	batch.instance_count = positions.size()
	var shape: BoxShape3D
	if solid:
		shape = BoxShape3D.new()
		shape.size = size
	for i in positions.size():
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
		if shape:
			var collider := CollisionShape3D.new()
			collider.position = positions[i]
			collider.shape = shape
			add_child(collider)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = batch
	add_child(instance)
