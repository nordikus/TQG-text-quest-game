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
	# The freestanding observatory has its original stair in local space.
	# Sample floor points up the helix from Y = 1.0 to Y = 19.5
	var tower_steps_ok: bool = true
	var revs: float = 3.42
	for s_idx in range(2, 96, 2):
		var t_norm: float = float(s_idx) / 95.0
		var expected_y: float = 0.35 + t_norm * 19.65
		var theta: float = float(s_idx) * (revs * TAU / 95.0)
		var world_x: float = -23.0 + 1.915 * cos(theta)
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

	if not _verify_east_wing(space_state):
		all_passed = false
	if not _verify_cellar_landing(space_state):
		all_passed = false
	if not _verify_throne_cache(space_state):
		all_passed = false
	if not _verify_gate_wall_walk(space_state):
		all_passed = false

	# Test the new corner joins and the center of the rear curtain.
	for x in [-45.1, -42.1, -32.6, -16.0, 0.0, 16.0, 32.6, 42.1, 45.1]:
		var rear_ray := PhysicsRayQueryParameters3D.create(
			Vector3(x, 1.3, -188), Vector3(x, 1.3, -178))
		var rear_hit := space_state.intersect_ray(rear_ray)
		if rear_hit.is_empty() or rear_hit.collider.name not in ["RearCurtainWall", "CornerTowerNW", "CornerTowerNE",
				"RearEastWatchtower", "RearWestWatchtower"]:
			push_error("FAIL: The rear curtain does not join the castle perimeter at x=%s." % x)
			all_passed = false

	for z in [-98.0, -105.83, -114.04, -130.0, -160.0, -177.0]:
		var wall_hit := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-49.0, 11.3, z), Vector3(-40.9, 11.3, z)))
		if wall_hit.is_empty() or wall_hit.collider.name != "WallWest" or absf(wall_hit.position.x + 45.75) > 0.01:
			push_error("FAIL: The western curtain must have a continuous outer face.")
			all_passed = false
	for z in range(-176, -86):
		var walker := Vector3(-44.0, 14.8, z)
		var foot := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			walker + Vector3.UP * 0.4, walker - Vector3.UP * 0.2))
		var chest := walker + Vector3.UP * 1.55
		var lane := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			chest + Vector3.LEFT * 0.53, chest + Vector3.RIGHT * 0.53))
		if foot.is_empty() or absf(foot.position.y - walker.y) > 0.025 or not lane.is_empty():
			push_error("FAIL: The west guard walk must remain continuous and at least one metre wide.")
			all_passed = false
			break
	var undercrossing := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-30.5, 2.1, -110.12), Vector3(-29.0, 2.1, -110.12)))
	if not undercrossing.is_empty():
		push_error("FAIL: The observatory and the western curtain should have open ground between them.")
		all_passed = false
	for z in [-140.0, -155.0, -165.0]:
		var library_wall := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-26.0, 4.8, z), Vector3(-32.1, 4.8, z)))
		if library_wall.is_empty() or library_wall.collider.name != "KeepWallWest" \
				or absf(library_wall.position.x + 31.6) > 0.03:
			push_error("FAIL: An exterior buttress or turret penetrates the lower library at z=%s." % z)
			all_passed = false
	for side in [Vector2(-44, -100), Vector2(15, -81.5), Vector2(44, -116),
			Vector2(0, -181.5), Vector2(-16, -181.5), Vector2(44, -181.5), Vector2(-44, -181.5)]:
		var foot := Vector3(side.x, 14.8, side.y)
		var crest := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			foot + Vector3.UP * 0.22, foot - Vector3.UP * 0.22))
		if crest.is_empty() or not is_equal_approx(crest.position.y, 14.8):
			push_error("FAIL: All curtain walks should meet the 14.8 m height.")
			all_passed = false
	var keep_back := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(0, 4.0, -172.0), Vector3(0, 4.0, -164.0)))
	var curtain_back := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(0, 4.0, -172.0), Vector3(0, 4.0, -184.0)))
	if (keep_back.is_empty() or curtain_back.is_empty()
			or keep_back.collider.name != "KeepWallNorth" or curtain_back.collider.name != "RearCurtainWall"
			or keep_back.position.z - curtain_back.position.z < 13.0):
		push_error("FAIL: The rear curtain must leave at least thirteen metres of courtyard behind the keep.")
		all_passed = false
	else:
		print("PASS: The rear courtyard is %.2f m deep." % (keep_back.position.z - curtain_back.position.z))
	for direction: float in [-1.0, 1.0]:
		var alley := Vector3(direction * 36.8, 12.0, -157.5)
		var keep_side := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			alley, alley - Vector3.RIGHT * direction * 7.0))
		var curtain_side := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			alley, alley + Vector3.RIGHT * direction * 7.0))
		if (keep_side.is_empty() or curtain_side.is_empty()
				or absf(keep_side.position.x - curtain_side.position.x) < 9.5):
			push_error("FAIL: The side curtains must leave a walkable lane clear of the keep.")
			all_passed = false
	for step in 25:
		var z := lerpf(-67.7, -79.63, float(step) / 24)
		var hit := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-23.0, 19.0, z), Vector3(-23.0, 10.5, z)))
		if hit.is_empty() or hit.collider.name != "TrunkBody" or hit.normal.y < 0.75:
			push_error("FAIL: The living bridge needs continuous footing on one axis toward the front curtain.")
			all_passed = false
			break
	if not _verify_front_breach(space_state):
		all_passed = false
	for step in 29:
		var z := lerpf(-86.20, -105.03, step / 28.0)
		var inside := Vector3(-23.0, 15.6, z)
		var shell := true
		for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.DOWN, Vector3.UP]:
			var hit := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				inside, inside + direction * 3.2))
			if hit.is_empty() or hit.collider.name != "TrunkBody":
				shell = false
		if not shell:
			push_error("FAIL: The visible bark must enclose the route across the courtyard.")
			all_passed = false
			break
	if not _verify_branch_floor_at_fork(space_state):
		all_passed = false
	var tree_model := clearing.get_node("GreatTree/TrunkBody/TreeMesh") as MeshInstance3D
	if not _verify_branch_shell(tree_model.mesh):
		all_passed = false
	var tower := clearing.find_child("MageTower", true, false) as Node3D
	var sill := tower.get_node("SouthEntryLanding/Mesh") as MeshInstance3D
	var bridge_floor := tower.get_node("CoveredBridge/TowerBridgeDeck/Mesh") as MeshInstance3D
	var landing := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-23, 13.55, -105.50), Vector3(-23, 13.0, -105.50)))
	if landing.is_empty() or landing.collider != sill.get_parent() or not _verify_bridge_portal(space_state):
		push_error("FAIL: The entry and library bridge must meet the tower's landings.")
		all_passed = false
	var bridge_cornice := tower.get_node("CorniceTier2") as MeshInstance3D
	if _bounds(bridge_cornice).end.y >= _bounds(bridge_floor).end.y:
		push_error("FAIL: The tower cornice projects into the bridge entrance.")
		all_passed = false
	for shelf_name in ["AlcoveShelf_1", "AlcoveShelf_2"]:
		var shelf := clearing.find_child(shelf_name, true, false)
		var cabinet := shelf.get_node("Cabinet")
		var collider := shelf.get_node("Col") as CollisionShape3D
		var shape := collider.shape as BoxShape3D
		var envelope := collider.global_transform * AABB(-shape.size * 0.5, shape.size)
		for part: VisualInstance3D in cabinet.get_children():
			envelope = envelope.merge(part.global_transform * part.get_aabb())
		if cabinet.get_child_count() == 0 or envelope.end.x >= -25.2:
			push_error("FAIL: A furnished library bookcase is missing or reaches into the stairwell.")
			all_passed = false
	var open_sky := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-20.1, 31.0, -110), Vector3(-20.1, 23.0, -110)))
	var covered_roof := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-25.9, 31.0, -110), Vector3(-25.9, 23.0, -110)))
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

