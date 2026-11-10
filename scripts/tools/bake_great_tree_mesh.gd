@tool
extends SceneTree

const OUT_MESH := "res://scenes/world/great_tree_mesh.res"
const OUT_SHAPE := "res://scenes/world/great_tree_trunk_shape.res"

const SEG := 56
const TRUNK_TOP := 41.0
const CANOPY_FLOOR := 25.5

const PROFILE: Array[Vector2] = [
	Vector2(-1.2, 3.85), Vector2(0.0, 3.45), Vector2(4.0, 3.05),
	Vector2(18.0, 2.80), Vector2(29.0, 2.20), Vector2(37.0, 1.60), Vector2(TRUNK_TOP, 1.10),
]

# Smooth, broad root buttresses integrated directly into the trunk mesh
const ROOTS := [
	[-18.0, 2.8, 4.5, 3.4],
	[92.0, 1.5, 5.0, 2.0],
	[148.0, 2.9, 4.2, 3.2],
	[206.0, 3.4, 4.5, 3.8],
	[258.0, 3.6, 4.2, 4.0],
	[308.0, 3.0, 4.5, 3.5],
]

# [trunk_height, angle_deg, length, rise, base_radius]
const LIMBS := [
	[23.5, 18.0, 10.5, 6.0, 1.25],
	[25.0, 68.0, 9.5, 7.0, 1.1],
	[24.0, 118.0, 10.0, 5.5, 1.2],
	[26.5, 163.0, 9.0, 6.5, 1.05],
	[23.0, 212.0, 10.5, 6.0, 1.3],
	[27.0, 258.0, 9.5, 6.5, 1.1],
	[24.5, 305.0, 10.0, 6.0, 1.2],
	[29.0, 345.0, 8.0, 6.0, 0.95],
	[33.0, 95.0, 6.0, 5.0, 0.7],
	[34.5, 225.0, 6.5, 5.0, 0.7],
	[36.0, 330.0, 5.5, 4.5, 0.6],
]

const BARK := Color(0.27, 0.18, 0.12)
const BARK_DARK := Color(0.11, 0.07, 0.045)
const BARK_WARM := Color(0.35, 0.23, 0.15)
const MOSS := Color(0.20, 0.42, 0.16)
const MOSS_PATH := Color(0.28, 0.62, 0.24)
const MOSS_GLOW := Color(0.38, 0.78, 0.34)
const LEAF_DARK := Color(0.11, 0.30, 0.14)
const LEAF_MID := Color(0.19, 0.46, 0.21)
const LEAF_LIGHT := Color(0.32, 0.60, 0.28)
const SPORE_COL := Color(0.38, 0.96, 0.74)

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var wind_sign := 1.0


class Geo:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()


func _init() -> void:
	noise.seed = 7
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0
	rng.seed = 20261110
	_detect_winding()

	var trunk := Geo.new()
	_build_trunk(trunk)

	var bark := Geo.new()
	var spores := Geo.new()
	var leaves := Geo.new()
	var tips: Array = []
	var arch_foliage: Array = []

	_build_limbs(bark, tips)
	_build_spiral_walkway(bark, spores)
	_build_terrace_and_bridge(bark, spores, arch_foliage)
	_build_canopy(leaves, tips, arch_foliage)

	var mesh := ArrayMesh.new()
	var bark_mat := _bark_material()
	_commit_smooth(mesh, trunk, bark_mat)
	_commit_smooth(mesh, bark, bark_mat)
	_commit_smooth(mesh, spores, _spore_material())
	_commit_smooth(mesh, leaves, _leaf_material())

	var trunk_only := ArrayMesh.new()
	_commit_smooth(trunk_only, trunk, bark_mat)
	var shape := trunk_only.create_trimesh_shape()

	_report_normal(mesh)
	print("trunk verts=", trunk.v.size(), " bark verts=", bark.v.size(), " spores verts=", spores.v.size(), " leaves verts=", leaves.v.size())
	var e1 := ResourceSaver.save(mesh, OUT_MESH)
	var e2 := ResourceSaver.save(shape, OUT_SHAPE)
	print("save mesh=", e1, " shape=", e2)
	quit()


func _detect_winding() -> void:
	var arr := SphereMesh.new().get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ids: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var acc := 0.0
	for t in range(0, ids.size(), 3):
		var n := (vs[ids[t + 1]] - vs[ids[t]]).cross(vs[ids[t + 2]] - vs[ids[t]])
		acc += n.dot(ns[ids[t]] + ns[ids[t + 1]] + ns[ids[t + 2]])
	wind_sign = signf(acc)


