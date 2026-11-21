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
	Vector2(7.5, -75),
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

			# Keep the original sampling sequence around both story paths.
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

	persistent_pines = persistent_pines.filter(_outside_castle)
	persistent_oaks = persistent_oaks.filter(_outside_castle)
	corridor_pines = corridor_pines.filter(_outside_castle)
	corridor_oaks = corridor_oaks.filter(_outside_castle)
	undergrowth_transforms = undergrowth_transforms.filter(_outside_castle)

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

	ResourceSaver.save(mm_pers_pines.mesh, "res://scenes/world/pine_model.res", ResourceSaver.FLAG_COMPRESS)
	ResourceSaver.save(mm_pers_oaks.mesh, "res://scenes/world/deciduous_model.res", ResourceSaver.FLAG_COMPRESS)
	print("Saved the five grove batches and two individual tree models.")
	quit(0)

func _outside_castle(placement: Transform3D) -> bool:
	return not Layout.CASTLE_TREE_CLEARANCE.has_point(Vector2(placement.origin.x, placement.origin.z))

func _create_pine_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bark := _surface()
	_stem(bark, Vector3(0, -0.055, 0), Vector3(0.04, 1.48, 0.02), 0.41, 0.29, 7)
	_stem(bark, Vector3(0.04, 1.43, 0.02), Vector3(-0.17, 3.68, 0.08), 0.30, 0.085, 6)
	_stem(bark, Vector3(0.03, 1.25, 0), Vector3(0.76, 1.74, -0.15), 0.14, 0.047, 5)
	_stem(bark, Vector3(0.02, 1.53, 0.02), Vector3(-0.83, 2.0, 0.26), 0.12, 0.041, 5)
	_root_flares(bark, 0.74)

	var needles := _surface()
	_bough(needles, Vector3(0.06, 1.73, 0.02), 1.77, 0.37, 1.58, 0.01)
	_bough(needles, Vector3(-0.13, 2.65, 0.16), 1.49, 0.31, 1.62, 0.24)
	_bough(needles, Vector3(-0.11, 3.57, 0.06), 1.08, 0.18, 1.59, 0.49)
	_bough(needles, Vector3(-0.26, 4.44, 0.09), 0.72, 0.0, 1.42, 0.76)
	return _multimesh(_tree_mesh(bark, needles, Color(0.13, 0.29, 0.19), Color(0.36, 0.49, 0.26)), transforms)

func _create_oak_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var bark := _surface()
	_stem(bark, Vector3(0, -0.055, 0), Vector3(-0.06, 1.88, 0.09), 0.52, 0.35, 7)
	_stem(bark, Vector3(-0.07, 1.80, 0.09), Vector3(0.06, 4.13, 0.16), 0.32, 0.11, 6)
	_stem(bark, Vector3(-0.08, 1.70, 0.07), Vector3(-1.09, 3.39, -0.48), 0.22, 0.096, 6)
	_stem(bark, Vector3(-0.05, 2.22, 0.15), Vector3(1.17, 3.32, 0.45), 0.23, 0.091, 6)
	_stem(bark, Vector3(-0.31, 2.28, -0.08), Vector3(-0.74, 2.85, 0.88), 0.13, 0.053, 5)
	_root_flares(bark, 1.0)

	var leaves := _surface()
	_crown(leaves, Vector3(-1.12, 3.42, -0.32), Vector3(1.29, 0.71, 1.02), 0.46)
	_crown(leaves, Vector3(1.10, 3.44, 0.38), Vector3(1.45, 0.87, 1.20), 0.8)
	_crown(leaves, Vector3(-0.62, 3.07, 1.02), Vector3(1.05, 0.72, 1.04), 1.26)
	_crown(leaves, Vector3(0.02, 4.10, -0.68), Vector3(1.47, 0.94, 1.08), 1.67)
	_crown(leaves, Vector3(-0.16, 4.65, 0.18), Vector3(1.35, 0.89, 1.19), 2.09)
	return _multimesh(_tree_mesh(bark, leaves, Color(0.20, 0.34, 0.15), Color(0.47, 0.55, 0.24)), transforms)

