@tool
extends SceneTree

# -----------------------------------------------------------------------------
# ToolMeshBuilder Wrapper
# -----------------------------------------------------------------------------
class ToolMeshBuilder:
	var st: SurfaceTool
	var vert_count: int = 0

	func _init() -> void:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func add_vertex(v: Vector3) -> int:
		var idx: int = vert_count
		st.add_vertex(v)
		vert_count += 1
		return idx

	func set_color(c: Color) -> void:
		st.set_color(c)

	func set_normal(n: Vector3) -> void:
		st.set_normal(n)

	func set_uv(uv: Vector2) -> void:
		st.set_uv(uv)

	func add_index(i: int) -> void:
		st.add_index(i)

	func generate_normals() -> void:
		st.generate_normals()

	func commit(target: ArrayMesh) -> void:
		st.commit(target)


# -----------------------------------------------------------------------------
# Path Frame & Spline Helper
# -----------------------------------------------------------------------------
class PathFrame:
	var pos: Vector3 = Vector3.ZERO
	var tangent: Vector3 = Vector3.FORWARD
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3.UP
	var t: float = 0.0

class Spline3D:
	var points: Array[Vector3] = []
	var closed: bool = false
	var total_length: float = 0.0
	var segment_lengths: Array[float] = []

	func _init(pts: Array[Vector3], is_closed: bool = false) -> void:
		points = pts
		closed = is_closed
		_calc_lengths()

	func _calc_lengths() -> void:
		total_length = 0.0
		segment_lengths.clear()
		var n: int = points.size()
		if n < 2:
			return
		var count: int = n if closed else n - 1
		for i in range(count):
			var p0: Vector3 = points[i]
			var p1: Vector3 = points[(i + 1) % n]
			var seg_len: float = 0.0
			var prev: Vector3 = p0
			var samples: int = 16
			for s in range(1, samples + 1):
				var curr: Vector3 = _eval_segment(i, float(s) / float(samples))
				seg_len += prev.distance_to(curr)
				prev = curr
			segment_lengths.append(seg_len)
			total_length += seg_len

	func _eval_segment(i: int, s: float) -> Vector3:
		var n: int = points.size()
		var p0: Vector3
		var p1: Vector3
		var p2: Vector3
		var p3: Vector3

		if closed:
			p0 = points[(i - 1 + n) % n]
			p1 = points[i]
			p2 = points[(i + 1) % n]
			p3 = points[(i + 2) % n]
		else:
			p1 = points[i]
			p2 = points[i + 1]
			p0 = points[i - 1] if i > 0 else (2.0 * p1 - p2)
			p3 = points[i + 2] if (i + 2) < n else (2.0 * p2 - p1)

		var s2: float = s * s
		var s3: float = s2 * s
		return 0.5 * (
			(2.0 * p1) +
			(-p0 + p2) * s +
			(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s2 +
			(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s3
		)

	func _eval_tangent_segment(i: int, s: float) -> Vector3:
		var n: int = points.size()
		var p0: Vector3
		var p1: Vector3
		var p2: Vector3
		var p3: Vector3

		if closed:
			p0 = points[(i - 1 + n) % n]
			p1 = points[i]
			p2 = points[(i + 1) % n]
			p3 = points[(i + 2) % n]
		else:
			p1 = points[i]
			p2 = points[i + 1]
			p0 = points[i - 1] if i > 0 else (2.0 * p1 - p2)
			p3 = points[i + 2] if (i + 2) < n else (2.0 * p2 - p1)

		var s2: float = s * s
		var d: Vector3 = 0.5 * (
			(-p0 + p2) +
			2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s +
			3.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s2
		)
		return d.normalized()

	func sample(t: float) -> PathFrame:
		t = clampf(t, 0.0, 1.0)
		var target_d: float = t * total_length
		var accumulated: float = 0.0
		var n: int = points.size()
		var count: int = n if closed else n - 1

		for i in range(count):
			var seg_l: float = segment_lengths[i]
			if accumulated + seg_l >= target_d or i == count - 1:
				var local_s: float = 0.0
				if seg_l > 0.0001:
					local_s = clampf((target_d - accumulated) / seg_l, 0.0, 1.0)
				var pos: Vector3 = _eval_segment(i, local_s)
				var tang: Vector3 = _eval_tangent_segment(i, local_s)
				var right: Vector3 = tang.cross(Vector3.UP).normalized()
				if right.length_squared() < 0.01:
					right = Vector3.RIGHT
				var up: Vector3 = right.cross(tang).normalized()
				var frame := PathFrame.new()
				frame.pos = pos
				frame.tangent = tang
				frame.right = right
				frame.up = up
				frame.t = t
				return frame
			accumulated += seg_l

		var last_i: int = count - 1
		var last_pos: Vector3 = _eval_segment(last_i, 1.0)
		var last_tang: Vector3 = _eval_tangent_segment(last_i, 1.0)
		var last_right: Vector3 = last_tang.cross(Vector3.UP).normalized()
		var last_up: Vector3 = last_right.cross(last_tang).normalized()
		var last_frame := PathFrame.new()
		last_frame.pos = last_pos
		last_frame.tangent = last_tang
		last_frame.right = last_right
		last_frame.up = last_up
		last_frame.t = 1.0
		return last_frame


# -----------------------------------------------------------------------------
# Main Tool Logic
# -----------------------------------------------------------------------------
const Layout := preload("res://scripts/world/forest_layout.gd")

func _init() -> void:
	print("--- Starting Story Paths Baker ---")

	var nature_spline := Spline3D.new(Layout.LIFE_PATH)
	var burning_spline := Spline3D.new(Layout.ASH_PATH)

	if not OS.get_cmdline_user_args().has("ash-only"):
		_bake_nature_trail(nature_spline)
	_bake_burning_path(burning_spline)

	print("--- Story Paths Baking Finished Successfully ---")
	quit(0)


func _connect_tube_grid(b: ToolMeshBuilder, base_idx: int, rings: int, ring_pts: int, is_closed_ring: bool = false) -> void:
	for r in range(rings - 1):
		var r0: int = base_idx + r * ring_pts
		var r1: int = base_idx + (r + 1) * ring_pts
		var segs: int = ring_pts if is_closed_ring else ring_pts - 1
		for s in range(segs):
			var i0: int = r0 + s
			var i1: int = r0 + ((s + 1) % ring_pts if is_closed_ring else s + 1)
			var i2: int = r1 + s
			var i3: int = r1 + ((s + 1) % ring_pts if is_closed_ring else s + 1)

			b.add_index(i0)
			b.add_index(i1)
			b.add_index(i2)

			b.add_index(i1)
			b.add_index(i3)
			b.add_index(i2)


# -----------------------------------------------------------------------------
# BAKE NATURE TRAIL
# -----------------------------------------------------------------------------
func _life_trail_width(t: float) -> float:
	return 2.13 + 0.20 * sin(t * 19.0) + 2.40 * smoothstep(0.80, 1.0, t)


func _bake_nature_trail(spline: Spline3D) -> void:
	print("Baking Nature Trail...")
	var ground := ToolMeshBuilder.new()
	var stones := ToolMeshBuilder.new()
	var plants := ToolMeshBuilder.new()
	var glow := ToolMeshBuilder.new()
	var water := ToolMeshBuilder.new()
	var detail := FastNoiseLite.new()
	detail.seed = 2318
	detail.frequency = 0.68
	const ROWS := 135
	const COLUMNS := 17
	for i in ROWS + 1:
		var t := float(i) / ROWS
		var frame := spline.sample(t)
		var width := _life_trail_width(t)
		for j in COLUMNS:
			var u := float(j) * 2.0 / (COLUMNS - 1) - 1.0
			var at := frame.pos + frame.right * (width * u + 0.10 * sin(t * 53.0) * u * u)
			var wet := detail.get_noise_2d(at.x, at.z)
			var worn := 1.0 - smoothstep(0.16, 0.72, absf(u + wet * 0.20))
			at.y = lerpf(0.027, 0.051, worn) + 0.009 * wet
			var moss := Color(0.22, 0.33, 0.13).lerp(Color(0.35, 0.46, 0.20), wet + 0.45)
			var earth := Color(0.34, 0.235, 0.132).lerp(Color(0.56, 0.432, 0.275), 0.51 + wet * 0.68)
			var tint := moss.lerp(earth, worn)
			var ragged := absf(u) + wet * 0.12 * absf(u)
			tint.a = (1.0 - smoothstep(0.66, 1.0, ragged)) * smoothstep(0.0, 0.040, t)
			ground.set_color(tint)
			ground.add_vertex(at)
	_connect_tube_grid(ground, 0, ROWS + 1, COLUMNS)

	# Weathered stones show where water and foot traffic have stripped the moss.
	for i in 31:
		var t := 0.045 + 0.934 * float(i) / 30.0
		var frame := spline.sample(t)
		var at := frame.pos + frame.right * (0.59 * sin(i * 2.51))
		var width := 0.45 + 0.17 * cos(i * 1.61)
		var length := 0.36 + 0.12 * sin(i * 2.17)
		_trail_stone(stones, at, Vector2(width, length), 0.076 + 0.026 * sin(i * 2.71), i * 2.0)

	for i in 58:
		var t := 0.035 + 0.945 * float(i) / 57.0
		var frame := spline.sample(t)
		var side := -1.0 if i % 2 == 0 else 1.0
		var edge := frame.pos + frame.right * side * (_life_trail_width(t) + 0.14 * sin(i * 3.79))
		var size := 0.60 + 0.22 * sin(i * 2.93)
		_trail_fern(plants, edge + Vector3.UP * 0.022, side * 0.7 + i * 0.91, size)
		if i % 4 == 0:
			_trail_fern(plants, edge + frame.right * (side * 0.62) + frame.tangent * 0.52, i * 0.38, size * 1.17)
		if i % 3 != 1:
			for mushroom in 2 + i % 2:
				var at := edge - frame.right * side * (0.20 + 0.12 * mushroom) + frame.tangent * (mushroom * 0.21)
				var height := 0.14 + 0.07 * sin(i * 4.17 + mushroom * 2.7)
				_build_3d_mushroom(plants, glow, at + Vector3.UP * 0.035, height, height * 0.77, Color(0.30, 0.95, 0.75))

	_build_life_spring(stones, plants, glow, water)
	# Stone shoulders frame the last few steps into the roots.
	for i in 7:
		var angle := -0.75 + i * 0.41
		var at := Vector3(-17.75 + 4.18 * cos(angle), 0, -56.8 + 3.97 * sin(angle))
		_trail_stone(stones, at, Vector2(0.5 + 0.12 * sin(i * 1.72), 0.49), 0.15 + 0.09 * cos(i), i * 1.25)

	var soil := StandardMaterial3D.new()
	soil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soil.cull_mode = BaseMaterial3D.CULL_DISABLED
	soil.vertex_color_use_as_albedo = true
	soil.vertex_color_is_srgb = true
	soil.roughness = 0.94
	var rock := StandardMaterial3D.new()
	rock.vertex_color_use_as_albedo = true
	rock.vertex_color_is_srgb = true
	rock.cull_mode = BaseMaterial3D.CULL_DISABLED
	rock.roughness = 0.87
	var leaf := rock.duplicate() as StandardMaterial3D
	leaf.roughness = 0.76
	var light := rock.duplicate() as StandardMaterial3D
	light.emission_enabled = true
	light.emission = Color(0.25, 0.86, 0.68)
	light.emission_energy_multiplier = 1.85
	var spring := rock.duplicate() as StandardMaterial3D
	spring.metallic = 0.34
	spring.roughness = 0.24

	var mesh := ArrayMesh.new()
	for surface: ToolMeshBuilder in [ground, stones, plants, glow, water]:
		surface.generate_normals()
		surface.commit(mesh)
	for i in 5:
		mesh.surface_set_material(i, [soil, rock, leaf, light, spring][i])

	var physical := ArrayMesh.new()
	ground.commit(physical)
	stones.commit(physical)
	var collision := physical.create_trimesh_shape()
	collision.backface_collision = true
	ResourceSaver.save(mesh, "res://scenes/world/nature_trail_mesh.res")
	ResourceSaver.save(collision, "res://scenes/world/nature_trail_col.res")
	print("Saved nature_trail_mesh.res and nature_trail_col.res")


func _trail_stone(stones: ToolMeshBuilder, at: Vector3, radius: Vector2, height: float, seed: float) -> void:
	const SIDES := 8
	var top := PackedVector3Array()
	var edge := PackedVector3Array()
	for i in SIDES:
		var angle := float(i) * TAU / SIDES
		var r := 0.91 + 0.13 * sin(seed + i * 3.1)
		var flat := Vector3(cos(angle + seed) * radius.x, 0, sin(angle + seed) * radius.y) * r
		top.append(at + flat * 0.80 + Vector3.UP * (height + 0.012 * sin(i * 2.6 + seed)))
		edge.append(at + flat + Vector3.UP * 0.022)
	var shade := Color(0.38, 0.39, 0.34).lerp(Color(0.48, 0.49, 0.41), 0.5 + 0.5 * sin(seed))
	for i in SIDES:
		var next := (i + 1) % SIDES
		_trail_triangle(stones, at + Vector3.UP * (height + 0.012), top[i], top[next], shade)
		var tint := shade.lerp(Color(0.26, 0.37, 0.15), 0.35 + 0.22 * sin(i * 4.7 + seed))
		_trail_triangle(stones, top[i], edge[i], top[next], tint)
		_trail_triangle(stones, top[next], edge[i], edge[next], tint)


func _trail_fern(plants: ToolMeshBuilder, at: Vector3, yaw: float, size: float) -> void:
	for frond in 6:
		var angle := yaw + frond * TAU / 6.0
		var along := Vector3(cos(angle), 0, sin(angle))
		var cross := along.cross(Vector3.UP)
		var tip := at + along * size + Vector3.UP * size * (0.42 + 0.12 * sin(frond * 2.7))
		var bend := at.lerp(tip, 0.51) + Vector3.UP * size * 0.39
		var green := Color(0.19, 0.35, 0.105).lerp(Color(0.37, 0.51, 0.17), 0.5 + 0.5 * sin(angle * 2.3))
		_trail_triangle(plants, at, bend - cross * 0.025, bend + cross * 0.025, green)
		_trail_triangle(plants, bend - cross * 0.025, tip, bend + cross * 0.025, green)
		for row in 4:
			var t := 0.23 + row * 0.19
			var rib := at.lerp(bend, t).lerp(bend.lerp(tip, t), t)
			for side: float in [-1.0, 1.0]:
				var blade := rib + cross * side * size * (0.29 - row * 0.048) + along * size * 0.13
				_trail_triangle(plants, rib, blade, rib + along * size * 0.15, green.lightened(row * 0.035))


func _build_life_spring(stones: ToolMeshBuilder, plants: ToolMeshBuilder, glow: ToolMeshBuilder, water: ToolMeshBuilder) -> void:
	var center := Vector3(-4.95, 0.024, -35.85)
	var shore := PackedVector3Array()
	for i in 22:
		var theta := float(i) * TAU / 22.0
		var radius := 1.0 + 0.078 * sin(i * 2.1)
		var at := center + Vector3(1.58 * cos(theta), 0, 2.11 * sin(theta)) * radius
		shore.append(at)
		_trail_stone(stones, at - Vector3.UP * 0.014, Vector2(0.29 + 0.10 * absf(sin(i)), 0.42),
			0.12 + 0.07 * absf(cos(i * 2.7)), theta * 0.88)
		if i % 3 == 1:
			_trail_fern(plants, at.lerp(center, -0.19), theta - 0.37, 0.76)
			_build_3d_mushroom(plants, glow, at.lerp(center, -0.17) + Vector3.UP * 0.031,
				0.18, 0.13, Color(0.32, 0.88, 0.78))
	for i in shore.size():
		water.set_color(Color(0.12, 0.27, 0.23))
		var middle := water.add_vertex(center)
		water.set_color(Color(0.20, 0.38, 0.30))
		var a := water.add_vertex(shore[i])
		var b := water.add_vertex(shore[(i + 1) % shore.size()])
		water.add_index(middle)
		water.add_index(a)
		water.add_index(b)
	for i in 3:
		_trail_stone(stones, Vector3(-7.68 + 0.50 * i, 0.01, -36.02 - 0.10 * i),
			Vector2(0.35, 0.29), 0.082, i * 2.12)


func _trail_triangle(builder: ToolMeshBuilder, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	builder.set_color(tint)
	for point in [a, b, c]:
		builder.add_index(builder.add_vertex(point))


# -----------------------------------------------------------------------------
# BAKE BURNING PATH & CHARRED FOREST ZONE
# -----------------------------------------------------------------------------
func _bake_burning_path(spline: Spline3D) -> void:
	print("Baking Burning Path and Charred Zone...")
	var b_charred := ToolMeshBuilder.new()
	var b_embers := ToolMeshBuilder.new()
	var b_timber := ToolMeshBuilder.new()

	var col_faces: Array[Vector3] = []

	var steps: int = 110
	var trans_pts: int = 13
	var base_idx: int = 0
	const GATE_EDGE := -79.75
	var before_gate := 0.0
	var beyond_gate := 1.0
	for i in 16:
		var middle := (before_gate + beyond_gate) * 0.5
		if spline.sample(middle).pos.z > GATE_EDGE:
			before_gate = middle
		else:
			beyond_gate = middle

	# 1. Charred Road & Ash Field Surface
	for i in range(steps + 1):
		var t := before_gate * float(i) / steps
		var f: PathFrame = spline.sample(t)

		var pos: Vector3 = f.pos
		var right: Vector3 = f.right
		var up: Vector3 = f.up

		var approach := 1.0 - smoothstep(-77.5, -67.0, pos.z)
		var total_half_w := lerpf(lerpf(7.5, 12.0, smoothstep(0.0, 0.18, t)), 3.1, approach)
		for j in range(trans_pts):
			var u := -1.0 + 2.0 * float(j) / float(trans_pts - 1)
			var dist := u * total_half_w + pow(absf(u), 2.0) * 1.65 * sin(t * 28.0) * (1.0 - approach)
			var weight := smoothstep(0.60, 1.0, absf(u))
			var ash := 0.5 + 0.5 * sin(t * 151.0 + dist * 3.7) * cos(t * 93.0 - dist * 2.4)
			var col := Color(0.07, 0.058, 0.052).lerp(Color(0.19, 0.169, 0.146), ash)
			var vpos: Vector3 = pos + right * dist
			vpos.z = lerpf(vpos.z, pos.z, approach)
			vpos.y = 0.018
			col.a = (1.0 - weight) * smoothstep(0.0, 0.045, t) * smoothstep(GATE_EDGE, -77.1, vpos.z)
			b_charred.set_color(col)
			b_charred.set_uv(Vector2(u * 0.5 + 0.5, t * 30.0))
			b_charred.set_normal(up)
			b_charred.add_vertex(vpos)

	_connect_tube_grid(b_charred, base_idx, steps + 1, trans_pts, false)

	# Scattered coals sit beside the passage, among the fallen wood.
	const EMBER_PATCHES := 30
	for patch in EMBER_PATCHES:
		var t := 0.06 + 0.88 * (float(patch) / float(EMBER_PATCHES - 1))
		var f: PathFrame = spline.sample(t)
		if f.pos.z < -75.8:
			continue
		var side := -1.0 if patch % 2 == 0 else 1.0
		var edge := f.pos + f.right * side * (3.5 + 0.45 * sin(float(patch) * 1.8)) + f.up * 0.025

		for ember_i in range(3):
			var angle := float(ember_i) * 2.1 + float(patch)
			var ember := edge + Vector3(cos(angle) * 0.52, 0.0, sin(angle) * 0.23)
			_add_ember_rock(b_embers, ember, 0.055 + 0.035 * absf(sin(angle * 2.7)))

	# Real ground-level fallen charred timber & jagged stumps (NO floating sticks!)
	for ti in range(8):
		var t_tree: float = 0.12 + 0.78 * (float(ti) / 7.0)
		var f_tree: PathFrame = spline.sample(t_tree)
		var side: float = 1.0 if (ti % 2 == 0) else -1.0
		var stump_pos: Vector3 = f_tree.pos + f_tree.right * (side * 4.2)
		var log_end: Vector3 = f_tree.pos + f_tree.right * (side * 1.8) + f_tree.tangent * (0.8 * sin(float(ti)))
		# Trunk lying firmly on ground
		_add_cylinder_beam(b_timber, stump_pos + Vector3.UP * 0.25, log_end + Vector3.UP * 0.18, 0.38, 0.24, Color(0.06, 0.05, 0.05))
		# Jagged stump root
		_add_cylinder_beam(b_timber, stump_pos, stump_pos + Vector3.UP * 1.2, 0.44, 0.32, Color(0.05, 0.045, 0.045))

	# Commit Burning Path Mesh & Collisions
	b_charred.generate_normals()
	b_embers.generate_normals()
	b_timber.generate_normals()

	var m_charred := StandardMaterial3D.new()
	m_charred.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_charred.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_charred.vertex_color_use_as_albedo = true
	m_charred.vertex_color_is_srgb = true
	m_charred.roughness = 0.92

	var m_embers := StandardMaterial3D.new()
	m_embers.vertex_color_use_as_albedo = true
	m_embers.vertex_color_is_srgb = true
	m_embers.emission_enabled = true
	m_embers.emission = Color(1.0, 0.24, 0.035)
	m_embers.emission_energy_multiplier = 1.65

	var m_timber := StandardMaterial3D.new()
	m_timber.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_timber.vertex_color_use_as_albedo = true
	m_timber.vertex_color_is_srgb = true
	m_timber.roughness = 0.96

	var mesh := ArrayMesh.new()
	b_charred.commit(mesh)
	var charred_shape := mesh.create_trimesh_shape()
	if charred_shape:
		col_faces.append_array(charred_shape.get_faces())
	b_embers.commit(mesh)
	b_timber.commit(mesh)

	mesh.surface_set_material(0, m_charred)
	mesh.surface_set_material(1, m_embers)
	mesh.surface_set_material(2, m_timber)

	var col_shape := ConcavePolygonShape3D.new()
	col_shape.backface_collision = true
	col_shape.set_faces(PackedVector3Array(col_faces))

	ResourceSaver.save(mesh, "res://scenes/world/burning_path_mesh.res")
	ResourceSaver.save(col_shape, "res://scenes/world/burning_path_col.res")
	print("Saved burning_path_mesh.res and burning_path_col.res")


# -----------------------------------------------------------------------------
# Detailed 3D Procedural Helpers
# -----------------------------------------------------------------------------
func _build_3d_mushroom(b_ground: ToolMeshBuilder, b_bio: ToolMeshBuilder, base: Vector3, h: float, rad: float, glow_col: Color) -> void:
	var stalk_segs: int = 5
	var stalk_r: float = 0.035
	var s_base: int = b_ground.vert_count
	for i in range(2):
		var y_off: float = float(i) * h
		for s in range(stalk_segs):
			var a: float = float(s) * TAU / float(stalk_segs)
			var v: Vector3 = base + Vector3(cos(a) * stalk_r, y_off, sin(a) * stalk_r)
			b_ground.set_color(Color(0.48, 0.62, 0.44))
			b_ground.add_vertex(v)
	_connect_tube_grid(b_ground, s_base, 2, stalk_segs, true)

	var cap_apex: Vector3 = base + Vector3.UP * (h + rad * 0.65)
	var cap_segs: int = 8
	var cap_pts: Array[Vector3] = []
	for s in range(cap_segs):
		var a: float = float(s) * TAU / float(cap_segs)
		var p: Vector3 = base + Vector3(cos(a) * rad, h, sin(a) * rad)
		cap_pts.append(p)

	for s in range(cap_segs):
		var s_next: int = (s + 1) % cap_segs
		b_bio.set_color(glow_col)
		var va: int = b_bio.add_vertex(cap_apex)
		var v0: int = b_bio.add_vertex(cap_pts[s])
		var v1: int = b_bio.add_vertex(cap_pts[s_next])
		b_bio.add_index(va); b_bio.add_index(v0); b_bio.add_index(v1)


func _add_cylinder_beam(b: ToolMeshBuilder, start: Vector3, end: Vector3, r0: float, r1: float, color: Color) -> void:
	var segs: int = 6
	var dir: Vector3 = (end - start).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	var up: Vector3 = right.cross(dir).normalized()

	var vbase: int = b.vert_count
	for i in range(2):
		var p: Vector3 = start if i == 0 else end
		var r: float = r0 if i == 0 else r1
		for s in range(segs):
			var a: float = float(s) * TAU / float(segs)
			var n: Vector3 = (right * cos(a) + up * sin(a)).normalized()
			var v: Vector3 = p + n * r
			b.set_color(color)
			b.set_normal(n)
			b.add_vertex(v)
	_connect_tube_grid(b, vbase, 2, segs, true)


func _add_ember_rock(b: ToolMeshBuilder, pos: Vector3, rad: float) -> void:
	var segs: int = 5
	var top: Vector3 = pos + Vector3.UP * rad
	var ring: Array[Vector3] = []
	for s in range(segs):
		var a: float = float(s) * TAU / float(segs)
		ring.append(pos + Vector3(cos(a) * rad, 0.01, sin(a) * rad))

	for s in range(segs):
		var s_next: int = (s + 1) % segs
		b.set_color(Color(1.0, 0.45, 0.08))
		b.set_normal(Vector3.UP)
		var vt: int = b.add_vertex(top)
		var v0: int = b.add_vertex(ring[s])
		var v1: int = b.add_vertex(ring[s_next])
		b.add_index(vt); b.add_index(v0); b.add_index(v1)