# Connects a closed tubular grid (n_rings x seg) with 100% uniform manifold topology
# so individual triangles never flip or tear along curved/noisy sections.
func _connect_tube_grid(g: Geo, start: int, n_rings: int, seg: int, centers: Array, cap_start_dir: Vector3, cap_end_dir: Vector3) -> void:
	var acc := 0.0
	for k in n_rings - 1:
		var mid: Vector3 = (centers[k] + centers[k + 1]) * 0.5
		for j in seg:
			var a := start + k * seg + j
			var b := start + k * seg + (j + 1) % seg
			var c := start + (k + 1) * seg + (j + 1) % seg
			var n := (g.v[b] - g.v[a]).cross(g.v[c] - g.v[a])
			var out := (g.v[a] + g.v[c]) * 0.5 - mid
			acc += n.dot(out) * wind_sign
	var flip := acc < 0.0
	for k in n_rings - 1:
		for j in seg:
			var a := start + k * seg + j
			var b := start + k * seg + (j + 1) % seg
			var c := start + (k + 1) * seg + (j + 1) % seg
			var d := start + (k + 1) * seg + j
			if flip:
				g.i.append_array([a, c, b, a, d, c])
			else:
				g.i.append_array([a, b, c, a, c, d])

	if cap_start_dir.length_squared() > 0.001:
		var cap0 := g.v.size()
		g.v.append(centers[0] + cap_start_dir * 0.25)
		g.c.append(BARK_DARK)
		for j in seg:
			var a := start + j
			var b := start + (j + 1) % seg
			if flip:
				g.i.append_array([a, b, cap0])
			else:
				g.i.append_array([a, cap0, b])

	if cap_end_dir.length_squared() > 0.001:
		var cap1 := g.v.size()
		var last := start + (n_rings - 1) * seg
		g.v.append(centers[n_rings - 1] + cap_end_dir * 0.25)
		g.c.append(BARK_DARK)
		for j in seg:
			var a := last + j
			var b := last + (j + 1) % seg
			if flip:
				g.i.append_array([a, cap1, b])
			else:
				g.i.append_array([a, b, cap1])


func _profile(y: float) -> float:
	for k in PROFILE.size() - 1:
		var a := PROFILE[k]
		var b := PROFILE[k + 1]
		if y <= b.x:
			return lerpf(a.y, b.y, clampf((y - a.x) / (b.x - a.x), 0.0, 1.0))
	return PROFILE[-1].y


func _spine(y: float) -> Vector3:
	var sway_x := 0.32 * sin(y * 0.16 + 0.4)
	var sway_z := 0.28 * cos(y * 0.14 + 1.1)
	var t := clampf((y - 17.0) / (TRUNK_TOP - 17.0), 0.0, 1.0)
	return Vector3(sway_x + 1.3 * t * t, y, sway_z - 0.8 * t * t)


func _root_sum(theta: float, y: float) -> float:
	var s := 0.0
	for rt in ROOTS:
		var ang: float = rt[0]
		var strength: float = rt[1]
		var sharp: float = rt[2]
		var decay: float = rt[3]
		var twist := maxf(0.0, 2.5 - y * 0.5) * 0.08
		var d := wrapf(theta + twist - deg_to_rad(ang), -PI, PI)
		var lobe := pow(maxf(0.0, cos(d)), sharp)
		s += strength * lobe * exp(-maxf(y + 0.5, 0.0) / decay)
	return s


func _build_trunk(g: Geo) -> void:
	var ys: Array[float] = []
	var y := -1.2
	while y < TRUNK_TOP:
		ys.append(y)
		y += 0.3 if y < 3.5 else (0.55 if y < 20.0 else 0.85)
	ys.append(TRUNK_TOP)

	var start := g.v.size()
	var centers: Array = []
	for ring in ys.size():
		var ry: float = ys[ring]
		var center := _spine(ry)
		centers.append(center)
		for j in SEG:
			var theta := TAU * j / SEG
			var tw := theta + ry * 0.065
			var ridge := sin(tw * 10.0 + noise.get_noise_2d(theta * 3.0, ry * 0.3) * 2.8)
			var major_rib := sin(theta * 5.0 - ry * 0.12 + 0.8)
			var base := _profile(ry)
			var roots := _root_sum(theta, ry)
			var r := base + 0.24 * ridge + 0.18 * major_rib
			r += 0.30 * noise.get_noise_3d(cos(theta) * 3.0, ry * 0.18, sin(theta) * 3.0)
			r += roots
			g.v.append(center + Vector3(cos(theta) * r, 0.0, sin(theta) * r))
			var furrow := clampf(-ridge * 0.65 - major_rib * 0.35, 0.0, 1.0)
			var col := BARK.lerp(BARK_DARK, furrow * 0.85)
			var patch := clampf(noise.get_noise_3d(cos(theta) * 2.0, ry * 0.25 + 40.0, sin(theta) * 2.0) * 1.4, 0.0, 1.0)
			var moss := clampf(1.0 - ry / 3.5, 0.0, 1.0) * 0.42 + patch * 0.25
			g.c.append(col.lerp(MOSS, clampf(moss, 0.0, 0.68)))

	_connect_tube_grid(g, start, ys.size(), SEG, centers, Vector3.ZERO, Vector3.UP * 4.0)