func _verify_branch_shell(model: ArrayMesh) -> bool:
	var indices: PackedInt32Array = model.surface_get_arrays(2)[Mesh.ARRAY_INDEX]
	var edges: Dictionary[Vector2i, int] = {}
	for triangle in range(0, indices.size(), 3):
		for side in 3:
			var from := indices[triangle + side]
			var to := indices[triangle + (side + 1) % 3]
			var edge := Vector2i(mini(from, to), maxi(from, to))
			edges[edge] = edges.get(edge, 0) + 1
	for incidence in edges.values():
		if incidence != 2:
			push_error("FAIL: The outer forks and tunnel must share a closed bark surface.")
			return false
	print("PASS: The courtyard branch has closed bark through both exterior forks.")
	return true

func _verify_branch_floor_at_fork(space: PhysicsDirectSpaceState3D) -> bool:
	# The outer fork joins the shell underneath this stretch of the tunnel.
	for step in 9:
		var center := Vector3(-23.0, 15.8, -96.65 - 0.16 * step)
		var floor := space.intersect_ray(PhysicsRayQueryParameters3D.create(center, center + Vector3.DOWN * 3.0))
		if floor.is_empty() or floor.collider.name != "TrunkBody":
			push_error("FAIL: The tunnel needs a continuous floor above the outer fork.")
			return false
		for edge: float in [-0.82, -0.54, 0.54, 0.82]:
			var at := center + Vector3.RIGHT * edge
			var tread := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 3.0))
			if tread.is_empty() or tread.collider != floor.collider or absf(tread.position.y - floor.position.y) > 0.075:
				push_error("FAIL: The outer fork must stay below the tunnel floor at %s." % at)
				return false
	print("PASS: The outer fork is clear of the tunnel floor.")
	return true

