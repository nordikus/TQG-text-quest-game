@tool
extends Node3D

const Plant := preload("res://scripts/world/forest_plant.gd")
const BARK := preload("res://scenes/world/forest_bark.gdshader")
const HALF_STEPS := 12
const LEAF_DARK := Color(0.14, 0.31, 0.15)
const LEAF_LIGHT := Color(0.36, 0.52, 0.22)

@export var crown_height := 4.5
@export var span := 6.6
@export var variant := 0

func _ready() -> void:
	var wood := Plant.begin_surface()
	var foliage := Plant.begin_surface()
	var profile := _arch_profile()
	var radii := PackedFloat32Array()
	for i in profile.size():
		var t := float(i) / (profile.size() - 1)
		var taper := pow(absf(t * 2.0 - 1.0), 2.2)
		radii.append(lerpf(0.157, 0.44, taper) * (1.0 + 0.12 * sin(t * TAU + variant)))
	_tube(wood, profile, radii, 9)

	for side: float in [-1.0, 1.0]:
		var foot := profile[0] if side < 0.0 else profile[-1]
		var base := foot.lerp(profile[1] if side < 0.0 else profile[-2], 0.68)
		for offset: float in [-0.9, 0.84]:
			var end := foot + Vector3(side * (0.76 + 0.15 * sin(variant + offset)), 0.08, offset)
			var root := _curve(base, base + Vector3(side * 0.24, -0.21, offset * 0.27),
				end + Vector3(-side * 0.35, 0.48, -0.26 * offset), end, 5)
			_tapered(wood, root, 0.168, 0.023, 6)

	var fork_side := -1.0 if variant % 2 == 0 else 1.0
	var start := profile[3] if fork_side < 0.0 else profile[21]
	var junction := profile[9] if fork_side < 0.0 else profile[15]
	var fork := _curve(start, start + Vector3(fork_side * 0.54, 0.95, 0.48),
		junction + Vector3(fork_side * 0.84, -0.42, 0.83), junction, 10)
	_tapered(wood, fork, 0.117, 0.049, 7)
	var fork_tip := fork[6] + Vector3(fork_side * 0.78, 0.64, 0.44)
	var fork_sprig := _curve(fork[6], fork[6] + Vector3(fork_side * 0.28, 0.42, 0.10),
		fork_tip - Vector3(fork_side * 0.04, 0.22, 0.21), fork_tip, 6)
	_tapered(wood, fork_sprig, 0.062, 0.012, 6)
	_leaves(foliage, fork_sprig, variant + 5)

	for i in range(5, 21, 2):
		var p := profile[i]
		var outward := -1.0 if i < HALF_STEPS else 1.0
		var side := 1.0 if (i / 2 + variant) % 2 == 0 else -1.0
		var spread := 0.84 + 0.20 * sin(i + variant * 1.7)
		var end := p + Vector3(outward * (0.45 + spread * 0.53), 0.19 + 0.29 * spread, side * spread)
		var sprig := _curve(p, p + Vector3(outward * 0.30, 0.26, side * 0.32),
			end + Vector3(-outward * 0.20, 0.19, -side * 0.18), end, 6)
		_tapered(wood, sprig, 0.111 if i in [7, 15] else 0.071, 0.014, 6)
		_leaves(foliage, sprig, i + variant)
		var shoot_end := sprig[3] + Vector3(outward * 0.40, 0.48, -side * 0.50)
		var shoot := _curve(sprig[3], sprig[3] + Vector3(0, 0.34, -side * 0.05),
			shoot_end + Vector3(-outward * 0.13, 0.10, side * 0.17), shoot_end, 5)
		_tapered(wood, shoot, 0.032, 0.009, 5)
		_leaves(foliage, shoot, i + variant + 1)

	var bark := ShaderMaterial.new()
	bark.shader = BARK
	wood.set_material(bark)
	wood.generate_normals()
	var combined := wood.commit()
	var leaves := StandardMaterial3D.new()
	leaves.vertex_color_use_as_albedo = true
	leaves.vertex_color_is_srgb = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.roughness = 0.94
	foliage.set_material(leaves)
	foliage.generate_normals()
	foliage.commit(combined)
	var model := MeshInstance3D.new()
	model.name = "GrownBough"
	model.mesh = combined
	add_child(model)

