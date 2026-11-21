@tool
extends StaticBody3D

@export var length := 12.0
@export var width := 3.5
@export var outer_edge := -1.45
@export var stone: Material
@export var cap_stone: Material
@export var gaps: PackedVector2Array

const MERLON_WIDTH := 1.68
const MERLON_DEPTH := 0.78
const MERLON_HEIGHT := 0.98

func _ready() -> void:
	var start := -length * 0.5
	for gap in gaps:
		_span(start, gap.x)
		start = gap.y
	_span(start, length * 0.5)

func _span(start: float, end: float) -> void:
	var span := end - start
	if span <= 0.0:
		return
	_block(Vector3(width + 0.23, 0.22, span), Vector3(0, -0.035, (start + end) * 0.5), cap_stone)
	var count := maxi(1, roundi(span / 2.7))
	var spacing := span / count
	var merlon_width := minf(MERLON_WIDTH, spacing * 0.65)
	var size := Vector3(MERLON_DEPTH, MERLON_HEIGHT, merlon_width)
	var merlons := _row(size, stone, count)
	var caps := _row(Vector3(0.91, 0.14, merlon_width + 0.12), cap_stone, count)
	var shape := BoxShape3D.new()
	shape.size = size
	for i in count:
		var at := Vector3(outer_edge, 0.49, start + (i + 0.5) * spacing)
		merlons.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
		caps.set_instance_transform(i, Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.47))
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = at
		add_child(collision)
	for row: MultiMesh in [merlons, caps]:
		var model := MultiMeshInstance3D.new()
		model.multimesh = row
		add_child(model)

func _row(size: Vector3, material: Material, count: int) -> MultiMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var row := MultiMesh.new()
	row.transform_format = MultiMesh.TRANSFORM_3D
	row.mesh = mesh
	row.instance_count = count
	return row

func _block(size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	add_child(part)
