@tool
extends SceneTree

const Layout := preload("res://scripts/world/forest_layout.gd")

func _initialize() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("==================================================")
	print("--- VERIFY V9: 5 LEVEL DESIGN & TRAVERSAL FIXES ---")
	print("==================================================")

	var clearing_scene: PackedScene = load("res://scenes/forest_clearing.tscn")
	if not clearing_scene:
		push_error("Failed to load forest_clearing.tscn")
		quit(1)
		return

	var clearing: Node3D = clearing_scene.instantiate() as Node3D
	root.add_child(clearing)

	var quests := root.get_node("QuestManager")
	quests.complete_quest("burning_grove", "extinguish_fire")
	await create_timer(3.7).timeout

	var all_passed: bool = true

	# -------------------------------------------------------------------------
	# 1. Forest boundaries and the approach to the Great Tree.
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Open Forest and Great Tree Approach ---")
	if clearing.has_node("OuterRidge") or clearing.has_node("ForestBarrier") or clearing.has_node("NatureBarrier"):
		push_error("FAIL: Old forest walls or barricades still exist.")
		all_passed = false
	for grove in ["ClearingGroves", "CorridorForest", "GateApproachGrove"]:
		for tree in clearing.get_node(grove).get_children():
			if not tree.scene_file_path.ends_with("tree_lowpoly.tscn") and not tree.scene_file_path.ends_with("tree_deciduous_lowpoly.tscn"):
				continue
			var trunk := tree as Node3D
			var point := Vector2(trunk.global_position.x, trunk.global_position.z)
			if Layout.clear_for_life(point, 0.5 * trunk.scale.x):
				push_error("FAIL: Placed tree %s overlaps the living trail or root landing." % trunk.name)
				all_passed = false

	var space_state: PhysicsDirectSpaceState3D = clearing.get_world_3d().direct_space_state
	var ash_mesh := clearing.get_node("BurningPath/BurningPathBody/BurningPathMesh") as MeshInstance3D
	var ash_ground: PackedVector3Array = ash_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for point in ash_ground:
		if point.z < -79.76:
			push_error("FAIL: The baked ash surface extends past the threshold into the paved yard.")
			all_passed = false
			break
	# Test raycasts on ground along Nature Trail where 5m invisible walls used to be
	# Cast horizontal ray across the approach plaza border: must NOT hit any invisible walls!
	var ground_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-14.0, 1.2, -56.8),
		Vector3(-17.3, 1.2, -56.8)
	)
	var g_hit: Dictionary = space_state.intersect_ray(ground_ray)
	if g_hit.is_empty():
		print("PASS: Open air traversal path on Nature Trail approach plaza has NO invisible walls!")
	else:
		push_error("FAIL: Hit invisible obstacle in open air on trail plaza: " + str(g_hit.collider.name) + " at " + str(g_hit.position))
		all_passed = false

	# -------------------------------------------------------------------------
	# 2. TEST ISSUE 2: GREAT TREE LAST STEP / TERRACE LIP
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Great Tree Last Step to Canopy Terrace ---")
	# GreatTree is at (-21, 0, -60).
	# Spiral walkway top step in world coords is around (-21.6, 17.1, -64.2)
	# Terrace center in world coords is around (-21.55, 17.2, -65.2)
	# Cast horizontal ray at Y = 17.4 across the west parapet into terrace floor
	# (Before fix, west parapet was 0.84m high wall blocking this ray)
	var terrace_entry_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-22.8, 17.4, -64.2), # Walkway side
		Vector3(-21.5, 17.4, -64.2)  # Inside terrace
	)
	var t_hit: Dictionary = space_state.intersect_ray(terrace_entry_ray)
	if t_hit.is_empty():
		print("PASS: Canopy Terrace entrance has NO vertical parapet lip blocking player entry!")
	else:
		push_error("FAIL: Parapet wall still blocking terrace entrance: " + str(t_hit.collider.name) + " at " + str(t_hit.position))
		all_passed = false

	# -------------------------------------------------------------------------
	# 3. TEST ISSUE 3: MAGE TOWER SPIRAL STAIRS
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Mage Tower Spiral Stairs Traversal ---")
	# Mage Tower is at world (-30.4, 0, -110) on the western curtain.
	# Sample floor points up the helix from Y = 1.0 to Y = 19.5
	var tower_steps_ok: bool = true
	var revs: float = 3.42
	for s_idx in range(2, 96, 2):
		var t_norm: float = float(s_idx) / 95.0
		var expected_y: float = 0.35 + t_norm * 19.65
		var theta: float = float(s_idx) * (revs * TAU / 95.0)
		var world_x: float = -30.4 + 1.915 * cos(theta)
		var world_z: float = -110.0 + 1.915 * sin(theta)
		# Cast down from 0.5m above expected step surface
		var ray_step := PhysicsRayQueryParameters3D.create(
			Vector3(world_x, expected_y + 0.6, world_z),
			Vector3(world_x, expected_y - 0.6, world_z)
		)
		var s_hit: Dictionary = space_state.intersect_ray(ray_step)
		if s_hit.is_empty():
			push_error("FAIL: Missing floor on Mage Tower spiral stair step " + str(s_idx) + " at Y=" + str(expected_y))
			tower_steps_ok = false
		else:
			var normal: Vector3 = s_hit.normal
			var angle_with_up: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
			if angle_with_up > 35.0:
				push_error("FAIL: Step surface too steep (wall normal): " + str(angle_with_up) + " deg on step " + str(s_idx))
				tower_steps_ok = false

	if tower_steps_ok:
		print("PASS: Mage Tower spiral staircase has continuous, smooth walkable steps all the way to Tier 3!")
	else:
		all_passed = false

	# -------------------------------------------------------------------------
	# 4. TEST ISSUE 4: MAIN KEEP GRAND STAIRCASE & FLOOR 2 HEADROOM CUTOUT
	# -------------------------------------------------------------------------
	print("\n--- 4. Testing Main Keep Grand Staircase & Floor 2 Cutout ---")
	# MainKeep is at world (0, 0, -151).
	# Stairs run at X = -22.5 from Z = -161.5 (local -10.5) to Z = -148.5 (local 2.5).
	# Check vertical clearance (headroom) above the top of the stairs at local Z = 0.0 (world -151.0):
	# Stair floor at Z = 0.0 is at Y = 5.08.
	# Ray cast upwards from stair floor to Y = 10.0: MUST NOT HIT Floor2West!
	var headroom_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-22.5, 5.3, -151.0),
		Vector3(-22.5, 9.0, -151.0)
	)
	var h_hit: Dictionary = space_state.intersect_ray(headroom_ray)
	if h_hit.is_empty():
		print("PASS: Floor2West has OPEN stairwell cutout! No ceiling blocking player headroom above stairs!")
	else:
		push_error("FAIL: Ceiling slab still blocking stairwell headroom: " + str(h_hit.collider.name) + " at " + str(h_hit.position))
		all_passed = false

	# Test stair ramp collision slope through ramp center (world z = -155.0, local z = -4.0):
	var ramp_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-22.5, 5.0, -155.0),
		Vector3(-22.5, 1.0, -155.0)
	)
	var r_hit: Dictionary = space_state.intersect_ray(ramp_ray)
	if r_hit.is_empty():
		push_error("FAIL: No collision ramp found under Grand Staircase!")
		all_passed = false
	else:
		var ramp_angle: float = rad_to_deg(acos(clampf(r_hit.normal.dot(Vector3.UP), -1.0, 1.0)))
		print("Grand Staircase ramp hit at Y=" + str(r_hit.position.y) + " slope angle=" + str(ramp_angle) + " deg")
		if ramp_angle <= 30.0:
			print("PASS: Grand Staircase ramp is smooth and walkable (slope <= 30 deg)!")
		else:
			push_error("FAIL: Grand Staircase ramp too steep: " + str(ramp_angle) + " deg")
			all_passed = false

	# -------------------------------------------------------------------------
	# 5. TEST ISSUE 5: THRONE ROOM ENCLOSED PARTITION WALLS & PORTALS
	# -------------------------------------------------------------------------
	print("\n--- 5. Testing Throne Room Interior Partition Walls & Portals ---")
	# A. West Partition Wall at local X = -13.0 (world -13.0):
	# Ray through solid wall section at local Z = 4.5 (world -146.5, Y = 3.0): MUST HIT WALL!
	var wall_w_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-10.0, 3.0, -146.5),
		Vector3(-16.0, 3.0, -146.5)
	)
	var ww_hit: Dictionary = space_state.intersect_ray(wall_w_ray)
	if not ww_hit.is_empty():
		print("PASS: West interior partition wall cleanly separates Throne Room from West Wing at Z=4.5!")
	else:
		push_error("FAIL: West partition wall is missing at Z=4.5!")
		all_passed = false

	# Portal through West Wall at local Z = -8.5 (world -159.5, Y = 2.5): MUST BE OPEN!
	var portal_w_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-10.0, 2.5, -159.5),
		Vector3(-16.0, 2.5, -159.5)
	)
	var pw_hit: Dictionary = space_state.intersect_ray(portal_w_ray)
	if pw_hit.is_empty():
		print("PASS: West Grand Portal to Staircase Hall is wide open for traversal!")
	else:
		push_error("FAIL: West Grand Portal is blocked by: " + str(pw_hit.collider.name) + " at " + str(pw_hit.position))
		all_passed = false

	# B. East Partition Wall at local X = 13.0 (world 13.0):
	# Ray through solid wall section at local Z = 8.0 (world -143.0, Y = 3.0): MUST HIT WALL!
	var wall_e_ray := PhysicsRayQueryParameters3D.create(
		Vector3(10.0, 3.0, -143.0),
		Vector3(16.0, 3.0, -143.0)
	)
	var we_hit: Dictionary = space_state.intersect_ray(wall_e_ray)
	if not we_hit.is_empty():
		print("PASS: East interior partition wall cleanly separates Throne Room from East Wing at Z=8.0!")
	else:
		push_error("FAIL: East partition wall is missing at Z=8.0!")
		all_passed = false

	# Portal through East Wall at local Z = 0.0 (world -151.0, Y = 2.5): MUST BE OPEN!
	var portal_e_ray := PhysicsRayQueryParameters3D.create(
		Vector3(10.0, 2.5, -151.0),
		Vector3(16.0, 2.5, -151.0)
	)
	var pe_hit: Dictionary = space_state.intersect_ray(portal_e_ray)
	if pe_hit.is_empty():
		print("PASS: East Grand Portal to Royal Banquet Hall is wide open for traversal!")
	else:
		push_error("FAIL: East Grand Portal is blocked by: " + str(pe_hit.collider.name) + " at " + str(pe_hit.position))
		all_passed = false

	# The keep is approachable from outside, but the rear perimeter is closed.
	for x in [-33.2, 0.0, 33.2]:
		var rear_ray := PhysicsRayQueryParameters3D.create(
			Vector3(x, 1.3, -171), Vector3(x, 1.3, -164))
		rear_ray.hit_from_inside = true
		var rear_hit := space_state.intersect_ray(rear_ray)
		if rear_hit.is_empty() or rear_hit.collider.name not in ["RearCurtainWall", "CornerTowerNW", "CornerTowerNE"]:
			push_error("FAIL: The rear curtain does not join the castle perimeter at x=%s." % x)
			all_passed = false

	for z in [-105.83, -114.04]:
		var wall_joint := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-35.20, 1.3, z), Vector3(-29.0, 1.3, z)))
		if wall_joint.is_empty():
			push_error("FAIL: The western curtain must meet the cylindrical tower wall.")
			all_passed = false
	for z in [-140.0, -155.0, -165.0]:
		var library_wall := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-29.6, 4.8, z), Vector3(-32.1, 4.8, z)))
		if library_wall.is_empty() or library_wall.collider.name != "KeepWallWest":
			push_error("FAIL: An exterior buttress or turret penetrates the lower library at z=%s." % z)
			all_passed = false
	var portal := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-37.8, 21.1, -110.25), Vector3(-33.85, 21.1, -110.25)))
	var sill_base := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-36.0, 15.0, -110.25), Vector3(-33.6, 15.0, -110.25)))
	if not portal.is_empty() or sill_base.is_empty() or sill_base.collider.name != "ObservatoryWestBase":
		push_error("FAIL: The forest entry must be clear at floor level and closed beneath the sill.")
		all_passed = false
	var right_guard := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-36.8, 23.6, -108.74), Vector3(-36.8, 20.6, -108.74)))
	if right_guard.is_empty() or right_guard.collider.name != "BalconySouthWindbreak" or right_guard.position.y < 22.2:
		push_error("FAIL: The right side of the balcony must rise continuously above jump height.")
		all_passed = false
	var tower := clearing.find_child("MageTower", true, false) as Node3D
	var sill := tower.get_node("ForestPortalSill/Mesh") as MeshInstance3D
	var hall_floor := tower.get_node("TowerFloor3_North/Mesh") as MeshInstance3D
	var bridge_floor := tower.get_node("CoveredBridge/TowerBridgeDeck/Mesh") as MeshInstance3D
	var stair_floor := tower.get_node("TowerFloor2_West/Mesh") as MeshInstance3D
	var balcony_join := is_equal_approx(_bounds(sill).end.x, _bounds(hall_floor).position.x)
	var bridge_join := is_equal_approx(_bounds(bridge_floor).end.z, _bounds(stair_floor).position.z)
	if not balcony_join or not bridge_join:
		push_error("FAIL: The balcony and bridge thresholds must meet their landings edge to edge.")
		all_passed = false
	var bridge_cornice := tower.get_node("CorniceTier2") as MeshInstance3D
	if _bounds(bridge_cornice).end.y >= _bounds(bridge_floor).end.y:
		push_error("FAIL: The tower cornice projects into the bridge entrance.")
		all_passed = false
	for shelf_name in ["AlcoveShelf_1", "AlcoveShelf_2"]:
		var shelf := clearing.find_child(shelf_name, true, false).get_node("Mesh") as MeshInstance3D
		if _bounds(shelf).end.x >= -25.2:
			push_error("FAIL: A library bookcase reaches into the stairwell.")
			all_passed = false
	var open_sky := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-27.5, 31.0, -110), Vector3(-27.5, 23.0, -110)))
	var covered_roof := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-33.3, 31.0, -110), Vector3(-33.3, 23.0, -110)))
	if not open_sky.is_empty() or covered_roof.is_empty():
		push_error("FAIL: The observatory roof must leave the east quarter open to the sky.")
		all_passed = false

	print("\n==================================================")
	if all_passed:
		print("ALL 5 LEVEL DESIGN & TRAVERSAL ISSUES RESOLVED AND VERIFIED!")
		print("==================================================")
		quit(0)
	else:
		push_error("SOME VERIFICATION CHECKS FAILED!")
		print("==================================================")
		quit(1)

func _bounds(model: MeshInstance3D) -> AABB:
	return model.global_transform * model.get_aabb()
