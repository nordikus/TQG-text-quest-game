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
func _init() -> void:
	print("--- Starting Story Paths Baker ---")

	var nature_spline := Spline3D.new([
		Vector3(-4.5, 0.0, -17.5),
		Vector3(-6.2, 0.0, -25.0),
		Vector3(-9.0, 0.0, -35.5),
		Vector3(-13.8, 0.0, -47.5),
		Vector3(-17.3, 0.0, -56.8)
	])

	var burning_spline := Spline3D.new([
		Vector3(13.5, 0.0, -8.5),
		Vector3(16.2, 0.0, -21.0),
		Vector3(15.2, 0.0, -41.0),
		Vector3(8.5, 0.15, -60.0),
		Vector3(2.5, 2.1, -72.0),
		Vector3(0.0, 4.02, -82.5)
	])

	_bake_nature_trail(nature_spline)
	_bake_burning_path(burning_spline)

	print("--- Story Paths Baking Finished Successfully ---")
	quit(0)


# -----------------------------------------------------------------------------
# Helper: Connect grid of vertices into triangles
# -----------------------------------------------------------------------------
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

	var steps: int = 80
	var trans_pts: int = 9
	var base_idx: int = 0

	# 1. Road Surface & Stepping Stones
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var f: PathFrame = spline.sample(t)

		var half_w: float = 2.1
		if t > 0.7:
			var pt: float = (t - 0.7) / 0.3
			half_w = lerpf(2.1, 5.2, pt * pt)

		var pos: Vector3 = f.pos
		var right: Vector3 = f.right
		var up: Vector3 = f.up

		for j in range(trans_pts):
			var u: float = -1.0 + 2.0 * float(j) / float(trans_pts - 1)
			var abs_u: float = absf(u)
			var crown: float = (1.0 - abs_u * abs_u) * 0.06
			var edge_dip: float = -0.06 * pow(abs_u, 3.0)
			var h: float = crown + edge_dip

			# Feather start and end into terrain
			if t < 0.06:
				h *= (t / 0.06)
			elif t > 0.88:
				h *= (1.0 - (t - 0.88) / 0.12 * 0.6)

			var vpos: Vector3 = pos + right * (u * half_w) + up * h

			var col: Color = Color(0.22, 0.16, 0.11)
			if abs_u < 0.55:
				var moss_mix: float = (1.0 - abs_u * 1.8)
				col = col.lerp(Color(0.24, 0.52, 0.20), moss_mix * 0.9)
			elif abs_u > 0.85:
				col = Color(0.16, 0.12, 0.08)

			# Feather start color into clearing grass
			if t < 0.05:
				var f_blend: float = (t / 0.05)
				col = Color(0.22, 0.42, 0.20).lerp(col, f_blend)

			b_ground.set_color(col)
			b_ground.set_uv(Vector2(u * 0.5 + 0.5, t * 24.0))
			b_ground.set_normal(up)
			b_ground.add_vertex(vpos)

	_connect_tube_grid(b_ground, base_idx, steps + 1, trans_pts, false)

	# Stepping stones along the Nature Trail
	var stone_count: int = 22
	for s in range(stone_count):
		var st_t: float = 0.04 + 0.88 * (float(s) / float(stone_count - 1))
		var f: PathFrame = spline.sample(st_t)
		var jitter_u: float = sin(float(s) * 4.31) * 0.75
		var center: Vector3 = f.pos + f.right * jitter_u + f.up * 0.05
		var stone_rad: float = 0.55 + 0.15 * cos(float(s) * 2.1)
		var stone_segs: int = 8

		var top_pts: Array[Vector3] = []
		var bot_pts: Array[Vector3] = []
		for si in range(stone_segs):
			var ang: float = float(si) * TAU / float(stone_segs)
			var rad_j: float = stone_rad * (0.88 + 0.12 * sin(ang * 3.0))
			var l_x: float = cos(ang) * rad_j
			var l_z: float = sin(ang) * rad_j
			var p_top: Vector3 = center + f.right * l_x + f.tangent * l_z + f.up * 0.04
			var p_bot: Vector3 = center + f.right * l_x + f.tangent * l_z - f.up * 0.04
			top_pts.append(p_top)
			bot_pts.append(p_bot)

		var stone_col: Color = Color(0.38, 0.40, 0.38)
		for si in range(stone_segs):
			var s_next: int = (si + 1) % stone_segs
			# Top fan
			b_ground.set_color(stone_col)
			b_ground.set_normal(f.up)
			var c_idx: int = b_ground.add_vertex(center + f.up * 0.05)
			var t0_idx: int = b_ground.add_vertex(top_pts[si])
			var t1_idx: int = b_ground.add_vertex(top_pts[s_next])
			b_ground.add_index(c_idx); b_ground.add_index(t0_idx); b_ground.add_index(t1_idx)

			# Sides
			var side_col: Color = Color(0.28, 0.30, 0.28)
			b_ground.set_color(side_col)
			var side_n: Vector3 = (top_pts[si] - center).normalized()
			b_ground.set_normal(side_n)

			var s_t0: int = b_ground.add_vertex(top_pts[si])
			var s_b0: int = b_ground.add_vertex(bot_pts[si])
			var s_t1: int = b_ground.add_vertex(top_pts[s_next])
			var s_b1: int = b_ground.add_vertex(bot_pts[s_next])

			b_ground.add_index(s_t0); b_ground.add_index(s_b0); b_ground.add_index(s_t1)
			b_ground.add_index(s_t1); b_ground.add_index(s_b0); b_ground.add_index(s_b1)

	# Approach Plaza round stone pavement cap at end (center (-17.3, 0.0, -56.8))
	var plaza_center: Vector3 = Vector3(-17.3, 0.03, -56.8)
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

			var c: Color = Color(0.26, 0.45, 0.22) if ring < 2 else Color(0.22, 0.28, 0.18)
			b_ground.set_color(c)
			b_ground.set_normal(Vector3.UP)
			var i0: int = b_ground.add_vertex(p0)
			var i1: int = b_ground.add_vertex(p1)
			var i2: int = b_ground.add_vertex(p2)
			var i3: int = b_ground.add_vertex(p3)

			b_ground.add_index(i0); b_ground.add_index(i2); b_ground.add_index(i1)
			b_ground.add_index(i1); b_ground.add_index(i2); b_ground.add_index(i3)

	# Living Root Borders (left & right undulations)
	for side in [-1.0, 1.0]:
		var r_steps: int = 60
		var r_circ: int = 6
		var r_grid_base: int = b_ground.vert_count

		for rs in range(r_steps + 1):
			var t: float = float(rs) / float(r_steps)
			var f: PathFrame = spline.sample(t)
			var half_w: float = 2.1
			if t > 0.7:
				half_w = lerpf(2.1, 5.2, pow((t - 0.7) / 0.3, 2.0))

			var undulate: float = sin(t * TAU * 4.5 + (0.5 if side > 0 else 0.0))
			var root_h: float = maxf(-0.15, 0.12 + 0.28 * undulate)
			var root_r: float = 0.18 + 0.08 * undulate
			var c_pos: Vector3 = f.pos + f.right * (side * (half_w + 0.25)) + f.up * root_h

			for ci in range(r_circ):
				var ca: float = float(ci) * TAU / float(r_circ)
				var cp: Vector3 = c_pos + (f.right * cos(ca) + f.up * sin(ca)) * root_r
				var cn: Vector3 = (f.right * cos(ca) + f.up * sin(ca)).normalized()

				var r_col: Color = Color(0.28, 0.18, 0.11)
				if cn.y > 0.3:
					r_col = r_col.lerp(Color(0.25, 0.42, 0.18), 0.6)
				b_ground.set_color(r_col)
				b_ground.set_normal(cn)
				b_ground.add_vertex(cp)

		_connect_tube_grid(b_ground, r_grid_base, r_steps + 1, r_circ, true)

	# 2. Foliage Surface: Ferns along borders & 3 Living Arches
	var fern_count: int = 36
	for fc in range(fern_count):
		var t: float = 0.05 + 0.88 * (float(fc) / float(fern_count - 1))
		var f: PathFrame = spline.sample(t)
		var side: float = -1.0 if (fc % 2 == 0) else 1.0
		var half_w: float = 2.1
		if t > 0.7:
			half_w = lerpf(2.1, 5.2, pow((t - 0.7) / 0.3, 2.0))
		var base_p: Vector3 = f.pos + f.right * (side * (half_w + 0.35)) + f.up * 0.02

		for frond in range(4):
			var a: float = float(frond) * 0.7 + (0.3 if side < 0 else -0.3)
			var frond_dir: Vector3 = (f.right * side * cos(a) + f.tangent * sin(a)).normalized()
			var tip: Vector3 = base_p + frond_dir * 0.85 + f.up * 0.45
			var mid_left: Vector3 = base_p + frond_dir * 0.45 + f.right * 0.2 + f.up * 0.25
			var mid_right: Vector3 = base_p + frond_dir * 0.45 - f.right * 0.2 + f.up * 0.25

			b_foliage.set_color(Color(0.20, 0.55, 0.18))
			b_foliage.set_normal(f.up)
			var v0: int = b_foliage.add_vertex(base_p)
			var v1: int = b_foliage.add_vertex(mid_left)
			var v2: int = b_foliage.add_vertex(mid_right)
			var v3: int = b_foliage.add_vertex(tip)

			b_foliage.add_index(v0); b_foliage.add_index(v1); b_foliage.add_index(v2)
			b_foliage.add_index(v1); b_foliage.add_index(v3); b_foliage.add_index(v2)

	# 3 Living Arches at t = 0.25, 0.55, 0.82
	var arch_ts: Array[float] = [0.25, 0.55, 0.82]
	for at in arch_ts:
		var f: PathFrame = spline.sample(at)
		var arch_segs: int = 16
		var arch_circ: int = 6
		var arch_w: float = 2.2
		var arch_h: float = 4.3

		var arch_vbase: int = b_foliage.vert_count
		for asg in range(arch_segs + 1):
			var sa: float = float(asg) / float(arch_segs)
			var ang: float = sa * PI
			var u_pos: float = cos(ang) * arch_w
			var v_h: float = sin(ang) * arch_h
			var center_p: Vector3 = f.pos + f.right * u_pos + f.up * v_h
			var rad: float = 0.16 * (1.0 - 0.4 * sin(ang))

			for ac in range(arch_circ):
				var ca: float = float(ac) * TAU / float(arch_circ)
				var norm: Vector3 = (f.right * cos(ca) + f.tangent * sin(ca)).normalized()
				var v: Vector3 = center_p + (f.right * cos(ca) + f.tangent * sin(ca)) * rad
				b_foliage.set_color(Color(0.26, 0.18, 0.12))
				b_foliage.set_normal(norm)
				b_foliage.add_vertex(v)

		_connect_tube_grid(b_foliage, arch_vbase, arch_segs + 1, arch_circ, true)

		# Foliage canopy cluster at apex of arch
		var apex_center: Vector3 = f.pos + f.up * arch_h
		for cl in range(6):
			var cl_off: Vector3 = Vector3(sin(float(cl) * 1.5) * 0.7, cos(float(cl) * 2.1) * 0.35, sin(float(cl) * 3.2) * 0.7)
			var cl_pos: Vector3 = apex_center + cl_off
			var cl_rad: float = 0.75 + 0.2 * sin(float(cl))
			_add_foliage_puff(b_foliage, cl_pos, cl_rad, Color(0.22, 0.58, 0.20))

	# 3. Bioluminescent Mushrooms & Spores
	var shroom_count: int = 45
	for sc in range(shroom_count):
		var t: float = 0.08 + 0.82 * (float(sc) / float(shroom_count - 1))
		var f: PathFrame = spline.sample(t)
		var side: float = -1.0 if (sc % 2 == 0) else 1.0
		var half_w: float = 2.1
		if t > 0.7:
			half_w = lerpf(2.1, 5.2, pow((t - 0.7) / 0.3, 2.0))

		var sh_pos: Vector3 = f.pos + f.right * (side * (half_w + 0.15)) + f.up * 0.15
		var sh_rad: float = 0.12 + 0.06 * sin(float(sc) * 3.5)
		_add_mushroom_cap(b_biolum, sh_pos, sh_rad, Color(0.30, 0.95, 0.75))

	# 4. Generate Collision Geometry for Nature Trail
	for i in range(steps):
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var f0: PathFrame = spline.sample(t0)
		var f1: PathFrame = spline.sample(t1)

		var w0: float = 2.2 if t0 < 0.7 else lerpf(2.2, 5.2, pow((t0 - 0.7) / 0.3, 2.0))
		var w1: float = 2.2 if t1 < 0.7 else lerpf(2.2, 5.2, pow((t1 - 0.7) / 0.3, 2.0))

		var l0: Vector3 = f0.pos - f0.right * w0
		var r0: Vector3 = f0.pos + f0.right * w0
		var l1: Vector3 = f1.pos - f1.right * w1
		var r1: Vector3 = f1.pos + f1.right * w1

		# Walkable floor
		col_faces.append(l0); col_faces.append(l1); col_faces.append(r0)
		col_faces.append(r0); col_faces.append(l1); col_faces.append(r1)

		# Left guide wall (height 1.6m)
		var l0_top: Vector3 = l0 + Vector3.UP * 1.6
		var l1_top: Vector3 = l1 + Vector3.UP * 1.6
		col_faces.append(l0); col_faces.append(l0_top); col_faces.append(l1)
		col_faces.append(l1); col_faces.append(l0_top); col_faces.append(l1_top)

		# Right guide wall (height 1.6m)
		var r0_top: Vector3 = r0 + Vector3.UP * 1.6
		var r1_top: Vector3 = r1 + Vector3.UP * 1.6
		col_faces.append(r0); col_faces.append(r1); col_faces.append(r0_top)
		col_faces.append(r1); col_faces.append(r1_top); col_faces.append(r0_top)

	# Commit Nature Trail Mesh
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
	m_biolum.emission_energy_multiplier = 2.2

	var mesh := ArrayMesh.new()
	b_ground.commit(mesh)
	b_foliage.commit(mesh)
	b_biolum.commit(mesh)

	mesh.surface_set_material(0, m_ground)
	mesh.surface_set_material(1, m_foliage)
	mesh.surface_set_material(2, m_biolum)

	var col_shape := ConcavePolygonShape3D.new()
	var packed_col_faces := PackedVector3Array(col_faces)
	col_shape.set_faces(packed_col_faces)

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
	var b_debris := ToolMeshBuilder.new()

	var col_faces: Array[Vector3] = []

	var steps: int = 100
	var trans_pts: int = 13
	var base_idx: int = 0

	# 1. Charred Road & Ash Field Surface
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var f: PathFrame = spline.sample(t)

		var pos: Vector3 = f.pos
		var right: Vector3 = f.right
		var up: Vector3 = f.up

		var total_half_w: float = 7.0
		var core_half_w: float = 2.5

		for j in range(trans_pts):
			var u_norm: float = -1.0 + 2.0 * float(j) / float(trans_pts - 1)
			var dist: float = u_norm * total_half_w
			var abs_d: float = absf(dist)

			var h: float = 0.0
			var col: Color = Color(0.04, 0.04, 0.04)

			if abs_d <= core_half_w:
				var rut: float = 0.06 + 0.03 * cos(abs_d * 2.5)
				h = rut
				col = Color(0.04, 0.035, 0.03)
				if abs_d < 1.2:
					col = Color(0.055, 0.048, 0.042)
			else:
				var flank_factor: float = (abs_d - core_half_w) / (total_half_w - core_half_w)
				var mound: float = 0.05 + sin(flank_factor * PI) * (0.22 + 0.12 * sin(t * 30.0 + dist))
				h = mound
				col = Color(0.05, 0.04, 0.035).lerp(Color(0.02, 0.02, 0.02), flank_factor)

			# Feather start into clearing ground
			if t < 0.05:
				h *= (t / 0.05)

			var vpos: Vector3 = pos + right * dist + up * h
			b_charred.set_color(col)
			b_charred.set_uv(Vector2(u_norm * 0.5 + 0.5, t * 30.0))
			b_charred.set_normal(up)
			b_charred.add_vertex(vpos)

	_connect_tube_grid(b_charred, base_idx, steps + 1, trans_pts, false)

	# Broken flagstone ramp steps on the castle approach (Z = -60 to -82.5, t approx 0.65 to 1.0)
	var ramp_steps: int = 18
	for rs in range(ramp_steps):
		var t: float = 0.65 + 0.34 * (float(rs) / float(ramp_steps - 1))
		var f: PathFrame = spline.sample(t)
		var slab_w: float = 4.4
		var slab_l: float = 1.1
		var slab_h: float = 0.06

		var p0: Vector3 = f.pos - f.right * (slab_w * 0.5) - f.tangent * (slab_l * 0.5) + f.up * slab_h
		var p1: Vector3 = f.pos + f.right * (slab_w * 0.5) - f.tangent * (slab_l * 0.5) + f.up * slab_h
		var p2: Vector3 = f.pos - f.right * (slab_w * 0.5) + f.tangent * (slab_l * 0.5) + f.up * slab_h
		var p3: Vector3 = f.pos + f.right * (slab_w * 0.5) + f.tangent * (slab_l * 0.5) + f.up * slab_h

		var slab_col: Color = Color(0.22, 0.22, 0.24)
		b_charred.set_color(slab_col)
		b_charred.set_normal(f.up)
		var v0: int = b_charred.add_vertex(p0)
		var v1: int = b_charred.add_vertex(p1)
		var v2: int = b_charred.add_vertex(p2)
		var v3: int = b_charred.add_vertex(p3)

		b_charred.add_index(v0); b_charred.add_index(v2); b_charred.add_index(v1)
		b_charred.add_index(v1); b_charred.add_index(v2); b_charred.add_index(v3)

	# 2. Glowing Lava Cracks & Coals
	var crack_count: int = 28
	for cc in range(crack_count):
		var t: float = 0.05 + 0.90 * (float(cc) / float(crack_count - 1))
		var f: PathFrame = spline.sample(t)
		var side: float = -1.0 if (cc % 2 == 0) else 1.0
		var crack_pos: Vector3 = f.pos + f.right * (side * 2.4) - f.up * 0.03
		var crack_len: float = 2.2 + 0.6 * sin(float(cc) * 1.8)

		var c_p0: Vector3 = crack_pos - f.tangent * (crack_len * 0.5)
		var c_p1: Vector3 = crack_pos + f.tangent * (crack_len * 0.5)
		var c_mid: Vector3 = crack_pos + f.right * (0.35 * sin(float(cc) * 3.1)) - f.up * 0.05

		# Ember glow triangles
		b_lava.set_color(Color(1.0, 0.72, 0.15))
		b_lava.set_normal(f.up)
		var vm: int = b_lava.add_vertex(c_mid)
		b_lava.set_color(Color(0.85, 0.25, 0.02))
		var vp0: int = b_lava.add_vertex(c_p0)
		var vp1: int = b_lava.add_vertex(c_p1)
		b_lava.add_index(vm); b_lava.add_index(vp0); b_lava.add_index(vp1)

		# Coal mounds
		var coal_p: Vector3 = crack_pos + f.right * (side * 0.5)
		for cm in range(5):
			var ca: float = float(cm) * TAU / 5.0
			var cp: Vector3 = coal_p + Vector3(cos(ca), 0.1, sin(ca)) * 0.25
			var cp_next: Vector3 = coal_p + Vector3(cos(ca + 1.25), 0.1, sin(ca + 1.25)) * 0.25

			b_lava.set_color(Color(1.0, 0.35, 0.05))
			b_lava.set_normal(f.up)
			var v_apex: int = b_lava.add_vertex(coal_p + Vector3.UP * 0.15)
			var v_c0: int = b_lava.add_vertex(cp)
			var v_c1: int = b_lava.add_vertex(cp_next)
			b_lava.add_index(v_apex); b_lava.add_index(v_c0); b_lava.add_index(v_c1)

	# 3. Charred Debris & Fallen Burned Tree Arches Overhead
	var arch_ts: Array[float] = [0.22, 0.50, 0.78]
	for at in arch_ts:
		var f: PathFrame = spline.sample(at)
		var trunk_r: float = 0.32

		var p_start: Vector3 = f.pos - f.right * 4.5 + f.up * 0.5
		var p_end: Vector3 = f.pos + f.right * 4.5 + f.up * 5.2 + f.tangent * 2.0
		var p_mid: Vector3 = (p_start + p_end) * 0.5 + f.up * 1.2

		_add_cylinder_beam(b_debris, p_start, p_mid, trunk_r, Color(0.06, 0.05, 0.05))
		_add_cylinder_beam(b_debris, p_mid, p_end, trunk_r * 0.7, Color(0.05, 0.05, 0.05))

		var p2_start: Vector3 = f.pos + f.right * 4.2 + f.up * 0.4
		var p2_end: Vector3 = f.pos - f.right * 3.5 + f.up * 5.6 - f.tangent * 1.5
		var p2_mid: Vector3 = (p2_start + p2_end) * 0.5 + f.up * 1.0
		_add_cylinder_beam(b_debris, p2_start, p2_mid, trunk_r * 0.8, Color(0.06, 0.05, 0.05))
		_add_cylinder_beam(b_debris, p2_mid, p2_end, trunk_r * 0.55, Color(0.05, 0.05, 0.05))

	# 4. Generate Collision Geometry for Burning Path
	for i in range(steps):
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var f0: PathFrame = spline.sample(t0)
		var f1: PathFrame = spline.sample(t1)

		var w: float = 2.4

		var l0: Vector3 = f0.pos - f0.right * w
		var r0: Vector3 = f0.pos + f0.right * w
		var l1: Vector3 = f1.pos - f1.right * w
		var r1: Vector3 = f1.pos + f1.right * w

		# Floor
		col_faces.append(l0); col_faces.append(l1); col_faces.append(r0)
		col_faces.append(r0); col_faces.append(l1); col_faces.append(r1)

		# Left guide wall
		var l0_top: Vector3 = l0 + Vector3.UP * 1.8
		var l1_top: Vector3 = l1 + Vector3.UP * 1.8
		col_faces.append(l0); col_faces.append(l0_top); col_faces.append(l1)
		col_faces.append(l1); col_faces.append(l0_top); col_faces.append(l1_top)

		# Right guide wall
		var r0_top: Vector3 = r0 + Vector3.UP * 1.8
		var r1_top: Vector3 = r1 + Vector3.UP * 1.8
		col_faces.append(r0); col_faces.append(r1); col_faces.append(r0_top)
		col_faces.append(r1); col_faces.append(r1_top); col_faces.append(r0_top)

	# Commit Burning Path Mesh
	b_charred.generate_normals()
	b_lava.generate_normals()
	b_debris.generate_normals()

	var m_charred := StandardMaterial3D.new()
	m_charred.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_charred.vertex_color_use_as_albedo = true
	m_charred.vertex_color_is_srgb = true
	m_charred.roughness = 0.92

	var m_lava := StandardMaterial3D.new()
	m_lava.vertex_color_use_as_albedo = true
	m_lava.vertex_color_is_srgb = true
	m_lava.emission_enabled = true
	m_lava.emission = Color(1.0, 0.32, 0.05)
	m_lava.emission_energy_multiplier = 3.2

	var m_debris := StandardMaterial3D.new()
	m_debris.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_debris.vertex_color_use_as_albedo = true
	m_debris.vertex_color_is_srgb = true
	m_debris.roughness = 0.96

	var mesh := ArrayMesh.new()
	b_charred.commit(mesh)
	b_lava.commit(mesh)
	b_debris.commit(mesh)

	mesh.surface_set_material(0, m_charred)
	mesh.surface_set_material(1, m_lava)
	mesh.surface_set_material(2, m_debris)

	var col_shape := ConcavePolygonShape3D.new()
	var packed_col_faces := PackedVector3Array(col_faces)
	col_shape.set_faces(packed_col_faces)

	ResourceSaver.save(mesh, "res://scenes/world/burning_path_mesh.res")
	ResourceSaver.save(col_shape, "res://scenes/world/burning_path_col.res")
	print("Saved burning_path_mesh.res and burning_path_col.res")


