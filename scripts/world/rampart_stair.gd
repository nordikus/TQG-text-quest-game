@tool
extends StaticBody3D

const WALK_Y := 14.8
const FOOT_X := -6.70
const LANDING_X := -30.26
const LANDING_LENGTH := 1.54
const LANDING_BACK := LANDING_X - LANDING_LENGTH
const WALL_FACE_Z := 2.86
# Both stair bodies extend into the curtain so the stepped joint cannot open up.
const INNER_Z := WALL_FACE_Z - 0.18
const OUTER_Z := 5.70
const STEP_COUNT := 62
const MASONRY := preload("res://scenes/world/castle/masonry.gdshader")

@export var stone: Material
@export var trim: Material

func _ready() -> void:
	_ramp_collision()
	_approach()
	_build_masonry()
	_build_parapet()

func _build_masonry() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var profile := PackedVector2Array([Vector2(FOOT_X, 0)])
	for i in STEP_COUNT:
		var x := lerpf(FOOT_X, LANDING_X, float(i) / STEP_COUNT)
		var next_x := lerpf(FOOT_X, LANDING_X, float(i + 1) / STEP_COUNT)
		var y := WALK_Y * float(i) / STEP_COUNT
		var next_y := WALK_Y * float(i + 1) / STEP_COUNT
		profile.append(Vector2(x, next_y))
		profile.append(Vector2(next_x, next_y))
		# At wall-walk level the curtain covers the buried edge of the last tread.
		if i == STEP_COUNT - 1:
			_face(surface, [Vector3(LANDING_BACK, WALK_Y, WALL_FACE_Z), Vector3(LANDING_BACK, WALK_Y, OUTER_Z),
				Vector3(x, WALK_Y, OUTER_Z), Vector3(x, WALK_Y, WALL_FACE_Z)])
			_face(surface, [Vector3(LANDING_BACK, WALK_Y - 0.06, INNER_Z), Vector3(LANDING_BACK, WALK_Y, WALL_FACE_Z),
				Vector3(x, WALK_Y, WALL_FACE_Z), Vector3(x, WALK_Y - 0.06, INNER_Z)])
		else:
			_face(surface, [Vector3(next_x, next_y, INNER_Z), Vector3(next_x, next_y, OUTER_Z),
				Vector3(x, next_y, OUTER_Z), Vector3(x, next_y, INNER_Z)])
		_face(surface, [Vector3(x, y, INNER_Z), Vector3(x, next_y, INNER_Z),
			Vector3(x, next_y, OUTER_Z), Vector3(x, y, OUTER_Z)])
	surface.generate_normals()
	surface.set_material(stone)
	var stair_mesh := surface.commit()

	# The landing is part of the stepped section, with both sides, a back and a base.
	profile.append(Vector2(LANDING_BACK, WALK_Y))
	profile.append(Vector2(LANDING_BACK, 0))
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	sides.set_smooth_group(-1)
	var triangles := Geometry2D.triangulate_polygon(profile)
	for i in triangles:
		var point := profile[i]
		sides.add_vertex(Vector3(point.x, point.y, INNER_Z))
	triangles.reverse()
	for i in triangles:
		var point := profile[i]
		sides.add_vertex(Vector3(point.x, point.y, OUTER_Z))
	_face(sides, [Vector3(LANDING_BACK, 0, INNER_Z), Vector3(LANDING_BACK, 0, OUTER_Z),
		Vector3(LANDING_BACK, WALK_Y, OUTER_Z), Vector3(LANDING_BACK, WALK_Y, INNER_Z)])
	_face(sides, [Vector3(LANDING_BACK, 0, INNER_Z), Vector3(FOOT_X, 0, INNER_Z),
		Vector3(FOOT_X, 0, OUTER_Z), Vector3(LANDING_BACK, 0, OUTER_Z)])
	var side_stone := ShaderMaterial.new()
	side_stone.shader = MASONRY
	side_stone.set_shader_parameter("block_size", Vector2(1.27, 0.51))
	side_stone.set_shader_parameter("stone_tint", Vector3(0.62, 0.66, 0.73))
	sides.generate_normals()
	sides.set_material(side_stone)
	sides.commit(stair_mesh)
	_visual(stair_mesh, Vector3.ZERO).name = "StairMasonry"