func _tube(g: Geo, pts: Array, r0: float, r1: float, seg: int, moss_top: float, noise_amp: float = 0.14) -> void:
	var start := g.v.size()
	var n := pts.size()
	var ref := Vector3.UP
	for k in n:
		var p: Vector3 = pts[k]
		var tan: Vector3 = (pts[mini(k + 1, n - 1)] - pts[maxi(k - 1, 0)]).normalized()
		if absf(tan.dot(ref)) > 0.92:
			ref = Vector3.RIGHT
		var nx := tan.cross(ref).normalized()
		var bx := tan.cross(nx).normalized()
		var t := float(k) / maxi(1, n - 1)
		var r := lerpf(r0, r1, pow(t, 0.82))
		for j in seg:
			var a := TAU * j / seg
			var dir := nx * cos(a) + bx * sin(a)
			var flute := 0.08 * sin(a * 5.0 + float(k) * 0.42)
			var rr := r * (1.0 + flute + noise_amp * noise.get_noise_3d(p.x * 0.65 + dir.x, p.y * 0.65 + dir.y, p.z * 0.65 + dir.z))
			g.v.append(p + dir * rr)
			var col := BARK.lerp(BARK_DARK, clampf(-dir.y * 0.7 - flute * 3.5, 0.0, 1.0) * 0.68)
			g.c.append(col.lerp(MOSS, clampf(dir.y, 0.0, 1.0) * moss_top))
	var end_dir: Vector3 = (pts[n - 1] - pts[n - 2]).normalized()
	_connect_tube_grid(g, start, n, seg, pts, Vector3.ZERO, end_dir * r1)


func _bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, steps: int) -> Array:
	var out: Array = []
	for k in steps + 1:
		var t := float(k) / steps
		var u := 1.0 - t
		out.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return out


func _add_spore_cluster(spores: Geo, pos: Vector3, normal_up: Vector3, count: int = 3) -> void:
	var up := normal_up.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up).normalized()
	for m in count:
		var off := (side * rng.randf_range(-0.16, 0.16) + fwd * rng.randf_range(-0.16, 0.16)) * (0.35 if m == 0 else 1.0)
		var base := pos + off
		var r_cap := rng.randf_range(0.10, 0.14) if m == 0 else rng.randf_range(0.06, 0.10)
		var h_stem := r_cap * 0.65
		var center := base + up * h_stem
		var seg_u := 8
		var seg_v := 5
		var start := spores.v.size()
		var centers: Array = []
		for iv in range(seg_v + 1):
			var v_t := float(iv) / seg_v
			var phi := lerpf(-0.25 * PI, 0.5 * PI, v_t)
			var ry := sin(phi) * r_cap * 0.78
			var rr := cos(phi) * r_cap * (0.45 if iv == 0 else 1.0)
			centers.append(center + up * (ry - 0.05))
			for iu in seg_u:
				var th := TAU * iu / seg_u
				var pt := center + (side * cos(th) + fwd * sin(th)) * rr + up * ry
				spores.v.append(pt)
				var glow := clampf(v_t * 0.9 + 0.1, 0.0, 1.0)
				spores.c.append(MOSS_GLOW.lerp(SPORE_COL, glow))
		_connect_tube_grid(spores, start, seg_v + 1, seg_u, centers, Vector3.ZERO, up * r_cap)


