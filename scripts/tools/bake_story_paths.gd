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
func _bake_nature_trail(spline: Spline3D) -> void:
	print("Baking Nature Trail...")
	var b_ground := ToolMeshBuilder.new()
	var b_foliage := ToolMeshBuilder.new()
	var b_biolum := ToolMeshBuilder.new()

	var col_faces: Array[Vector3] = []

	var steps: int = 90
	var trans_pts: int = 11
	var base_idx: int = 0

	# 1. Main Road Surface
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var f: PathFrame = spline.sample(t)

		var half_w: float = 2.2
		if t > 0.68:
			var pt: float = (t - 0.68) / 0.32
			half_w = lerpf(2.2, 5.4, pt * pt)

		var pos: Vector3 = f.pos
		var right: Vector3 = f.right
		var up: Vector3 = f.up

		for j in range(trans_pts):
			var u: float = -1.0 + 2.0 * float(j) / float(trans_pts - 1)
			var abs_u: float = absf(u)

			var h: float = lerpf(0.08, 0.01, pow(abs_u, 1.8))
			if t < 0.06:
				h = lerpf(0.02, h, t / 0.06)

			var vpos: Vector3 = pos + right * (u * half_w) + up * h

			var col: Color = Color(0.25, 0.17, 0.12)
			if abs_u < 0.60:
				var m_mix: float = 1.0 - (abs_u / 0.60)
				col = col.lerp(Color(0.24, 0.54, 0.22), m_mix).lerp(Color(0.32, 0.68, 0.28), m_mix * 0.4)
			elif abs_u > 0.85:
				col = Color(0.18, 0.13, 0.09)

			if t < 0.05:
				col = Color(0.24, 0.44, 0.18).lerp(col, t / 0.05)

			b_ground.set_color(col)
			b_ground.set_uv(Vector2(u * 0.5 + 0.5, t * 24.0))
			b_ground.set_normal(up)
			b_ground.add_vertex(vpos)

	_connect_tube_grid(b_ground, base_idx, steps + 1, trans_pts, false)

	# Stepping Stones
	var stone_count: int = 24
	for s in range(stone_count):
		var st_t: float = 0.05 + 0.86 * (float(s) / float(stone_count - 1))
		var f: PathFrame = spline.sample(st_t)
		var jitter_u: float = sin(float(s) * 4.31) * 0.75
		var center: Vector3 = f.pos + f.right * jitter_u
		var top_y: float = 0.13 + 0.02 * cos(float(s) * 1.7)
		var stone_rad: float = 0.58 + 0.12 * cos(float(s) * 2.3)
		var stone_segs: int = 9

		var top_pts: Array[Vector3] = []
		var bot_pts: Array[Vector3] = []

		for si in range(stone_segs):
			var ang: float = float(si) * TAU / float(stone_segs)
			var r_j: float = stone_rad * (0.88 + 0.12 * sin(ang * 3.0 + float(s)))
			var off_v := f.right * (cos(ang) * r_j) + f.tangent * (sin(ang) * r_j)
			top_pts.append(center + off_v + f.up * top_y)
			bot_pts.append(center + off_v + f.up * 0.01)

		var top_center_v := center + f.up * (top_y + 0.01)
		var stone_col: Color = Color(0.40, 0.42, 0.39).lerp(Color(0.28, 0.45, 0.25), 0.25)
		var side_col: Color = Color(0.26, 0.27, 0.25)

		for si in range(stone_segs):
			var s_next: int = (si + 1) % stone_segs

			b_ground.set_color(stone_col)
			b_ground.set_normal(f.up)
			var c_idx: int = b_ground.add_vertex(top_center_v)
			var t0_idx: int = b_ground.add_vertex(top_pts[si])
			var t1_idx: int = b_ground.add_vertex(top_pts[s_next])
			b_ground.add_index(c_idx); b_ground.add_index(t0_idx); b_ground.add_index(t1_idx)

			b_ground.set_color(side_col)
			var side_norm: Vector3 = ((top_pts[si] + top_pts[s_next]) * 0.5 - center).normalized()
			b_ground.set_normal(side_norm)
			var st0: int = b_ground.add_vertex(top_pts[si])
			var sb0: int = b_ground.add_vertex(bot_pts[si])
			var st1: int = b_ground.add_vertex(top_pts[s_next])
			var sb1: int = b_ground.add_vertex(bot_pts[s_next])
			b_ground.add_index(st0); b_ground.add_index(sb0); b_ground.add_index(st1)
			b_ground.add_index(st1); b_ground.add_index(sb0); b_ground.add_index(sb1)

	# Approach Plaza round stone pavement cap at end (center (-17.3, 0.0, -56.8))
	var plaza_center: Vector3 = Vector3(-17.3, 0.06, -56.8)
	var plaza_segs: int = 24
	var plaza_rad: float = 5.2
	for ring in range(3):
		var r_in: float = float(ring) * (plaza_rad / 3.0)
		var r_out: float = float(ring + 1) * (plaza_rad / 3.0)
		for si in range(plaza_segs):
			var a0: float = float(si) * TAU / float(plaza_segs)
			var a1: float = float(si + 1) * TAU / float(plaza_segs)

			var p0: Vector3 = plaza_center + Vector3(cos(a0), 0, sin(a0)) * r_in
			var p1: Vector3 = plaza_center + Vector3(cos(a1), 0, sin(a1)) * r_in
			var p2: Vector3 = plaza_center + Vector3(cos(a0), 0, sin(a0)) * r_out
			var p3: Vector3 = plaza_center + Vector3(cos(a1), 0, sin(a1)) * r_out

			var c: Color = Color(0.30, 0.48, 0.26) if ring < 2 else Color(0.24, 0.32, 0.20)
			b_ground.set_color(c)
			b_ground.set_normal(Vector3.UP)
			var i0: int = b_ground.add_vertex(p0)
			var i1: int = b_ground.add_vertex(p1)
			var i2: int = b_ground.add_vertex(p2)
			var i3: int = b_ground.add_vertex(p3)

			b_ground.add_index(i0); b_ground.add_index(i2); b_ground.add_index(i1)
			b_ground.add_index(i1); b_ground.add_index(i2); b_ground.add_index(i3)

	# Fern Clusters
	var fern_count: int = 40
	for fc in range(fern_count):
		var t: float = 0.05 + 0.88 * (float(fc) / float(fern_count - 1))
		var f: PathFrame = spline.sample(t)
		var side: float = -1.0 if (fc % 2 == 0) else 1.0
		var half_w: float = 2.2 if t <= 0.68 else lerpf(2.2, 5.4, pow((t - 0.68) / 0.32, 2.0))
		var base_p: Vector3 = f.pos + f.right * (side * (half_w + 0.40)) + f.up * 0.04

		for frond in range(5):
			var a: float = float(frond) * 0.6 + (0.3 if side < 0 else -0.3)
			var frond_dir: Vector3 = (f.right * side * cos(a) + f.tangent * sin(a)).normalized()
			var tip: Vector3 = base_p + frond_dir * 0.95 + f.up * 0.45
			var mid_l: Vector3 = base_p + frond_dir * 0.50 + f.right * 0.22 + f.up * 0.26
			var mid_r: Vector3 = base_p + frond_dir * 0.50 - f.right * 0.22 + f.up * 0.26

			b_foliage.set_color(Color(0.24, 0.43, 0.18))
			b_foliage.set_normal(f.up)
			var v0: int = b_foliage.add_vertex(base_p)
			var v1: int = b_foliage.add_vertex(mid_l)
			var v2: int = b_foliage.add_vertex(mid_r)
			var v3: int = b_foliage.add_vertex(tip)

			b_foliage.add_index(v0); b_foliage.add_index(v1); b_foliage.add_index(v2)
			b_foliage.add_index(v1); b_foliage.add_index(v3); b_foliage.add_index(v2)

	# Bioluminescent 3D Spore Mushrooms firmly rooted in ground/roots
	var shroom_count: int = 50
	for sc in range(shroom_count):
		var t: float = 0.07 + 0.84 * (float(sc) / float(shroom_count - 1))
		var f: PathFrame = spline.sample(t)
		var side: float = -1.0 if (sc % 2 == 0) else 1.0
		var half_w: float = 2.2 if t <= 0.68 else lerpf(2.2, 5.4, pow((t - 0.68) / 0.32, 2.0))
		var sh_base: Vector3 = f.pos + f.right * (side * (half_w + 0.25)) + f.up * 0.04
		var sh_h: float = 0.15 + 0.06 * sin(float(sc) * 2.8)
		var sh_rad: float = 0.12 + 0.04 * cos(float(sc) * 3.4)

		_build_3d_mushroom(b_ground, b_biolum, sh_base, sh_h, sh_rad, Color(0.30, 0.95, 0.75))

	# Commit Nature Trail Mesh & Collisions
	b_ground.generate_normals()
	b_foliage.generate_normals()
	b_biolum.generate_normals()

	var m_ground := StandardMaterial3D.new()
	m_ground.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_ground.vertex_color_use_as_albedo = true
	m_ground.vertex_color_is_srgb = true
	m_ground.roughness = 0.88

	var m_foliage := StandardMaterial3D.new()
	m_foliage.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_foliage.vertex_color_use_as_albedo = true
	m_foliage.vertex_color_is_srgb = true
	m_foliage.roughness = 0.75

	var m_biolum := StandardMaterial3D.new()
	m_biolum.vertex_color_use_as_albedo = true
	m_biolum.vertex_color_is_srgb = true
	m_biolum.emission_enabled = true
	m_biolum.emission = Color(0.30, 0.95, 0.75)
	m_biolum.emission_energy_multiplier = 2.4

	var mesh := ArrayMesh.new()
	b_ground.commit(mesh)
	var ground_shape := mesh.create_trimesh_shape()
	if ground_shape:
		col_faces.append_array(ground_shape.get_faces())
	b_foliage.commit(mesh)
	b_biolum.commit(mesh)

	mesh.surface_set_material(0, m_ground)
	mesh.surface_set_material(1, m_foliage)
	mesh.surface_set_material(2, m_biolum)

	var col_shape := ConcavePolygonShape3D.new()
	col_shape.backface_collision = true
	col_shape.set_faces(PackedVector3Array(col_faces))

	ResourceSaver.save(mesh, "res://scenes/world/nature_trail_mesh.res")
	ResourceSaver.save(col_shape, "res://scenes/world/nature_trail_col.res")
	print("Saved nature_trail_mesh.res and nature_trail_col.res")


