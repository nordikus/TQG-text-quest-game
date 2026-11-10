@tool
extends SceneTree

const FOREST_SIZE := 480.0
const CELL_SIZE := 5.8
const MIN_TREE_DIST := 5.6
const FILL_PROBABILITY := 0.86

const HAND_PLACED_POSITIONS: Array[Vector2] = [
	Vector2(-16.0, 2.0), Vector2(-18.0, -4.0), Vector2(-15.0, -9.0),
	Vector2(-20.0, -12.0), Vector2(-16.0, -15.0), Vector2(-19.0, 6.0),
	Vector2(-11.0, -18.0), Vector2(-16.0, -20.0), Vector2(-7.0, -22.0),
	Vector2(-2.5, -21.5), Vector2(1.0, -18.0), Vector2(6.0, -17.0),
	Vector2(-5.0, -15.0), Vector2(-15.0, 10.0), Vector2(-18.0, 14.0),
	Vector2(-11.0, 18.0), Vector2(-6.0, 18.0), Vector2(-2.0, 20.0),
	Vector2(4.0, 19.0), Vector2(9.0, 17.0), Vector2(14.0, 14.0),
	Vector2(17.0, 9.0), Vector2(18.0, 3.0), Vector2(17.0, -3.0),
	Vector2(18.5, -2.5), Vector2(-9.0, -10.0),
	Vector2(-26.0, 0.0), Vector2(-24.0, -11.0), Vector2(-23.0, 12.0),
	Vector2(0.0, 25.0), Vector2(20.0, 20.0), Vector2(-12.0, -26.0),
	Vector2(5.0, -26.0), Vector2(24.0, -6.0), Vector2(-26.0, -20.0),
	Vector2(-9.0, 24.0),
	# East barrier props:
	Vector2(13.0, -10.0), Vector2(16.0, -13.0), Vector2(19.0, -9.0), Vector2(21.0, -14.0),
	# Northwest barrier props:
	Vector2(-4.5, -18.0), Vector2(-6.5, -18.5), Vector2(-3.0, -18.5)
]

const NATURE_TRAIL_PTS: Array[Vector2] = [
	Vector2(-4.5, -17.5),
	Vector2(-6.2, -25.0),
	Vector2(-9.0, -35.5),
	Vector2(-13.8, -47.5),
	Vector2(-17.3, -56.8)
]