func _build_parapet() -> void:
	# The curtain protects the wall side. The courtyard parapet follows the whole stair.
	var crest := PackedVector2Array([
		Vector2(FOOT_X, 0.0), Vector2(LANDING_X, WALK_Y), Vector2(LANDING_BACK, WALK_Y),
	])
	var base := OUTER_Z - 0.30
	var edge := OUTER_Z + 0.03
	_parapet_band(crest, base, edge, -0.12, 0.88, stone)
	_parapet_band(crest, base - 0.035, edge + 0.035, 0.88, 1.0, trim)

func _parapet_band(crest: PackedVector2Array, inner: float, outer: float,
		low: float, high: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(crest.size() - 1):
		var start := crest[i]
		var end := crest[i + 1]
		var a := Vector3(start.x, start.y + low, inner)
		var b := Vector3(end.x, end.y + low, inner)
		var c := Vector3(start.x, start.y + high, inner)
		var d := Vector3(end.x, end.y + high, inner)
		var span := Vector3(0.0, 0.0, outer - inner)
		_face(surface, [a, b, d, c])
		_face(surface, [a + span, c + span, d + span, b + span])
		_face(surface, [d, d + span, c + span, c])
		_face(surface, [b, a, a + span, b + span])
		if i == 0:
			_face(surface, [a, c, c + span, a + span])
		if i == crest.size() - 2:
			_face(surface, [b, b + span, d + span, d])
		var shape := ConvexPolygonShape3D.new()
		shape.points = PackedVector3Array([a, b, c, d, a + span, b + span, c + span, d + span])
		_collision(shape, Vector3.ZERO)
	surface.generate_normals()
	surface.set_material(material)
	_visual(surface.commit(), Vector3.ZERO)

func _approach() -> void:
	var post := Vector3(FOOT_X + 0.12, 0, OUTER_Z + 0.38)
	_box(Vector3(0.65, 0.30, 0.60), post + Vector3.UP * 0.15, trim)
	_box(Vector3(0.41, 1.94, 0.39), post + Vector3.UP * 1.27, stone)
	_box(Vector3(0.63, 0.18, 0.57), post + Vector3.UP * 2.29, trim)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.31, 0.16, 0.075)
	_box(Vector3(1.27, 0.32, 0.10), post + Vector3(0, 1.86, 0.245), wood)
	var sign := Label3D.new()
	sign.text = "Боевой ход ↑"
	sign.position = post + Vector3(0, 1.86, 0.301)
	sign.font_size = 42
	sign.pixel_size = 0.0024
	sign.outline_size = 0
	sign.modulate = Color(0.91, 0.79, 0.56)
	add_child(sign)

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.90, 0.61, 0.25)
	glass.emission_enabled = true
	glass.emission = Color(0.93, 0.47, 0.13)
	glass.emission_energy_multiplier = 0.95
	_box(Vector3(0.33, 0.42, 0.33), post + Vector3.UP * 2.59, glass)
	for x in [-0.176, 0.176]:
		for z in [-0.176, 0.176]:
			_box(Vector3(0.035, 0.44, 0.035), post + Vector3(x, 2.59, z), trim)
	_box(Vector3(0.43, 0.13, 0.43), post + Vector3.UP * 2.85, trim)
	var light := OmniLight3D.new()
	light.position = post + Vector3(0.1, 2.55, 0.50)
	light.light_color = Color(1.0, 0.69, 0.32)
	light.light_energy = 2.75
	light.omni_range = 9.6
	add_child(light)

func _ramp_collision() -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(LANDING_X, 0, INNER_Z), Vector3(FOOT_X, 0, INNER_Z), Vector3(LANDING_X, WALK_Y, INNER_Z),
		Vector3(LANDING_X, 0, OUTER_Z), Vector3(FOOT_X, 0, OUTER_Z), Vector3(LANDING_X, WALK_Y, OUTER_Z),
	])
	_collision(shape, Vector3.ZERO)
	var landing := BoxShape3D.new()
	landing.size = Vector3(LANDING_LENGTH, WALK_Y, OUTER_Z - INNER_Z)
	_collision(landing, Vector3(LANDING_X - LANDING_LENGTH * 0.5, WALK_Y * 0.5, (INNER_Z + OUTER_Z) * 0.5))

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

func _visual(mesh: Mesh, at: Vector3, tilt := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = tilt
	add_child(instance)
	return instance

func _collision(shape: Shape3D, at: Vector3, tilt := Vector3.ZERO) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	collider.rotation = tilt
	add_child(collider)
