@tool
extends Node3D

@export var stone: Material
@export var trim: Material
@export var roof_material: Material

const WALK_Y := 14.80
const TOP_Y := 22.97
const WEST_FACE := -34.40
const EAST_FACE := -31.80
const WALL_X := -32.65
const SOUTH := 8.5
const NORTH := -77.6
const BREACH_Z := -20.12
const WALK_START := -74.25
const WALK_END := 5.15
const UPPER_Y := 20.15

func _ready() -> void:
	var wall := _body("WallWest")
	_span(wall, WEST_FACE, EAST_FACE, 0.0, WALK_Y, NORTH, SOUTH, stone)
	_outside_gallery(wall)
	_span(wall, WEST_FACE, -33.39, UPPER_Y, TOP_Y, WALK_START, BREACH_Z - 1.38, stone)
	_span(wall, WEST_FACE, -33.39, UPPER_Y, TOP_Y, BREACH_Z + 1.38, WALK_END, stone)
	_span(wall, WEST_FACE, EAST_FACE, 19.70, UPPER_Y, WALK_START, WALK_END, stone)

	_inside_gallery(wall)
	_crest(wall, WALK_START, BREACH_Z - 1.56)
	_crest(wall, BREACH_Z + 1.56, WALK_END)
	_upper_crossing()
	_corner("CornerTowerSW", SOUTH, true)
	_corner("CornerTowerNW", NORTH, false)
	_stairs()

func _outside_gallery(wall: StaticBody3D) -> void:
	const OUTER_INNER_FACE := -34.00
	_span(wall, WEST_FACE, OUTER_INNER_FACE, WALK_Y, 16.00, WALK_START, WALK_END, stone)
	_span(wall, WEST_FACE, OUTER_INNER_FACE, 17.64, UPPER_Y, WALK_START, WALK_END, stone)
	for i in 14:
		var a := lerpf(WALK_START, WALK_END, float(i) / 14)
		var b := lerpf(WALK_START, WALK_END, float(i + 1) / 14)
		_span(wall, WEST_FACE, OUTER_INNER_FACE, 16.00, 17.64, a, b - 0.43, stone)

func _inside_gallery(wall: StaticBody3D) -> void:
	const STAIR_OPENING := 2.80
	const KEEP_EDGE := -45.5
	const INNER_FACE := -32.43
	_span(wall, INNER_FACE, EAST_FACE, WALK_Y, 19.70, WALK_START, KEEP_EDGE, stone)
	_span(wall, INNER_FACE, EAST_FACE, WALK_Y, 15.98, KEEP_EDGE, STAIR_OPENING, stone)
	_span(wall, INNER_FACE, EAST_FACE, 18.25, 19.70, KEEP_EDGE, WALK_END, stone)
	for i in 9:
		var a := lerpf(KEEP_EDGE, STAIR_OPENING, float(i) / 9)
		var b := lerpf(KEEP_EDGE, STAIR_OPENING, float(i + 1) / 9)
		_span(wall, INNER_FACE, EAST_FACE, 15.98, 18.25, a, b - 1.47, stone)
	for z in [-70.0, -62.0, -53.5, -44.0, -35.4, -26.5, -17.4, -7.4, 1.9]:
		var light := OmniLight3D.new()
		light.position = Vector3(-33.31, 17.74, z)
		light.light_color = Color(0.91, 0.75, 0.55)
		light.light_energy = 0.62
		light.omni_range = 6.2
		wall.add_child(light)

func _crest(wall: StaticBody3D, start: float, finish: float) -> void:
	_span(wall, WEST_FACE - 0.08, -33.31, TOP_Y - 0.15, TOP_Y, start, finish, trim)
	var count := roundi((finish - start) / 2.7)
	for i in count:
		var z := lerpf(start, finish, (i + 0.5) / count)
		_span(wall, WEST_FACE, -33.52, TOP_Y, TOP_Y + 0.74, z - 0.80, z + 0.80, stone)
		_span(wall, WEST_FACE - 0.06, -33.45, TOP_Y + 0.74, TOP_Y + 0.86, z - 0.86, z + 0.86, trim)

func _upper_crossing() -> void:
	var crossing := _body("ObservatoryCrossing")
	const TOWER_EDGE := -27.8
	_span(crossing, EAST_FACE, TOWER_EDGE, UPPER_Y - 0.43, UPPER_Y, BREACH_Z - 1.38, BREACH_Z + 1.38, stone)
	for side in [-1, 1]:
		var z: float = BREACH_Z + 1.50 * side
		_span(crossing, -33.39, TOWER_EDGE, UPPER_Y, 23.0, z - 0.18, z + 0.18, stone)
		_span(crossing, EAST_FACE, EAST_FACE + 0.9, 18.58, UPPER_Y - 0.43, z - 0.24, z + 0.24, stone)
	# The gallery begins behind the outer face and occupies the space above the guard walk.
	_span(crossing, -33.39, TOWER_EDGE, 23.0, 23.29, BREACH_Z - 1.68, BREACH_Z + 1.68, trim)

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
	if is_south:
		_ramp(tower, -27.78, -24.35, WALK_Y, 13.80, z - 1.25, z + 1.25)

func _stairs() -> void:
	var stairs := _body("CourtyardWallStair")
	const LOW_X := -6.70
	const HIGH_X := -30.26
	const MIN_Z := 2.86
	const MAX_Z := 6.75
	_ramp(stairs, HIGH_X, LOW_X, WALK_Y, 0.0, MIN_Z, MAX_Z, false)
	_span(stairs, EAST_FACE, HIGH_X, WALK_Y - 0.34, WALK_Y, MIN_Z, MAX_Z, trim)
	var incline := atan2(WALK_Y, LOW_X - HIGH_X)
	var handrail := Vector3((LOW_X + HIGH_X) * 0.5, WALK_Y * 0.5 + 0.47, MIN_Z + 0.15)
	_box(stairs, Vector3(Vector2(LOW_X - HIGH_X, WALK_Y).length(), 0.94, 0.30), handrail,
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

func _ramp(body: StaticBody3D, west: float, east: float, west_y: float, east_y: float,
		start: float, finish: float, visible_ramp := true) -> void:
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
	if visible_ramp:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for indices in [[4, 7, 6, 5], [0, 4, 5, 1], [3, 2, 6, 7]]:
			_face(surface, [points[indices[0]], points[indices[1]], points[indices[2]], points[indices[3]]])
		surface.generate_normals()
		surface.set_material(trim)
		_visual(body, surface.commit(), Vector3.ZERO)

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