func _build_limbs(g: Geo, tips: Array) -> void:
	for lb in LIMBS:
		var h: float = lb[0]
		var ang: float = lb[1]
		var length: float = lb[2]
		var rise: float = lb[3]
		var r0: float = lb[4]
		var a := deg_to_rad(ang + rng.randf_range(-6.0, 6.0))
		var dir := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-dir.z, 0.0, dir.x)
		var base := _spine(h)
		var p0 := base + dir * _profile(h) * 0.35 - Vector3.UP * 0.6
		var p1 := base + dir * length * 0.35 + Vector3.UP * rise * 0.05
		var p2 := base + dir * length * 0.7 + Vector3.UP * rise * 0.45 + side * rng.randf_range(-1.5, 1.5)
		var p3 := base + dir * length + Vector3.UP * rise
		var pts := _bezier(p0, p1, p2, p3, 14)
		_tube(g, pts, r0, r0 * 0.22, 10, 0.40)
		tips.append([p3, r0])

		var fork: Vector3 = pts[8]
		var fdir := (dir + side * (1.0 if rng.randf() > 0.5 else -1.0) * 0.9).normalized()
		var f3 := fork + fdir * length * 0.45 + Vector3.UP * rise * 0.55
		var f1 := fork + fdir * length * 0.15 + Vector3.UP * 0.4
		var f2 := fork + fdir * length * 0.32 + Vector3.UP * rise * 0.35
		_tube(g, _bezier(fork - dir * 0.3, f1, f2, f3, 8), r0 * 0.5, r0 * 0.14, 8, 0.35)
		tips.append([f3, r0 * 0.7])
	tips.append([_spine(TRUNK_TOP) + Vector3.UP * 2.5, 1.4])


func _spiral_frame(s: float) -> Array:
	# Pure, C2-smooth helical parameterization from underground entry (s = -1.8, y = -0.82)
	# through RootEntryRamp (s = -0.85, (3.95, 0.12, 3.10)) and RootStep0..21 (s = 0..21.2)
	# into the South-West terrace fusion zone (s = 21.6), with radial outward vector never flipping!
	var th := 1.0680 + s * 0.46164
	if s < 0.0:
		var u := clampf(-s / 1.8, 0.0, 1.0)
		th = lerpf(1.0680, 0.56, u)
	var r := 3.55
	var y := 0.7318182 + s * 0.7636364
	if s < 0.0:
		var u := clampf(-s / 1.8, 0.0, 1.0)
		r = lerpf(3.55, 5.15, u)
		y = lerpf(0.7318182, -0.82, u * (0.75 + 0.25 * u))
	elif s > 19.5:
		var u := clampf((s - 19.5) / 2.1, 0.0, 1.0)
		var su := u * u * (3.0 - 2.0 * u)
		var hel_p := Vector3(cos(th) * 3.55, y, sin(th) * 3.55)
		var ter_p := Vector3(-1.05, 16.96, -4.65)
		var pos := hel_p.lerp(ter_p, su * 0.65)
		var out_dir := Vector3(cos(th), 0.0, sin(th)).lerp(Vector3(-0.35, 0.0, -0.94).normalized(), su * 0.5).normalized()
		return [pos, out_dir]
	var pos := Vector3(cos(th) * r, y, sin(th) * r)
	var out_dir := Vector3(cos(th), 0.0, sin(th))
	return [pos, out_dir]