func _arch_profile() -> PackedVector3Array:
	var offset := sin(variant * 1.93 + 0.9)
	var left := Vector3(-span * 0.5, -0.24, -0.24 + 0.23 * offset)
	var right := Vector3(span * 0.5, -0.23, 0.28 + 0.24 * offset)
	var crown := Vector3(0.50 * offset, crown_height, 0.37 * offset)
	var first := _curve(left, left + Vector3(-0.44, crown_height * 0.63, -0.24),
		crown + Vector3(-span * 0.28, -0.20 * offset, -0.46), crown, HALF_STEPS)
	var second := _curve(crown, crown + Vector3(span * 0.28, 0.20 * offset, 0.46),
		right + Vector3(0.32, crown_height * 0.65, 0.24), right, HALF_STEPS)
	first.append_array(second.slice(1))
	return first

func _curve(a: Vector3, b: Vector3, c: Vector3, d: Vector3, steps: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in range(steps + 1):
		points.append(a.bezier_interpolate(b, c, d, float(i) / steps))
	return points

func _tapered(surface: SurfaceTool, points: PackedVector3Array, base: float, tip: float, sides: int) -> void:
	var widths := PackedFloat32Array()
	for i in points.size():
		widths.append(lerpf(base, tip, float(i) / (points.size() - 1)))
	_tube(surface, points, widths, sides)

func _tube(surface: SurfaceTool, points: PackedVector3Array, widths: PackedFloat32Array, sides: int) -> void:
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var along := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var across := along.cross(Vector3.FORWARD if absf(along.z) < 0.94 else Vector3.RIGHT).normalized()
		var up := along.cross(across)
		var ring := PackedVector3Array()
		for side in sides:
			var angle := TAU * side / sides
			var uneven := 1.0 + 0.07 * sin(side * 3.51 + variant + 0.33 * i)
			ring.append(points[i] + (across * cos(angle) + up * sin(angle)) * widths[i] * uneven)
		rings.append(ring)

	var y := 0.0
	for i in range(rings.size() - 1):
		var next_y := y + points[i].distance_to(points[i + 1]) * 0.31
		for side in sides:
			var after := (side + 1) % sides
			var u := float(side) / sides
			var next_u := float(side + 1) / sides
			var a := rings[i][side]
			var b := rings[i][after]
			var c := rings[i + 1][side]
			var d := rings[i + 1][after]
			_vertex(surface, a, u, y)
			_vertex(surface, c, u, next_y)
			_vertex(surface, d, next_u, next_y)
			_vertex(surface, a, u, y)
			_vertex(surface, d, next_u, next_y)
			_vertex(surface, b, next_u, y)
		y = next_y
	for side in sides:
		var after := (side + 1) % sides
		_vertex(surface, points[0], 0.5, 0)
		_vertex(surface, rings[0][side], 0, 0)
		_vertex(surface, rings[0][after], 1, 0)
		_vertex(surface, points[-1], 0.5, y)
		_vertex(surface, rings[-1][after], 1, y)
		_vertex(surface, rings[-1][side], 0, y)

func _vertex(surface: SurfaceTool, at: Vector3, u: float, v: float) -> void:
	surface.set_uv(Vector2(u, v))
	surface.add_vertex(at)

func _leaves(surface: SurfaceTool, sprig: PackedVector3Array, seed_value: int) -> void:
	for i in range(2, sprig.size()):
		var root := sprig[i]
		var tangent := (root - sprig[i - 1]).normalized()
		var across := tangent.cross(Vector3.UP).normalized()
		for side: float in [-1.0, 1.0]:
			var phase := 1.47 * i + side * 1.8 + seed_value
			var length := 0.31 + 0.10 * sin(phase)
			var direction := (across * side + tangent * 0.56 + Vector3.UP * (0.34 + sin(phase) * 0.4)).normalized()
			var tip := root + direction * length
			var bent := root.lerp(tip, 0.57) + Vector3.UP * (0.043 + 0.036 * cos(phase))
			var width := direction.cross(Vector3.UP).normalized() * (0.082 + 0.020 * cos(phase))
			var color := LEAF_DARK.lerp(LEAF_LIGHT, 0.48 + 0.43 * sin(phase * 1.92))
			Plant.append_leaf(surface, root, bent, tip, width, color)