# -----------------------------------------------------------------------------
# Common Mesh Helpers
# -----------------------------------------------------------------------------
func _add_foliage_puff(b: ToolMeshBuilder, center: Vector3, radius: float, color: Color) -> void:
	var rings: int = 4
	var ring_pts: int = 6
	var vbase: int = b.vert_count

	for r in range(rings):
		var phi: float = (float(r + 1) / float(rings + 1)) * PI
		var y: float = cos(phi) * radius
		var ring_r: float = sin(phi) * radius
		for p in range(ring_pts):
			var theta: float = float(p) * TAU / float(ring_pts)
			var jitter: float = 1.0 + 0.15 * sin(theta * 3.0 + phi * 2.0)
			var v: Vector3 = center + Vector3(cos(theta) * ring_r * jitter, y * jitter, sin(theta) * ring_r * jitter)
			b.set_color(color)
			b.set_normal((v - center).normalized())
			b.add_vertex(v)

	_connect_tube_grid(b, vbase, rings, ring_pts, true)


func _add_mushroom_cap(b: ToolMeshBuilder, center: Vector3, radius: float, color: Color) -> void:
	var segs: int = 6
	var top_v: Vector3 = center + Vector3.UP * (radius * 0.6)
	var ring_pts: Array[Vector3] = []

	for i in range(segs):
		var a: float = float(i) * TAU / float(segs)
		var p: Vector3 = center + Vector3(cos(a), 0, sin(a)) * radius
		ring_pts.append(p)

	for i in range(segs):
		var i_next: int = (i + 1) % segs
		b.set_color(color)
		b.set_normal(Vector3.UP)
		var v_top: int = b.add_vertex(top_v)
		var v0: int = b.add_vertex(ring_pts[i])
		var v1: int = b.add_vertex(ring_pts[i_next])
		b.add_index(v_top); b.add_index(v0); b.add_index(v1)


func _add_cylinder_beam(b: ToolMeshBuilder, p0: Vector3, p1: Vector3, radius: float, color: Color) -> void:
	var segs: int = 5
	var dir: Vector3 = (p1 - p0).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:
		right = dir.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(dir).normalized()

	var vbase: int = b.vert_count
	for p_idx in [0, 1]:
		var cp: Vector3 = p0 if p_idx == 0 else p1
		for s in range(segs):
			var a: float = float(s) * TAU / float(segs)
			var norm: Vector3 = (right * cos(a) + up * sin(a)).normalized()
			var v: Vector3 = cp + norm * radius
			b.set_color(color)
			b.set_normal(norm)
			b.add_vertex(v)

	_connect_tube_grid(b, vbase, 2, segs, true)
