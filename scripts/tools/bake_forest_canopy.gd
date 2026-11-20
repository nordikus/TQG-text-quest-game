@tool
extends SceneTree

const FOREST_SIZE := 480.0
const CELL_SIZE := 4.05
const MIN_TREE_DIST := 3.05
const FILL_PROBABILITY := 0.88

const Layout := preload("res://scripts/world/forest_layout.gd")
const HAND_PLACED_POSITIONS: Array[Vector2] = [
	Vector2(-20.8, 1.7),
	Vector2(-23.4, -1.8),
	Vector2(-18.5, -9.4),
	Vector2(-21.8, -11.0),
	Vector2(-22.3, -16.0),
	Vector2(-18.0, 7.4),
	Vector2(-13.0, -18.3),
	Vector2(-16.3, -21.8),
	Vector2(-12.5, -23.5),
	Vector2(-10.2, -15.7),
	Vector2(7.5, -15.1),
	Vector2(8.9, -20.9),
	Vector2(-13.3, -31.2),
	Vector2(-16.6, 14),
	Vector2(-21.0, 11.5),
	Vector2(-11.0, 21.0),
	Vector2(-8.3, 17.6),
	Vector2(-4.0, 22.5),
	Vector2(3.6, 17.2),
	Vector2(11.8, 20.2),
	Vector2(15.8, 15.5),
	Vector2(18.1, 9.1),
	Vector2(21.0, 6.0),
	Vector2(19.5, -1.5),
	Vector2(22.5, -4.2),
	Vector2(-27.5, 1.0),
	Vector2(-24.5, -8.0),
	Vector2(-25.0, 16.2),
	Vector2(1.0, 27),
	Vector2(22, 20),
	Vector2(-16.9, -29.1),
	Vector2(9.3, -29.2),
	Vector2(26.0, -8),
	Vector2(-26, -20),
	Vector2(-8.1, 25.7),
	Vector2(9.8, -1.5),
	Vector2(10.55, -10.5),
	Vector2(19.2, -9.1),
	Vector2(14.3, -19.8),
	Vector2(4.7, -58),
	Vector2(-5.5, -74.5),
	Vector2(0.1, -20.2),
	Vector2(3.1, -22.4),
	Vector2(-0.2, -27.5),
	Vector2(3.2, -31.5),
	Vector2(-1.9, -34.4),
	Vector2(-2.9, -40.7),
	Vector2(2.0, -41.5),
	Vector2(-1.0, -46.8),
	Vector2(1.7, -51.1),
	Vector2(-3.4, -53.3),
	Vector2(-2.1, -58.6),
	Vector2(-1.1, -64.5),
	Vector2(-3.8, -67),
	Vector2(1.1, -73.9),
	Vector2(-3.8, -77.8),
]

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109

	var persistent_pines: Array[Transform3D] = []
	var persistent_oaks: Array[Transform3D] = []
	var corridor_pines: Array[Transform3D] = []
	var corridor_oaks: Array[Transform3D] = []
	var undergrowth_transforms: Array[Transform3D] = []

	var half_size := FOREST_SIZE * 0.5
	var grid_cols := int(FOREST_SIZE / CELL_SIZE)
	var grid_rows := int(FOREST_SIZE / CELL_SIZE)

	var occupied_cells: Dictionary = {}
	var grove_noise := FastNoiseLite.new()
	grove_noise.seed = 73
	grove_noise.frequency = 0.054

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
			var glade_radius := 19.0 + 2.8 * sin(3.0 * tree_pos.angle()) + sin(7.0 * tree_pos.angle())
			if tree_pos.length() < glade_radius:
				continue

			# Larger gaps between groves and smaller openings within each grove.
			if grove_noise.get_noise_2dv(tree_pos) < -0.28:
				continue

			var ash_distance := Layout.distance_to_path(tree_pos, Layout.ASH_PATH)
			if Layout.clear_for_life(tree_pos, 1.15) or ash_distance < Layout.ASH_CORE + 0.8:
				continue

			if pos_x > -39.0 and pos_x < 39.0 and pos_z > -174.0 and pos_z < -79.0:
				continue

			# 4. Check distance against hand-placed perimeter trees and props
			var too_close := false
			for hp in HAND_PLACED_POSITIONS:
				if (tree_pos - hp).length_squared() < (MIN_TREE_DIST * MIN_TREE_DIST):
					too_close = true
					break
			if too_close:
				continue

			# 5. Check neighbor cells in spatial hash grid
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
			var is_pine := rng.randf() < 0.54
			var is_in_burn_corridor := ash_distance < 13.0 and pos_z > -81.0 and pos_z < 3.0
			if is_pine:
				var scale_p := rng.randf_range(1.25, 1.7)
				var b := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_p, scale_p * rng.randf_range(0.95, 1.12), scale_p))
				var xform := Transform3D(b, Vector3(pos_x, 0.0, pos_z))
				if is_in_burn_corridor:
					corridor_pines.append(xform)
				else:
					persistent_pines.append(xform)
			else:
				var scale_o := rng.randf_range(1.15, 1.55)
				var b := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_o, scale_o * rng.randf_range(0.95, 1.10), scale_o))
				var xform := Transform3D(b, Vector3(pos_x, 0.0, pos_z))
				if is_in_burn_corridor:
					corridor_oaks.append(xform)
				else:
					persistent_oaks.append(xform)

			# Add undergrowth bush between trees near the clearing and trail borders
			if (tree_pos.length() < 36.0 or (absf(pos_x) < 23.0 and pos_z > -77.0)) and rng.randf() < 0.46:
				var ub_pos := tree_pos + Vector2(rng.randf_range(-1.8, 1.8), rng.randf_range(-1.8, 1.8))
				if ub_pos.length() > 15.0:
					if Layout.distance_to_path(ub_pos, Layout.ASH_PATH) < 7.5:
						continue
					if Layout.clear_for_life(ub_pos, 0.8):
						continue
					var sc := rng.randf_range(0.9, 1.5)
					var ub_xform := Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(sc, sc, sc)), Vector3(ub_pos.x, 0.0, ub_pos.y))
					undergrowth_transforms.append(ub_xform)

	print("Persistent: %d pines, %d oaks." % [persistent_pines.size(), persistent_oaks.size()])
	print("Burn corridor: %d pines, %d oaks." % [corridor_pines.size(), corridor_oaks.size()])
	print("Undergrowth bushes: %d." % undergrowth_transforms.size())

	var mm_pers_pines := _create_pine_multimesh(persistent_pines)
	var mm_pers_oaks := _create_oak_multimesh(persistent_oaks)
	var mm_corr_pines := _create_pine_multimesh(corridor_pines)
	var mm_corr_oaks := _create_oak_multimesh(corridor_oaks)
	var mm_undergrowth := _create_bush_multimesh(undergrowth_transforms)

	ResourceSaver.save(mm_pers_pines, "res://scenes/world/forest_canopy_pines.res")
	ResourceSaver.save(mm_pers_oaks, "res://scenes/world/forest_canopy_oaks.res")
	ResourceSaver.save(mm_corr_pines, "res://scenes/world/corridor_forest_pines.res")
	ResourceSaver.save(mm_corr_oaks, "res://scenes/world/corridor_forest_oaks.res")
	ResourceSaver.save(mm_undergrowth, "res://scenes/world/forest_canopy_undergrowth.res")

	print("Bake completed successfully! All 5 MultiMesh resources saved.")
	quit(0)