func _create_bush_multimesh(transforms: Array[Transform3D]) -> MultiMesh:
	var leaves := _surface()
	_crown(leaves, Vector3(-0.34, 0.36, 0.12), Vector3(0.72, 0.51, 0.54), 0.26)
	_crown(leaves, Vector3(0.52, 0.51, -0.12), Vector3(0.67, 0.58, 0.59), 0.91)
	_crown(leaves, Vector3(0.06, 0.72, 0.10), Vector3(0.65, 0.46, 0.58), 1.40)
	leaves.set_material(_foliage(Color(0.17, 0.30, 0.15), Color(0.42, 0.49, 0.20)))
	return _multimesh(leaves.commit(), transforms)

func _tree_mesh(bark: SurfaceTool, leaves: SurfaceTool, base: Color, tips: Color) -> ArrayMesh:
	var trunk_material := ShaderMaterial.new()
	trunk_material.shader = preload("res://scenes/world/forest_bark.gdshader")
	bark.set_material(trunk_material)
	leaves.set_material(_foliage(base, tips))
	return leaves.commit(bark.commit())

func _foliage(base: Color, tips: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://scenes/world/forest_leaves.gdshader")
	material.set_shader_parameter("leaf_base", base)
	material.set_shader_parameter("leaf_tip", tips)
	return material

func _surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	return surface

func _root_flares(surface: SurfaceTool, size: float) -> void:
	for i in 4:
		var direction := Vector3(sin(i * 1.56), 0, cos(i * 1.56))
		_stem(surface, Vector3.UP * 0.44, direction * (0.61 + i * 0.054) * size + Vector3.DOWN * 0.037,
			0.144 * size, 0.022 * size, 5)

func _stem(surface: SurfaceTool, low: Vector3, top: Vector3, start_radius: float, end_radius: float, sides: int) -> void:
	var tube := CylinderMesh.new()
	tube.bottom_radius = start_radius
	tube.top_radius = end_radius
	tube.height = low.distance_to(top)
	tube.radial_segments = sides
	tube.rings = 0
	var axis := (top - low).normalized()
	var bend := Basis(Quaternion(Vector3.UP, axis))
	surface.append_from(tube, 0, Transform3D(bend, (low + top) * 0.5))

func _bough(surface: SurfaceTool, at: Vector3, lower_radius: float, upper_radius: float, height: float, variant: float) -> void:
	var needles := CylinderMesh.new()
	needles.bottom_radius = lower_radius
	needles.top_radius = upper_radius
	needles.height = height
	needles.radial_segments = 7
	needles.rings = 0
	var spread := Basis.from_euler(Vector3(0.13 * sin(variant * 9.0), variant, 0.10 * cos(variant * 6.0)))
	surface.append_from(needles, 0, Transform3D(spread.scaled_local(Vector3(1, 1, 0.87)), at))

func _crown(surface: SurfaceTool, at: Vector3, size: Vector3, variant: float) -> void:
	var cluster := SphereMesh.new()
	cluster.radius = 1.0
	cluster.height = 2.0
	cluster.radial_segments = 7
	cluster.rings = 3
	var basis := Basis.from_euler(Vector3(0.24 * sin(variant), variant, 0.28 * cos(variant * 2.0))).scaled_local(size)
	surface.append_from(cluster, 0, Transform3D(basis, at))

func _multimesh(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	var packed := PackedFloat32Array()
	for placement in transforms:
		var frame := placement.basis
		var origin := placement.origin
		packed.append_array(PackedFloat32Array([
			frame.x.x, frame.y.x, frame.z.x, origin.x,
			frame.x.y, frame.y.y, frame.z.y, origin.y,
			frame.x.z, frame.y.z, frame.z.z, origin.z,
		]))
	batch.buffer = packed
	return batch