func _build_spiral_walkway(g: Geo, spores: Geo) -> void:
	var prof: Array[Vector2] = [
		Vector2(-1.90, 0.55),   # 0: inner top fused inside trunk bark
		Vector2(-1.25, 0.24),   # 1: inner bark-to-moss transition
		Vector2(-0.80, 0.21),   # 2: inner moss tread
		Vector2(-0.25, 0.22),   # 3: center-inner moss tread
		Vector2(0.30, 0.22),    # 4: center-outer moss tread
		Vector2(0.85, 0.21),    # 5: outer moss tread
		Vector2(1.28, 0.23),    # 6: outer moss-to-curb base
		Vector2(1.48, 0.42),    # 7: inner face of gnarled root curb
		Vector2(1.66, 0.50),    # 8: crest of gnarled root curb
		Vector2(1.82, 0.24),    # 9: outer upper flank of root shelf
		Vector2(1.74, -0.18),   # 10: outer lower flank of root shelf
		Vector2(1.38, -0.58),   # 11: outer underside bevel
		Vector2(0.80, -0.98),   # 12: mid-outer bracket underside
		Vector2(0.10, -1.38),   # 13: mid-inner bracket underside
		Vector2(-0.70, -1.78),  # 14: deep trunk root bracket
		Vector2(-1.90, -2.15),  # 15: bottom fused inside trunk
	]
	var m_prof := prof.size()
	var n_rings := 152
	var s_min := -1.8
	var s_max := 21.6
	var start := g.v.size()
	var centers: Array = []

	for k in n_rings:
		var t_ring := float(k) / (n_rings - 1)
		var s := lerpf(s_min, s_max, t_ring)
		var fr := _spiral_frame(s)
		var c: Vector3 = fr[0]
		var out_dir: Vector3 = fr[1]
		var up_dir := Vector3.UP
		centers.append(c - up_dir * 0.4)

		var entry_fade := clampf((s - s_min) / 1.4, 0.0, 1.0)
		var terrace_fade := clampf((s_max - s) / 1.5, 0.0, 1.0)
		var rim_fade := entry_fade * terrace_fade
		var burl_swell := 0.22 * noise.get_noise_3d(c.x * 0.38, c.y * 0.38, c.z * 0.38) + 0.14 * sin(s * 1.4)

		for j in m_prof:
			var uv := prof[j]
			var u := uv.x
			var v := uv.y

			if j >= 2 and j <= 5:
				var ripple := 0.020 * sin(s * TAU) + 0.016 * noise.get_noise_3d(c.x * 0.7 + u, c.y * 0.7, c.z * 0.7)
				v += ripple
			elif j >= 7 and j <= 9:
				var root_wave := 0.15 * sin(s * 2.1 + 0.5) + 0.13 * noise.get_noise_3d(c.x * 0.55, c.y * 0.55, c.z * 0.55)
				v = lerpf(0.21, v + root_wave, rim_fade)
				u += (0.11 * sin(s * 1.5) + burl_swell * 0.7) * rim_fade
			elif j >= 10 and j <= 14:
				var rib := 0.24 * pow(maxf(0.0, cos(s * PI * 0.85)), 2.0) + 0.18 * noise.get_noise_3d(c.x * 0.4 + u, c.y * 0.4, c.z * 0.4)
				v -= (rib + absf(burl_swell) * 0.45) * entry_fade
				u += (rib * 0.38 + burl_swell) * rim_fade

			var pt := c + out_dir * u + up_dir * v
			if s < -0.3 and v < 0.0:
				pt.y = maxf(pt.y, -0.75)
			g.v.append(pt)

			var col := BARK
			if j >= 2 and j <= 5:
				var center_t := 1.0 - absf(float(j) - 3.5) / 2.2
				col = MOSS.lerp(MOSS_PATH, clampf(center_t, 0.0, 1.0)).lerp(MOSS_GLOW, 0.22 * center_t)
			elif j == 1 or j == 6:
				col = BARK.lerp(MOSS, 0.60)
			elif j == 7 or j == 8:
				var moss_patch := clampf(0.45 + 0.45 * sin(s * 1.9), 0.15, 0.70)
				col = BARK_WARM.lerp(MOSS, moss_patch)
			else:
				var dark_t := clampf((-v) / 1.5, 0.0, 1.0)
				col = BARK.lerp(BARK_DARK, dark_t * 0.75)
			g.c.append(col)

	_connect_tube_grid(g, start, n_rings, m_prof, centers, Vector3(0.8, -0.2, 0.4), Vector3(0.0, -0.1, -0.8))

	for step_idx in [0, 3, 6, 9, 12, 15, 18, 20]:
		var fr_s := _spiral_frame(float(step_idx))
		var cp: Vector3 = fr_s[0]
		var r_dir: Vector3 = fr_s[1]
		var shroom_pos := cp + r_dir * 1.52 + Vector3.UP * 0.46
		_add_spore_cluster(spores, shroom_pos, Vector3.UP + r_dir * 0.18, 3)


func _bough_spine_z(z: float) -> Vector3:
	# Smooth C2 spine from z = -1.2 (inside trunk) through CanopyTerrace and BoughSegment0..3 to z = -45.6 (castle cliff)
	var t_bridge := clampf((-z - 6.60) / (45.60 - 6.60), 0.0, 1.0)
	var y_bridge := lerpf(17.00, 20.45, t_bridge)
	var x_bridge := 0.08 - 1.60 * pow(t_bridge, 1.55)
	var ter_bell := exp(-pow((z - (-5.2)) / 2.2, 2.0))
	var x := lerpf(x_bridge, -0.55, ter_bell)
	var y := lerpf(y_bridge, 17.00, clampf((z - (-8.5)) / 3.5, 0.0, 1.0))
	return Vector3(x, y, z)