func _verify_front_breach(space: PhysicsDirectSpaceState3D) -> bool:
	var approach := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-23, 16.3, -78.0), Vector3(-23, 16.3, -83.65)))
	var crossing := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-26.0, 16.3, -81.5), Vector3(-20.0, 16.3, -81.5)))
	if not approach.is_empty() or not crossing.is_empty():
		push_error("FAIL: The crest breach blocks the living approach or the wall walk.")
		return false
	for z in [-81.96, -81.5, -81.04]:
		for step in 25:
			var at := Vector3(lerpf(-26.0, -20.0, step / 24.0), 16.3, z)
			var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 1.69))
			if floor_hit.is_empty() or absf(floor_hit.position.y - 14.8) > 0.18:
				push_error("FAIL: The crest needs continuous footing clear of the broken masonry at %s." % at)
				return false
	print("PASS: The open breach and living branch join both halves of the front wall walk.")
	return true

func _verify_bridge_portal(space: PhysicsDirectSpaceState3D) -> bool:
	for z in [-114.16, -114.06, -113.45, -112.55, -111.6, -110.14, -109.52]:
		var threshold := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(-20.35, 6.56, z), Vector3(-20.35, 6.12, z)))
		if threshold.is_empty() or absf(threshold.position.y - 6.35) > 0.03:
			return false
	for z in [-114.2, -113.95, -113.70, -113.45, -113.2, -112.95, -112.68]:
		var center := Vector3(-20.35, 8.0, z)
		for direction in [Vector3.DOWN, Vector3.UP, Vector3.RIGHT]:
			if space.intersect_ray(PhysicsRayQueryParameters3D.create(center, center + direction * 2.5)).is_empty():
				return false
	var path := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-20.35, 7.25, -114.4), Vector3(-20.35, 7.25, -112.75)))
	return path.is_empty()

func _verify_throne_cache(space: PhysicsDirectSpaceState3D) -> bool:
	var sill := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-13.0, 7.46, -137.42), Vector3(-13.0, 6.39, -137.42)))
	var window := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-14.5, 8.20, -137.42), Vector3(-12.0, 8.20, -137.42)))
	var landing := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-11.7, 6.68, -137.42), Vector3(-11.7, 6.1, -137.42)))
	if sill.is_empty() or absf(sill.position.y - 7.08) > 0.03 or not window.is_empty() \
			or landing.is_empty() or landing.collider.name != "EntranceCornice":
		push_error("FAIL: The throne cache needs a jump over the window sill and a solid landing.")
		return false

	var draft := Vector3(-6.65, 6.38, -136.86)
	var shelf_view := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-7.64, 7.95, -137.56), draft))
	if shelf_view.is_empty() or shelf_view.collider.name != "RoyalOrderDraft":
		push_error("FAIL: The royal draft must be reachable from the gallery above the entrance.")
		return false
	print("PASS: The window sill leads to a solid cornice and a reachable royal draft.")
	return true

func _verify_gate_wall_walk(space: PhysicsDirectSpaceState3D) -> bool:
	for x in range(-8, 9):
		var crest := Vector3(x, 14.8, -82.45)
		var floor := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			crest + Vector3.UP * 0.2, crest - Vector3.UP * 0.2))
		if floor.is_empty() or absf(floor.position.y - crest.y) > 0.03:
			push_error("FAIL: The wall walk above the gate must stay level across its full width.")
			return false

	for x in [-5.15, -4.85, 4.85, 5.15]:
		var facade := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(x, 12.0, -77.5), Vector3(x, 12.0, -82.0)))
		if facade.is_empty() or absf(facade.position.z + 79.75) > 0.03:
			push_error("FAIL: The gate masonry must meet both sides of the front curtain in one plane.")
			return false
	print("PASS: The gatehouse meets the curtain and has a continuous wall walk.")
	return true

