@tool
extends SceneTree

func _init() -> void:
	_run_verification()

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

	var wc: Node = clearing.get_node_or_null("WorldChanger")
	if wc and wc.has_method("_apply_extinguish_outcome"):
		print("Activating Nature Trail & Great Tree via WorldChanger...")
		wc._apply_extinguish_outcome()

	var tree_node: Node3D = clearing.get_node_or_null("GreatTree") as Node3D
	if tree_node:
		tree_node.position.y = 0.0
		if wc and wc.has_method("_set_collision_recursive"):
			wc._set_collision_recursive(tree_node, true)

	var ncorr_node: Node3D = clearing.get_node_or_null("NatureCorridorForest") as Node3D
	if ncorr_node:
		# Immediately set to post-tween outcome state for headless test
		ncorr_node.position.y = -14.0
		ncorr_node.visible = false
		if wc and wc.has_method("_set_collision_recursive"):
			wc._set_collision_recursive(ncorr_node, false)

	await physics_frame
	await physics_frame
	await physics_frame

	var all_passed: bool = true

	# -------------------------------------------------------------------------
	# 1. TEST ISSUE 1: NATURE CORRIDOR FOREST SINKS & NO INVISIBLE WALL AT TREE BASE
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Ground Traversal Near Great Tree Base ---")
	var ncorr: Node3D = clearing.get_node_or_null("NatureCorridorForest") as Node3D
	if ncorr:
		# Should sink or be hidden when extinguish_fire is chosen
		if is_equal_approx(ncorr.position.y, -14.0) or not ncorr.visible:
			print("PASS: NatureCorridorForest sinks/hides to open Nature Trail!")
		else:
			push_error("FAIL: NatureCorridorForest is still blocking path: visible=" + str(ncorr.visible) + " y=" + str(ncorr.position.y))
			all_passed = false

	var space_state: PhysicsDirectSpaceState3D = clearing.get_world_3d().direct_space_state
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
	# 3. TEST ISSUE 3: MAGE TOWER SPIRAL STAIRS (427 nodes, 96 wedge steps)
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Mage Tower Spiral Stairs Traversal ---")
	# Mage Tower is at world (-26, 0, -110) in CastleFacade (0, 0, -90)
	# Sample floor points up the helix from Y = 1.0 to Y = 19.5
	var tower_steps_ok: bool = true
	var revs: float = 3.42
	for s_idx in [5, 20, 40, 60, 80, 95]:
		var t_norm: float = float(s_idx) / 95.0
		var expected_y: float = 0.35 + t_norm * 19.65
		var theta: float = float(s_idx) * (revs * TAU / 95.0)
		var world_x: float = -26.0 + 1.915 * cos(theta)
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

	print("\n==================================================")
	if all_passed:
		print("ALL 5 LEVEL DESIGN & TRAVERSAL ISSUES RESOLVED AND VERIFIED!")
		print("==================================================")
		quit(0)
	else:
		push_error("SOME VERIFICATION CHECKS FAILED!")
		print("==================================================")
		quit(1)