func _build_terrace_and_bridge(g: Geo, spores: Geo, arch_foliage: Array) -> void:
	var prof_b: Array[Vector2] = [
		Vector2(0.0, 0.21),     # 0: center moss path
		Vector2(0.36, 0.21),    # 1: inner-east moss path
		Vector2(0.72, 0.21),    # 2: outer-east moss path
		Vector2(0.88, 0.34),    # 3: east root-parapet inner slope
		Vector2(1.00, 0.68),    # 4: east root-parapet crest
		Vector2(1.18, 0.40),    # 5: east root-parapet outer shoulder
		Vector2(1.24, -0.18),   # 6: east upper bark flank
		Vector2(1.10, -0.82),   # 7: east lower bark flank
		Vector2(0.78, -1.45),   # 8: east bough belly
		Vector2(0.36, -1.88),   # 9: lower-east bough keel
		Vector2(0.0, -2.02),    # 10: bottom bough keel
		Vector2(-0.36, -1.88),  # 11: lower-west bough keel
		Vector2(-0.78, -1.45),  # 12: west bough belly
		Vector2(-1.10, -0.82),  # 13: west lower bark flank
		Vector2(-1.24, -0.18),  # 14: west upper bark flank
		Vector2(-1.18, 0.40),   # 15: west root-parapet outer shoulder
		Vector2(-1.00, 0.68),   # 16: west root-parapet crest
		Vector2(-0.88, 0.34),   # 17: west root-parapet inner slope
		Vector2(-0.72, 0.21),   # 18: outer-west moss path
		Vector2(-0.36, 0.21),   # 19: inner-west moss path
	]
	var m_b := prof_b.size()
	var n_stations := 108
	var z_start := -1.20
	var z_end := -45.60
	var start := g.v.size()
	var centers: Array = []

	for k in n_stations:
		var t := float(k) / (n_stations - 1)
		var z := lerpf(z_start, z_end, t)
		var c := _bough_spine_z(z)
		var c_next := _bough_spine_z(maxf(z_end, z - 0.8))
		var c_prev := _bough_spine_z(minf(z_start, z + 0.8))
		var fwd := (c_next - c_prev).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var up := Vector3.UP
		centers.append(c - up * 0.45)

		var terrace_w := exp(-pow((z - (-5.35)) / 2.45, 2.0))
		var trunk_flare := exp(-pow((z - (-1.2)) / 2.8, 2.0))
		var half_width := lerpf(1.52, 3.15, terrace_w) + 0.45 * trunk_flare
		var belly_depth := lerpf(1.15, 0.85, clampf((-z - 8.0) / 37.0, 0.0, 1.0)) + 0.65 * terrace_w + 1.45 * trunk_flare
		var width_meander := 0.08 * sin(z * 0.28) * (1.0 - terrace_w * 0.7)
		var west_stair_open := 1.0 - exp(-pow((z - (-3.7)) / 1.15, 2.0))

		for j in m_b:
			var uv := prof_b[j]
			var ux := uv.x * half_width
			var uy := uv.y

			var is_moss := (j <= 2 or j >= 18)
			var is_east_parapet := (j >= 3 and j <= 5)
			var is_west_parapet := (j >= 15 and j <= 17)
			if is_moss:
				uy += 0.016 * noise.get_noise_2d(z * 0.6, ux * 1.2)
			elif is_east_parapet or is_west_parapet:
				var p_scale := (west_stair_open if is_west_parapet else 1.0) * clampf((-z - 2.0) / 1.5, 0.0, 1.0)
				var wave := 0.14 * sin(z * 0.45 + signf(ux) * 1.4) + 0.12 * noise.get_noise_3d(c.x + ux * 0.6, c.y, z * 0.35)
				var target_y := (uv.y + 0.22 * terrace_w + wave)
				uy = lerpf(0.22, target_y, p_scale)
				ux += width_meander + 0.10 * noise.get_noise_2d(z * 0.35, ux)
			else:
				uy *= belly_depth
				var flute := 0.18 * sin(float(j) * 1.8 + z * 0.22) + 0.16 * noise.get_noise_3d(ux * 0.6, uy * 0.6, z * 0.22)
				ux = ux * (1.0 + 0.08 * flute) + width_meander
				uy += flute * 0.55

			var pt := c + right * ux + up * uy
			g.v.append(pt)

			var col := BARK
			if is_moss:
				var edge_f := clampf(1.0 - absf(uv.x) / 0.78, 0.0, 1.0)
				col = MOSS.lerp(MOSS_PATH, edge_f).lerp(MOSS_GLOW, 0.28 * edge_f)
			elif j == 3 or j == 17:
				col = MOSS.lerp(BARK_WARM, 0.45)
			elif j == 4 or j == 16:
				var m_top := clampf(0.5 + 0.4 * sin(z * 0.5 + ux), 0.2, 0.75)
				col = BARK_WARM.lerp(MOSS, m_top)
			else:
				var depth_f := clampf((-uy) / 2.2, 0.0, 1.0)
				col = BARK.lerp(BARK_DARK, depth_f * 0.75)
			g.c.append(col)

	_connect_tube_grid(g, start, n_stations, m_b, centers, Vector3(0.0, -0.3, 1.0), Vector3(0.0, -0.2, -1.0))

	# Two massive parabolic arch-boughs growing out of the lower North trunk (y = 9.2..12.8)
	# and sweeping smoothly into the underside of the Bough Bridge (z = -12.5 and z = -21.5)
	var arch_buttress_1 := _bezier(
		Vector3(0.0, 9.2, -1.2),
		Vector3(0.05, 12.8, -5.5),
		Vector3(0.08, 15.6, -9.2),
		Vector3(0.05, 16.6, -13.5),
		16
	)
	var arch_buttress_2 := _bezier(
		Vector3(-0.2, 11.5, -1.5),
		Vector3(-0.15, 14.5, -8.5),
		Vector3(-0.08, 16.8, -15.0),
		Vector3(-0.15, 17.6, -21.5),
		18
	)
	_tube(g, arch_buttress_1, 1.45, 0.72, 11, 0.25, 0.16)
	_tube(g, arch_buttress_2, 1.15, 0.58, 10, 0.28, 0.16)

	# Roots at the far end of the bridge (z = -44.5..-50.2) that wrap directly onto the stone cylinder
	# of MageTower (centered at (-5.0, 18.0, -50.0), radius 4.5m) and cradle TowerBalcony ((-1.5, 20.0, -47.0))
	var tower_roots := [
		[Vector3(-1.8, 19.4, -44.5), Vector3(-3.2, 20.2, -45.2), Vector3(-4.5, 21.0, -45.8), Vector3(-6.2, 21.8, -46.8)],
		[Vector3(-1.5, 18.8, -44.2), Vector3(-1.9, 17.5, -45.8), Vector3(-2.5, 15.8, -46.4), Vector3(-3.6, 13.2, -46.0)],
		[Vector3(-0.6, 19.0, -44.5), Vector3(-0.5, 18.2, -46.8), Vector3(-0.5, 16.8, -48.6), Vector3(-0.8, 14.5, -50.2)],
	]
	for tr in tower_roots:
		_tube(g, _bezier(tr[0], tr[1], tr[2], tr[3], 12), 0.65, 0.24, 9, 0.30, 0.16)

	_add_spore_cluster(spores, Vector3(-3.35, 17.85, -5.5), Vector3.UP, 3)
	_add_spore_cluster(spores, Vector3(2.15, 17.85, -5.2), Vector3.UP, 3)
	for z_sp in [-12.0, -18.5, -25.0, -31.5, -38.0, -43.5]:
		var cs := _bough_spine_z(z_sp)
		_add_spore_cluster(spores, cs + Vector3(-1.48, 0.66, 0.0), Vector3.UP, 3)
		_add_spore_cluster(spores, cs + Vector3(1.48, 0.66, 0.0), Vector3.UP, 3)

	# Overarching canopy boughs growing out of the main trunk at y = 20.5..22.0 over the terrace
	var over_w := _bezier(Vector3(-1.1, 20.4, -1.5), Vector3(-2.8, 21.6, -4.5), Vector3(-2.4, 22.3, -7.8), Vector3(-0.6, 22.1, -10.8), 14)
	var over_e := _bezier(Vector3(1.0, 20.9, -1.5), Vector3(2.4, 21.9, -4.8), Vector3(1.9, 22.6, -8.2), Vector3(0.4, 22.3, -11.4), 14)
	_tube(g, over_w, 0.78, 0.22, 9, 0.40)
	_tube(g, over_e, 0.75, 0.22, 9, 0.40)
	arch_foliage.append([Vector3(-1.4, 22.5, -9.2), 2.8])
	arch_foliage.append([Vector3(1.1, 22.8, -9.8), 2.7])
	arch_foliage.append([Vector3(-0.2, 23.0, -7.5), 3.1])

	# Natural forked lateral branches growing outward and upward from the giant bough flanks
	var branch_specs := [
		[-16.5, -1.0, 4.8, 3.8, -2.2, 0.48],
		[-22.0, 1.0, 5.2, 4.1, -2.5, 0.52],
		[-28.0, -1.0, 4.6, 3.9, -2.0, 0.46],
		[-33.5, 1.0, 4.9, 4.0, -2.4, 0.48],
		[-39.0, -1.0, 4.2, 3.6, -1.8, 0.42],
	]
	for bs in branch_specs:
		var bz: float = bs[0]
		var side_sign: float = bs[1]
		var reach_x: float = bs[2]
		var reach_y: float = bs[3]
		var reach_z: float = bs[4]
		var br0: float = bs[5]
		var cb := _bough_spine_z(bz)
		var p0 := cb + Vector3(side_sign * 1.35, -0.35, 0.0)
		var p1 := cb + Vector3(side_sign * (1.8 + reach_x * 0.35), reach_y * 0.30, reach_z * 0.3)
		var p2 := cb + Vector3(side_sign * (1.5 + reach_x * 0.65), reach_y * 0.75, reach_z * 0.7)
		var p3 := cb + Vector3(side_sign * reach_x * 0.55, reach_y, reach_z)
		var b_pts := _bezier(p0, p1, p2, p3, 12)
		_tube(g, b_pts, br0, br0 * 0.22, 8, 0.40)

		var fk: Vector3 = b_pts[6]
		var f3 := cb + Vector3(-side_sign * 0.4, reach_y + 0.55, reach_z * 0.85)
		var f1 := fk.lerp(f3, 0.35) + Vector3(0.0, 0.4, 0.0)
		var f2 := fk.lerp(f3, 0.70) + Vector3(0.0, 0.6, 0.0)
		_tube(g, _bezier(fk, f1, f2, f3, 8), br0 * 0.52, br0 * 0.16, 7, 0.40)

		arch_foliage.append([p3 + Vector3(0.0, 0.4, 0.0), 2.35])
		arch_foliage.append([p3 + Vector3(side_sign * 1.1, -0.2, 0.8), 1.85])
		arch_foliage.append([f3 + Vector3(0.0, 0.35, 0.0), 2.10])