func _dist_to_nature_trail(p: Vector2) -> float:
	var min_d := 1e9
	for i in range(NATURE_TRAIL_PTS.size() - 1):
		var a = NATURE_TRAIL_PTS[i]
		var b = NATURE_TRAIL_PTS[i + 1]
		var ab = b - a
		var ap = p - a
		var l_sq = ab.length_squared()
		var t = clampf(ap.dot(ab) / l_sq, 0.0, 1.0)
		var proj = a + t * ab
		var d = (p - proj).length()
		if d < min_d:
			min_d = d
	return min_d

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109

	var persistent_pines: Array[Transform3D] = []
	var persistent_oaks: Array[Transform3D] = []
	var corridor_pines: Array[Transform3D] = []
	var corridor_oaks: Array[Transform3D] = []
	var nature_corridor_pines: Array[Transform3D] = []
	var nature_corridor_oaks: Array[Transform3D] = []

	var half_size := FOREST_SIZE * 0.5
	var grid_cols := int(FOREST_SIZE / CELL_SIZE)
	var grid_rows := int(FOREST_SIZE / CELL_SIZE)

	var occupied_cells: Dictionary = {}

	for row in range(grid_rows):
		for col in range(grid_cols):
			if rng.randf() > FILL_PROBABILITY:
				continue

			var base_x := -half_size + (float(col) + 0.5) * CELL_SIZE
			var base_z := -half_size + (float(row) + 0.5) * CELL_SIZE

			var max_jitter := (CELL_SIZE - MIN_TREE_DIST) * 0.45
			var jitter_x := rng.randf_range(-max_jitter, max_jitter)
			var jitter_z := rng.randf_range(-max_jitter, max_jitter)

			var pos_x := base_x + jitter_x
			var pos_z := base_z + jitter_z
			var tree_pos := Vector2(pos_x, pos_z)

			# 1. Clearing exclusion (22.5m radius from altar)
			if tree_pos.length() < 22.5:
				continue

			# 2. Castle courtyard and keep exclusion
			if pos_x > -35.0 and pos_x < 35.0 and pos_z > -165.0 and pos_z < -78.0:
				continue

			# 2b. Check if inside nature path corridor / Great Tree zone
			var is_nature_corridor := false
			if (tree_pos - Vector2(-21.0, -60.0)).length() < 14.0:
				is_nature_corridor = true
			elif (tree_pos - Vector2(-17.5, -56.8)).length() < 8.0:
				is_nature_corridor = true
			elif pos_x >= -25.0 and pos_x <= -17.0 and pos_z <= -60.0 and pos_z >= -95.0:
				is_nature_corridor = true
			elif _dist_to_nature_trail(tree_pos) < 5.0:
				is_nature_corridor = true

			# 3. Check distance against hand-placed perimeter trees and props
			var too_close := false
			for hp in HAND_PLACED_POSITIONS:
				if (tree_pos - hp).length_squared() < (MIN_TREE_DIST * MIN_TREE_DIST):
					too_close = true
					break
			if too_close:
				continue

			# 4. Check neighbor cells in spatial hash grid
			var cell_coord := Vector2i(col, row)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					var neighbor_coord := cell_coord + Vector2i(dx, dz)
					if occupied_cells.has(neighbor_coord):
						var other_pos: Vector2 = occupied_cells[neighbor_coord]
						if (tree_pos - other_pos).length_squared() < (MIN_TREE_DIST * MIN_TREE_DIST):
							too_close = true
							break
				if too_close:
					break

			if too_close:
				continue

			occupied_cells[cell_coord] = tree_pos

			var rot_y := rng.randf_range(0.0, TAU)
			var is_pine := rng.randf() < 0.52
			var is_in_burn_corridor := (pos_x > -6.0 and pos_x < 36.0 and pos_z > -82.0 and pos_z < -5.0)

			if is_pine:
				var scale_p := rng.randf_range(1.2, 1.6)
				var b := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_p, scale_p * rng.randf_range(0.95, 1.1), scale_p))
				var xform := Transform3D(b, Vector3(pos_x, 0.0, pos_z))
				if is_nature_corridor:
					nature_corridor_pines.append(xform)
				elif is_in_burn_corridor:
					corridor_pines.append(xform)
				else:
					persistent_pines.append(xform)
			else:
				var scale_o := rng.randf_range(1.1, 1.45)
				var b := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_o, scale_o * rng.randf_range(0.95, 1.08), scale_o))
				var xform := Transform3D(b, Vector3(pos_x, 0.0, pos_z))
				if is_nature_corridor:
					nature_corridor_oaks.append(xform)
				elif is_in_burn_corridor:
					corridor_oaks.append(xform)
				else:
					persistent_oaks.append(xform)

	print("Persistent: %d pines, %d oaks." % [persistent_pines.size(), persistent_oaks.size()])
	print("Burn corridor: %d pines, %d oaks." % [corridor_pines.size(), corridor_oaks.size()])
	print("Nature corridor: %d pines, %d oaks." % [nature_corridor_pines.size(), nature_corridor_oaks.size()])

	var mm_pers_pines := _create_pine_multimesh(persistent_pines)
	var mm_pers_oaks := _create_oak_multimesh(persistent_oaks)
	var mm_corr_pines := _create_pine_multimesh(corridor_pines)
	var mm_corr_oaks := _create_oak_multimesh(corridor_oaks)
	var mm_nat_pines := _create_pine_multimesh(nature_corridor_pines)
	var mm_nat_oaks := _create_oak_multimesh(nature_corridor_oaks)

	ResourceSaver.save(mm_pers_pines, "res://scenes/world/forest_canopy_pines.res")
	ResourceSaver.save(mm_pers_oaks, "res://scenes/world/forest_canopy_oaks.res")
	ResourceSaver.save(mm_corr_pines, "res://scenes/world/corridor_forest_pines.res")
	ResourceSaver.save(mm_corr_oaks, "res://scenes/world/corridor_forest_oaks.res")
	ResourceSaver.save(mm_nat_pines, "res://scenes/world/nature_corridor_pines.res")
	ResourceSaver.save(mm_nat_oaks, "res://scenes/world/nature_corridor_oaks.res")

	print("Bake completed successfully! All 6 MultiMesh resources saved.")
	quit(0)

