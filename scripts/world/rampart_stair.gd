@tool
extends StaticBody3D

const WALK_Y := 14.8
const FOOT_X := -6.70
const LANDING_X := -30.26
const INNER_Z := 2.86
const OUTER_Z := 5.70

@export var stone: Material
@export var trim: Material

func _ready() -> void:
	_ramp_collision()
	_box(Vector3(1.54, 0.34, OUTER_Z - INNER_Z),
		Vector3(LANDING_X - 0.77, WALK_Y - 0.17, (INNER_Z + OUTER_Z) * 0.5), trim)
	var incline := atan2(WALK_Y, FOOT_X - LANDING_X)
	const RAIL_END := LANDING_X + 1.55
	var rail_height := WALK_Y * inverse_lerp(FOOT_X, LANDING_X, RAIL_END)
	for side in [INNER_Z + 0.15, OUTER_Z - 0.15]:
		var guard := Vector3((FOOT_X + RAIL_END) * 0.5, rail_height * 0.5 + 0.47, side)
		_box(Vector3(Vector2(FOOT_X - RAIL_END, rail_height).length(), 0.94, 0.30), guard,
			stone, Vector3(0, 0, -incline))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in 62:
		var x := lerpf(FOOT_X, LANDING_X, float(i) / 62)
		var next_x := lerpf(FOOT_X, LANDING_X, float(i + 1) / 62)
		var y := WALK_Y * float(i) / 62
		var next_y := WALK_Y * float(i + 1) / 62
		_face(surface, [Vector3(next_x, next_y, INNER_Z), Vector3(next_x, next_y, OUTER_Z),
			Vector3(x, next_y, OUTER_Z), Vector3(x, next_y, INNER_Z)])
		_face(surface, [Vector3(x, y, INNER_Z), Vector3(x, next_y, INNER_Z),
			Vector3(x, next_y, OUTER_Z), Vector3(x, y, OUTER_Z)])
		_face(surface, [Vector3(x, 0, OUTER_Z), Vector3(x, next_y, OUTER_Z),
			Vector3(next_x, next_y, OUTER_Z), Vector3(next_x, 0, OUTER_Z)])
		_face(surface, [Vector3(next_x, 0, INNER_Z), Vector3(next_x, next_y, INNER_Z),
			Vector3(x, next_y, INNER_Z), Vector3(x, 0, INNER_Z)])
	surface.generate_normals()
	surface.set_material(stone)
	_visual(surface.commit(), Vector3.ZERO)

func _ramp_collision() -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(LANDING_X, 0, INNER_Z), Vector3(FOOT_X, 0, INNER_Z), Vector3(LANDING_X, WALK_Y, INNER_Z),
		Vector3(LANDING_X, 0, OUTER_Z), Vector3(FOOT_X, 0, OUTER_Z), Vector3(LANDING_X, WALK_Y, OUTER_Z),
	])
	_collision(shape, Vector3.ZERO)

func _face(surface: SurfaceTool, corners: Array) -> void:
	for index in [0, 2, 1, 0, 3, 2]:
		surface.add_vertex(corners[index])

func _box(size: Vector3, at: Vector3, material: Material, tilt := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	_visual(mesh, at, tilt)
	var shape := BoxShape3D.new()
	shape.size = size
	_collision(shape, at, tilt)

func _visual(mesh: Mesh, at: Vector3, tilt := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = tilt
	add_child(instance)

func _collision(shape: Shape3D, at: Vector3, tilt := Vector3.ZERO) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	collider.rotation = tilt
	add_child(collider)