func _build_canopy(leaves: Geo, tips: Array, arch_foliage: Array) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 18
	sphere.rings = 10
	var arr := sphere.get_mesh_arrays()
	var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var si: PackedInt32Array = arr[Mesh.ARRAY_INDEX]

	var blobs: Array = []
	for tip in tips:
		var p: Vector3 = tip[0]
		var weight: float = tip[1]
		var count := 3 if weight > 0.9 else 2
		for k in count:
			var r := rng.randf_range(3.0, 4.2) * lerpf(0.85, 1.2, clampf(weight / 1.3, 0.0, 1.0))
			var c := p + Vector3(rng.randf_range(-2.4, 2.4), rng.randf_range(-0.4, 1.6), rng.randf_range(-2.4, 2.4))
			c.y = maxf(c.y, CANOPY_FLOOR + r * 0.7)
			blobs.append([c, r])

	for af in arch_foliage:
		var ap: Vector3 = af[0]
		var ar: float = af[1]
		blobs.append([ap, ar])

	var min_y := 1e9
	var max_y := -1e9
	for b in blobs:
		var bp: Vector3 = b[0]
		var br: float = b[1]
		min_y = minf(min_y, bp.y - br * 0.7)
		max_y = maxf(max_y, bp.y + br * 0.7)

	for b in blobs:
		var c: Vector3 = b[0]
		var r: float = b[1]
		var tint := LEAF_DARK.lerp(LEAF_MID, rng.randf()).lerp(LEAF_LIGHT, rng.randf() * 0.45)
		var base_v := leaves.v.size()
		for v in sv:
			var w := c + v * r
			var disp := 1.0 + 0.34 * noise.get_noise_3d(w.x * 0.38, w.y * 0.38, w.z * 0.38)
			var pt := c + Vector3(v.x, v.y * 0.62, v.z) * r * disp
			leaves.v.append(pt)
			var height := clampf((pt.y - min_y) / (max_y - min_y), 0.0, 1.0)
			var col := tint * lerpf(0.68, 1.12, height)
			col = col.lerp(LEAF_LIGHT, clampf(v.y, 0.0, 1.0) * 0.25)
			col.a = 1.0
			leaves.c.append(col)
		for idx in si:
			leaves.i.append(base_v + idx)


func _commit_smooth(mesh: ArrayMesh, g: Geo, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in g.v.size():
		st.set_color(g.c[k])
		st.add_vertex(g.v[k])
	for idx in g.i:
		st.add_index(idx)
	st.generate_normals()
	st.set_material(mat)
	st.commit(mesh)


func _report_normal(mesh: ArrayMesh) -> void:
	var arr := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var k := SEG * 30
	var out := Vector3(vs[k].x, 0.0, vs[k].z).normalized()
	print("winding=", wind_sign, " trunk normal outward dot=", ns[k].dot(out))


func _bark_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "GreatTreeBark"
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.90
	m.emission_enabled = true
	m.emission = Color(0.04, 0.14, 0.06)
	m.emission_energy_multiplier = 0.22
	return m


func _spore_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "GreatTreeSpores"
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = Color(0.30, 0.95, 0.75)
	m.emission_energy_multiplier = 2.2
	return m


func _leaf_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "GreatTreeLeaves"
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85
	m.emission_enabled = true
	m.emission = Color(0.05, 0.18, 0.08)
	m.emission_energy_multiplier = 0.28
	return m