func _create_pine_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.32, 0.22, 0.15)
	bark_mat.roughness = 0.9

	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.18, 0.42, 0.22)
	leaves_mat.roughness = 0.85

	var st_bark := SurfaceTool.new()
	st_bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.35
	trunk.height = 2.5
	st_bark.append_from(trunk, 0, Transform3D(Basis(), Vector3(0.0, 1.25, 0.0)))
	var trunk_mesh = st_bark.commit()

	var st_foliage := SurfaceTool.new()
	st_foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var l1 := CylinderMesh.new()
	l1.top_radius = 0.2; l1.bottom_radius = 1.4; l1.height = 1.6; l1.radial_segments = 6
	st_foliage.append_from(l1, 0, Transform3D(Basis(), Vector3(0.0, 2.3, 0.0)))

	var l2 := CylinderMesh.new()
	l2.top_radius = 0.1; l2.bottom_radius = 1.0; l2.height = 1.4; l2.radial_segments = 6
	st_foliage.append_from(l2, 0, Transform3D(Basis(), Vector3(0.0, 3.2, 0.0)))

	var l3 := CylinderMesh.new()
	l3.top_radius = 0.0; l3.bottom_radius = 0.7; l3.height = 1.2; l3.radial_segments = 6
	st_foliage.append_from(l3, 0, Transform3D(Basis(), Vector3(0.0, 4.1, 0.0)))
	var fol_mesh = st_foliage.commit()

	var combined := ArrayMesh.new()
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, trunk_mesh.surface_get_arrays(0))
	combined.surface_set_material(0, bark_mat)
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fol_mesh.surface_get_arrays(0))
	combined.surface_set_material(1, leaves_mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = combined
	mm.instance_count = transforms.size()

	var buf := PackedFloat32Array()
	buf.resize(transforms.size() * 12)
	for i in range(transforms.size()):
		var offset = i * 12
		var t = transforms[i]
		buf[offset + 0] = t.basis.x.x
		buf[offset + 1] = t.basis.y.x
		buf[offset + 2] = t.basis.z.x
		buf[offset + 3] = t.origin.x

		buf[offset + 4] = t.basis.x.y
		buf[offset + 5] = t.basis.y.y
		buf[offset + 6] = t.basis.z.y
		buf[offset + 7] = t.origin.y

		buf[offset + 8] = t.basis.x.z
		buf[offset + 9] = t.basis.y.z
		buf[offset + 10] = t.basis.z.z
		buf[offset + 11] = t.origin.z

	mm.buffer = buf
	return mm

func _create_oak_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.35, 0.26, 0.18)
	bark_mat.roughness = 0.9

	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.32, 0.55, 0.25)
	leaves_mat.roughness = 0.8

	var st_bark := SurfaceTool.new()
	st_bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.3
	trunk.bottom_radius = 0.5
	trunk.height = 3.5
	trunk.radial_segments = 7
	st_bark.append_from(trunk, 0, Transform3D(Basis(), Vector3(0.0, 1.75, 0.0)))
	var trunk_mesh = st_bark.commit()

	var st_foliage := SurfaceTool.new()
	st_foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c1 := SphereMesh.new()
	c1.radius = 1.6; c1.height = 2.4; c1.radial_segments = 7; c1.rings = 5
	st_foliage.append_from(c1, 0, Transform3D(Basis(), Vector3(0.0, 3.8, 0.0)))

	var c2 := SphereMesh.new()
	c2.radius = 1.2; c2.height = 1.8; c2.radial_segments = 6; c2.rings = 4
	st_foliage.append_from(c2, 0, Transform3D(Basis(), Vector3(0.8, 4.4, 0.4)))
	var fol_mesh = st_foliage.commit()

	var combined := ArrayMesh.new()
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, trunk_mesh.surface_get_arrays(0))
	combined.surface_set_material(0, bark_mat)
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fol_mesh.surface_get_arrays(0))
	combined.surface_set_material(1, leaves_mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = combined
	mm.instance_count = transforms.size()

	var buf := PackedFloat32Array()
	buf.resize(transforms.size() * 12)
	for i in range(transforms.size()):
		var offset = i * 12
		var t = transforms[i]
		buf[offset + 0] = t.basis.x.x
		buf[offset + 1] = t.basis.y.x
		buf[offset + 2] = t.basis.z.x
		buf[offset + 3] = t.origin.x

		buf[offset + 4] = t.basis.x.y
		buf[offset + 5] = t.basis.y.y
		buf[offset + 6] = t.basis.z.y
		buf[offset + 7] = t.origin.y

		buf[offset + 8] = t.basis.x.z
		buf[offset + 9] = t.basis.y.z
		buf[offset + 10] = t.basis.z.z
		buf[offset + 11] = t.origin.z

	mm.buffer = buf
	return mm
