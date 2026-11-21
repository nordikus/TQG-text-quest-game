@tool
extends Node3D

@export var stone: Material
@export var trim: Material
@export var roof_material: Material

const WALK_Y := 14.80
const WEST_FACE := -34.40
const EAST_FACE := -31.80
const WALL_X := -32.65
const SOUTH := 8.5
const NORTH := -77.6
const APPROACH_X := -23.0
const EXTERIOR_FACE := 10.25
const COURTYARD_FACE := 6.75
const BREACH_FLOOR := 11.83
const PASSAGE_HEIGHT := 2.84
const PASSAGE_HALF_WIDTH := 1.38

func _ready() -> void:
	var wall := _body("WallWest")
	_span(wall, WEST_FACE, EAST_FACE, 0.0, WALK_Y, NORTH, SOUTH, stone)
	_front_wall()
	_corner("CornerTowerSW", SOUTH, true)
	_corner("CornerTowerNW", NORTH, false)
	_stairs()

func _front_wall() -> void:
	var front := _body("WallFrontLeft")
	var left := APPROACH_X - PASSAGE_HALF_WIDTH
	var right := APPROACH_X + PASSAGE_HALF_WIDTH
	var lintel := BREACH_FLOOR + PASSAGE_HEIGHT
	_span(front, -33.0, left, 0.0, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE, stone)
	_span(front, right, -5.0, 0.0, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE, stone)
	_span(front, left, right, 0.0, BREACH_FLOOR, COURTYARD_FACE, EXTERIOR_FACE, stone)
	_span(front, left, right, lintel, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE, stone)

func _corner(tower_name: String, z: float, is_south: bool) -> void:
	var tower := _body(tower_name)
	var foot := Vector3(WALL_X, 0, z)
	_cylinder(tower, foot + Vector3.UP * (WALK_Y * 0.5), 4.62, 4.80, WALK_Y, stone)
	_cylinder(tower, foot + Vector3.UP * 24.86, 0.1, 5.11, 4.92, roof_material)
	var exits := Vector3.FORWARD if is_south else Vector3.BACK
	for i in 24:
		var angle := i * TAU / 24
		var radial := Vector3(cos(angle), 0, sin(angle))
		var place := foot + radial * 4.22
		var doorway := radial.dot(exits) > 0.904 or radial.dot(Vector3.RIGHT) > 0.904
		var bottom := 17.72 if doorway else WALK_Y
		_box(tower, Vector3(0.84, 22.43 - bottom, 1.135), place + Vector3.UP * (bottom + 22.43) * 0.5,
			stone, Vector3(0, -angle, 0))
	# The rear curtain meets its chamber at grade. The lower front curtain uses a ramp.
	_span(tower, -29.28, -27.78, WALK_Y - 0.3, WALK_Y, z - 1.25, z + 1.25, trim)

func _stairs() -> void:
	var stairs := _body("CourtyardWallStair")
	const LOW_X := -6.70
	const HIGH_X := -30.26
	const MIN_Z := 2.86
	const MAX_Z := 5.70
	stairs.position = Vector3(-34.66, 0, -26.36)
	stairs.rotation.y = PI * 0.5
	_ramp_collision(stairs, HIGH_X, LOW_X, WALK_Y, 0.0, MIN_Z, MAX_Z)
	_span(stairs, EAST_FACE, HIGH_X, WALK_Y - 0.34, WALK_Y, MIN_Z, MAX_Z, trim)
	var incline := atan2(WALK_Y, LOW_X - HIGH_X)
	const RAIL_END := HIGH_X + 1.55
	var rail_height := WALK_Y * inverse_lerp(LOW_X, HIGH_X, RAIL_END)
	var handrail := Vector3((LOW_X + RAIL_END) * 0.5, rail_height * 0.5 + 0.47, MIN_Z + 0.15)
	_box(stairs, Vector3(Vector2(LOW_X - RAIL_END, rail_height).length(), 0.94, 0.30), handrail,
		stone, Vector3(0, 0, -incline))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in 62:
		var x := lerpf(LOW_X, HIGH_X, float(i) / 62)
		var next_x := lerpf(LOW_X, HIGH_X, float(i + 1) / 62)
		var y := WALK_Y * float(i) / 62
		var next_y := WALK_Y * float(i + 1) / 62
		_face(surface, [Vector3(next_x, next_y, MIN_Z), Vector3(next_x, next_y, MAX_Z),
			Vector3(x, next_y, MAX_Z), Vector3(x, next_y, MIN_Z)])
		_face(surface, [Vector3(x, y, MIN_Z), Vector3(x, next_y, MIN_Z),
			Vector3(x, next_y, MAX_Z), Vector3(x, y, MAX_Z)])
		_face(surface, [Vector3(x, 0, MAX_Z), Vector3(x, next_y, MAX_Z),
			Vector3(next_x, next_y, MAX_Z), Vector3(next_x, 0, MAX_Z)])
		_face(surface, [Vector3(next_x, 0, MIN_Z), Vector3(next_x, next_y, MIN_Z),
			Vector3(x, next_y, MIN_Z), Vector3(x, 0, MIN_Z)])
	surface.generate_normals()
	surface.set_material(stone)
	_visual(stairs, surface.commit(), Vector3.ZERO)

func _ramp_collision(body: StaticBody3D, west: float, east: float, west_y: float, east_y: float,
		start: float, finish: float) -> void:
	var floor_y := maxf(0.0, minf(west_y, east_y) - 0.33)
	var points := PackedVector3Array([
		Vector3(west, floor_y, start), Vector3(east, floor_y, start),
		Vector3(east, floor_y, finish), Vector3(west, floor_y, finish),
		Vector3(west, west_y, start), Vector3(east, east_y, start),
		Vector3(east, east_y, finish), Vector3(west, west_y, finish),
	])
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	_collision(body, shape, Vector3.ZERO)

func _face(surface: SurfaceTool, corners: Array) -> void:
	for index in [0, 2, 1, 0, 3, 2]:
		surface.add_vertex(corners[index])

func _span(body: StaticBody3D, left: float, right: float, low: float, high: float,
		start: float, finish: float, material: Material) -> void:
	_box(body, Vector3(right - left, high - low, finish - start),
		Vector3((left + right) * 0.5, (low + high) * 0.5, (start + finish) * 0.5), material)

func _body(body_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	add_child(body)
	return body

func _box(body: StaticBody3D, size: Vector3, at: Vector3, material: Material, tilt := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	_visual(body, mesh, at, tilt)
	var shape := BoxShape3D.new()
	shape.size = size
	_collision(body, shape, at, tilt)

func _cylinder(body: StaticBody3D, at: Vector3, top: float, bottom: float, height: float,
		material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 0
	mesh.material = material
	_visual(body, mesh, at)
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for i in mesh.radial_segments:
		var a := TAU * i / mesh.radial_segments
		var radial := Vector3(sin(a), 0, cos(a))
		points.append(radial * top + Vector3.UP * height * 0.5)
		points.append(radial * bottom - Vector3.UP * height * 0.5)
	shape.points = points
	_collision(body, shape, at)

func _visual(body: StaticBody3D, mesh: Mesh, at: Vector3, tilt := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = tilt
	body.add_child(instance)

func _collision(body: StaticBody3D, shape: Shape3D, at: Vector3, tilt := Vector3.ZERO) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	collider.rotation = tilt
	body.add_child(collider)