# -----------------------------------------------------------------------------
# BAKE BURNING PATH & CHARRED FOREST ZONE
# -----------------------------------------------------------------------------
func _bake_burning_path(spline: Spline3D) -> void:
	print("Baking Burning Path and Charred Zone...")
	var b_charred := ToolMeshBuilder.new()
	var b_lava := ToolMeshBuilder.new()
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

	# Lava Fissures & Solid Ground Embers
	var crack_count: int = 30
	for cc in range(crack_count):
		var t: float = 0.06 + 0.88 * (float(cc) / float(crack_count - 1))
		var f: PathFrame = spline.sample(t)
		if f.pos.z < -75.8:
			continue
		var side: float = -1.0 if (cc % 2 == 0) else 1.0
		var crack_pos: Vector3 = f.pos + f.right * (side * 3.4) + f.up * 0.04
		var crack_len: float = 2.4 + 0.6 * sin(float(cc) * 1.8)

		var c_p0: Vector3 = crack_pos - f.tangent * (crack_len * 0.5)
		var c_p1: Vector3 = crack_pos + f.tangent * (crack_len * 0.5)
		var c_mid: Vector3 = crack_pos + f.right * (0.35 * sin(float(cc) * 3.1))

		b_lava.set_color(Color(1.0, 0.65, 0.12))
		b_lava.set_normal(f.up)
		var vm: int = b_lava.add_vertex(c_mid + f.up * 0.02)
		b_lava.set_color(Color(0.85, 0.25, 0.02))
		var vp0: int = b_lava.add_vertex(c_p0 + f.up * 0.01)
		var vp1: int = b_lava.add_vertex(c_p1 + f.up * 0.01)
		b_lava.add_index(vm); b_lava.add_index(vp0); b_lava.add_index(vp1)

		for ember_i in range(3):
			var a: float = float(ember_i) * 2.1 + float(cc)
			var ep: Vector3 = crack_pos + Vector3(cos(a) * 0.35, 0.02, sin(a) * 0.35)
			_add_ember_rock(b_lava, ep, 0.10)

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
	b_lava.generate_normals()
	b_timber.generate_normals()

	var m_charred := StandardMaterial3D.new()
	m_charred.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_charred.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_charred.vertex_color_use_as_albedo = true
	m_charred.vertex_color_is_srgb = true
	m_charred.roughness = 0.92

	var m_lava := StandardMaterial3D.new()
	m_lava.vertex_color_use_as_albedo = true
	m_lava.vertex_color_is_srgb = true
	m_lava.emission_enabled = true
	m_lava.emission = Color(1.0, 0.38, 0.06)
	m_lava.emission_energy_multiplier = 3.2

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
	b_lava.commit(mesh)
	b_timber.commit(mesh)

	mesh.surface_set_material(0, m_charred)
	mesh.surface_set_material(1, m_lava)
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
			b_ground.set_normal(Vector3(cos(a), 0, sin(a)))
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
		b_bio.set_normal(Vector3.UP)
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