func _create_pine_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.28, 0.18, 0.12)
	bark_mat.roughness = 0.9

	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.16, 0.38, 0.19)
	leaves_mat.roughness = 0.85

	var st_bark := SurfaceTool.new()
	st_bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.24
	trunk.bottom_radius = 0.40
	trunk.height = 2.4
	st_bark.append_from(trunk, 0, Transform3D(Basis(), Vector3(0.0, 1.2, 0.0)))
	var trunk_mesh = st_bark.commit()

	var st_foliage := SurfaceTool.new()
	st_foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	# 4 dense tiers extending down to Y = 1.0
	var l0 := CylinderMesh.new()
	l0.top_radius = 0.35; l0.bottom_radius = 1.8; l0.height = 1.6; l0.radial_segments = 7
	st_foliage.append_from(l0, 0, Transform3D(Basis(), Vector3(0.0, 1.7, 0.0)))

	var l1 := CylinderMesh.new()
	l1.top_radius = 0.25; l1.bottom_radius = 1.45; l1.height = 1.5; l1.radial_segments = 7
	st_foliage.append_from(l1, 0, Transform3D(Basis(), Vector3(0.0, 2.7, 0.0)))

	var l2 := CylinderMesh.new()
	l2.top_radius = 0.15; l2.bottom_radius = 1.1; l2.height = 1.4; l2.radial_segments = 7
	st_foliage.append_from(l2, 0, Transform3D(Basis(), Vector3(0.0, 3.6, 0.0)))

	var l3 := CylinderMesh.new()
	l3.top_radius = 0.0; l3.bottom_radius = 0.75; l3.height = 1.3; l3.radial_segments = 7
	st_foliage.append_from(l3, 0, Transform3D(Basis(), Vector3(0.0, 4.5, 0.0)))
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
	bark_mat.albedo_color = Color(0.32, 0.22, 0.15)
	bark_mat.roughness = 0.9

	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.28, 0.50, 0.22)
	leaves_mat.roughness = 0.8

	var st_bark := SurfaceTool.new()
	st_bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.32
	trunk.bottom_radius = 0.52
	trunk.height = 3.2
	trunk.radial_segments = 7
	st_bark.append_from(trunk, 0, Transform3D(Basis(), Vector3(0.0, 1.6, 0.0)))
	var trunk_mesh = st_bark.commit()

	var st_foliage := SurfaceTool.new()
	st_foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c0 := SphereMesh.new()
	c0.radius = 1.7; c0.height = 2.4; c0.radial_segments = 7; c0.rings = 5
	st_foliage.append_from(c0, 0, Transform3D(Basis(), Vector3(0.0, 2.7, 0.0)))

	var c1 := SphereMesh.new()
	c1.radius = 1.4; c1.height = 2.0; c1.radial_segments = 7; c1.rings = 5
	st_foliage.append_from(c1, 0, Transform3D(Basis(), Vector3(0.7, 3.8, 0.4)))

	var c2 := SphereMesh.new()
	c2.radius = 1.4; c2.height = 2.0; c2.radial_segments = 6; c2.rings = 4
	st_foliage.append_from(c2, 0, Transform3D(Basis(), Vector3(-0.7, 3.8, -0.4)))

	var c3 := SphereMesh.new()
	c3.radius = 1.2; c3.height = 1.8; c3.radial_segments = 6; c3.rings = 4
	st_foliage.append_from(c3, 0, Transform3D(Basis(), Vector3(0.1, 4.6, 0.1)))
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

func _create_bush_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bush_mat := StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.24, 0.46, 0.20)
	bush_mat.roughness = 0.85

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s1 := SphereMesh.new()
	s1.radius = 1.1; s1.height = 1.4; s1.radial_segments = 6; s1.rings = 4
	st.append_from(s1, 0, Transform3D(Basis(), Vector3(0.0, 0.6, 0.0)))
	var bush_mesh = st.commit()
	bush_mesh.surface_set_material(0, bush_mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bush_mesh
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