func _verify_east_wing(space: PhysicsDirectSpaceState3D) -> bool:
	var dining_open := true
	for z in [-151.67, -151.0, -150.33]:
		dining_open = dining_open and space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(11.5, 2.45, z), Vector3(17.0, 2.45, z))).is_empty()
	var doorway_edge := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(11.5, 1.55, -149.65), Vector3(17.0, 1.55, -149.65)))
	if not dining_open or doorway_edge.is_empty():
		push_error("FAIL: The narrow dining passage needs a clear centre and a solid jamb.")
		return false

	for z in [-155.0, -147.0]:
		var above_rail := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(11.7, 8.35, z), Vector3(15.0, 8.35, z)))
		var rail := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(11.7, 6.89, z), Vector3(15.0, 6.89, z)))
		if not above_rail.is_empty() or rail.is_empty() or not str(rail.collider.name).begins_with("BalustradeEast_Loggia"):
			push_error("FAIL: Both dining gallery bays need an open view above a solid balustrade.")
			return false

	var kitchen_door := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(18.07, 1.65, -153.6), Vector3(18.07, 1.65, -155.2)))
	var kitchen_wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(26.0, 1.65, -153.6), Vector3(26.0, 1.65, -155.2)))
	var service_hatch := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(22.53, 1.95, -153.6), Vector3(22.53, 1.95, -155.2)))
	if not kitchen_door.is_empty() or kitchen_wall.is_empty() or not service_hatch.is_empty():
		push_error("FAIL: The kitchen requires its own room and open access from dining.")
		return false

	var service_wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(26.5, 8.0, -160.0), Vector3(23.5, 8.0, -160.0)))
	if service_wall.is_empty() or service_wall.collider.name != "ServiceRoomEastWall":
		push_error("FAIL: The stairwell must not bypass the lock on the service-room doorway.")
		return false
	var gallery_wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(14.5, 8.0, -156.5), Vector3(17.0, 8.0, -156.5)))
	if gallery_wall.is_empty() or gallery_wall.collider.name != "ServiceRoomWestWall":
		push_error("FAIL: The dining gallery must not bypass the lock on the service-room doorway.")
		return false

	for flight in range(2):
		for step in range(1, 16):
			var progress := step / 16.0
			var x := 29.89 if flight == 0 else 26.81
			var z := lerpf(-155.85, -162.25, progress if flight == 0 else 1.0 - progress)
			var grade := 0.25 + 3.05 * (flight + progress)
			var foot := Vector3(x, grade, z)
			var stair := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				foot + Vector3.UP * 0.36, foot - Vector3.UP * 0.36))
			var overhead := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				foot + Vector3.UP * 0.12, foot + Vector3.UP * 2.1))
			var body_name := "ServiceStairLower" if flight == 0 else "ServiceStairUpper"
			if stair.is_empty() or stair.collider.name != body_name or not overhead.is_empty():
				push_error("FAIL: The kitchen stair needs continuous footing and at least 2.1 m of headroom.")
				return false
	for step in range(1, 20):
		var progress := step / 20.0
		var foot := Vector3(16.3, lerpf(0.25, -3.55, progress), lerpf(-157.0, -164.2, progress))
		var stair := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			foot + Vector3.UP * 0.15, foot - Vector3.UP * 0.16))
		var overhead := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			foot + Vector3.UP * 0.15, foot + Vector3.UP * 2.1))
		if stair.is_empty() or stair.collider.name != "CellarStair" or not overhead.is_empty():
			push_error("FAIL: The cellar stair must stay open through the floor and foundation.")
			return false
	print("PASS: The dining entry, service hatch, kitchen stairs and cellar stairs are clear.")
	return true

func _verify_cellar_landing(space: PhysicsDirectSpaceState3D) -> bool:
	var landing := Vector3(16.3, -0.5, -164.4)
	var walls := {
		Vector3.LEFT: "StairWestWall",
		Vector3.RIGHT: "CellarDoorHead",
		Vector3.FORWARD: "StairEndWall",
	}
	for direction: Vector3 in walls:
		var lining := space.intersect_ray(PhysicsRayQueryParameters3D.create(landing, landing + direction * 2.5))
		if lining.is_empty() or lining.collider.name != walls[direction]:
			push_error("FAIL: Stone must cover the foundation at the cellar stair landing.")
			return false
	print("PASS: The cellar landing is enclosed by stone above the doorway.")
	return true
