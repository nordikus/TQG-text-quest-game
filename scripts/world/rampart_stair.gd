@tool
extends StaticBody3D

const WALK_Y := 14.8
const FOOT_X := -6.70
const LANDING_X := -30.26
const INNER_Z := 2.86
const OUTER_Z := 5.70
const PAVING := preload("res://scenes/world/castle/flagstones.gdshader")
const MASONRY := preload("res://scenes/world/castle/masonry.gdshader")

@export var stone: Material
@export var trim: Material

func _ready() -> void:
	_ramp_collision()
	_approach()
	_box(Vector3(1.54, 0.34, OUTER_Z - INNER_Z),
		Vector3(LANDING_X - 0.77, WALK_Y - 0.17, (INNER_Z + OUTER_Z) * 0.5), trim)
	var incline := atan2(WALK_Y, FOOT_X - LANDING_X)
	const RAIL_END := LANDING_X + 1.55
	var rail_height := WALK_Y * inverse_lerp(FOOT_X, LANDING_X, RAIL_END)
	var rail_length := Vector2(FOOT_X - RAIL_END, rail_height).length()
	for side in [INNER_Z + 0.15, OUTER_Z - 0.15]:
		var guard := Vector3((FOOT_X + RAIL_END) * 0.5, rail_height * 0.5 + 0.47, side)
		var tilt := Vector3(0, 0, -incline)
		_box(Vector3(rail_length, 0.94, 0.30), guard, stone, tilt)
		var coping := BoxMesh.new()
		coping.size = Vector3(rail_length, 0.11, 0.36)
		coping.material = trim
		_visual(coping, guard + Vector3(sin(incline), cos(incline), 0) * 0.49, tilt)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	sides.set_smooth_group(-1)
	for i in 62:
		var x := lerpf(FOOT_X, LANDING_X, float(i) / 62)
		var next_x := lerpf(FOOT_X, LANDING_X, float(i + 1) / 62)
		var y := WALK_Y * float(i) / 62
		var next_y := WALK_Y * float(i + 1) / 62
		_face(surface, [Vector3(next_x, next_y, INNER_Z), Vector3(next_x, next_y, OUTER_Z),
			Vector3(x, next_y, OUTER_Z), Vector3(x, next_y, INNER_Z)])
		_face(surface, [Vector3(x, y, INNER_Z), Vector3(x, next_y, INNER_Z),
			Vector3(x, next_y, OUTER_Z), Vector3(x, y, OUTER_Z)])
		_face(sides, [Vector3(x, 0, OUTER_Z), Vector3(x, next_y, OUTER_Z),
			Vector3(next_x, next_y, OUTER_Z), Vector3(next_x, 0, OUTER_Z)])
		_face(sides, [Vector3(next_x, 0, INNER_Z), Vector3(next_x, next_y, INNER_Z),
			Vector3(x, next_y, INNER_Z), Vector3(x, 0, INNER_Z)])
	surface.generate_normals()
	surface.set_material(stone)
	var stair_mesh := surface.commit()
	var side_stone := ShaderMaterial.new()
	side_stone.shader = MASONRY
	side_stone.set_shader_parameter("block_size", Vector2(1.27, 0.51))
	side_stone.set_shader_parameter("stone_tint", Vector3(0.62, 0.66, 0.73))
	sides.generate_normals()
	sides.set_material(side_stone)
	sides.commit(stair_mesh)
	_visual(stair_mesh, Vector3.ZERO)

func _approach() -> void:
	var paving := BoxMesh.new()
	paving.size = Vector3(3.10, 0.048, 8.12)
	var flags := ShaderMaterial.new()
	flags.shader = PAVING
	paving.material = flags
	_visual(paving, Vector3(FOOT_X + 1.0, 0.008, 7.93))

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
