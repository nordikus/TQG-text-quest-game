extends Node

func _ready() -> void:
	print("==================================================")
	print("--- VERIFY V8: TREE, NATURE TRAIL & ROOF COLLISIONS ---")
	print("==================================================")

	var clearing_scene: PackedScene = load("res://scenes/forest_clearing.tscn")
	if not clearing_scene:
		push_error("Failed to load forest_clearing.tscn")
		get_tree().quit(1)
		return

	var clearing: Node3D = clearing_scene.instantiate() as Node3D
	add_child(clearing)

	# Trigger extinguish outcome in WorldChanger to simulate Nature Trail & Great Tree active
	var wc: Node = clearing.get_node_or_null("WorldChanger")
	if wc and wc.has_method("_apply_extinguish_outcome"):
		print("Activating Nature Trail & Great Tree via WorldChanger...")
		wc._apply_extinguish_outcome()

	# Ensure GreatTree is fully risen at Y = 0.0 for immediate verification
	var tree_node: Node3D = clearing.get_node_or_null("GreatTree") as Node3D
	if tree_node:
		tree_node.position.y = 0.0
		if wc and wc.has_method("_set_collision_recursive"):
			wc._set_collision_recursive(tree_node, true)

	# Wait 3 physics frames for physics space to sync
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state: PhysicsDirectSpaceState3D = clearing.get_world_3d().direct_space_state
	var all_passed: bool = true

	# -------------------------------------------------------------------------
	# 1. VERIFY ROOF COLLISIONS
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Building Roof Collisions ---")
	# Format: [Name, RayOrigin (above roof), RayEnd (inside building)]
	# Note: CastleFacade is at (0, 0, -90).
	# Barracks is at (24, 0, -19) in facade -> world (24, 0, -109)
	# Chapel is at (-22, 0, -2) in facade -> world (-22, 0, -92)
	# Courtyard walls corner SW is at (-36, 7, 8.5) in facade -> world (-36, 7, -81.5)
	# MageTower is at (-26, 0, -20) in facade -> world (-26, 0, -110)
	# MainKeep is at (0, 0, -61) in facade -> world (0, 0, -151)
	var roof_tests: Array = [
		["Barracks Gable Roof", Vector3(24.0, 15.0, -109.0), Vector3(24.0, 5.0, -109.0)],
		["Chapel Gable Roof", Vector3(-22.0, 18.0, -92.0), Vector3(-22.0, 6.0, -92.0)],
		["Courtyard SW Tower Roof", Vector3(-36.0, 22.0, -81.5), Vector3(-36.0, 10.0, -81.5)],
		["Mage Tower Conical Roof", Vector3(-26.0, 36.0, -110.0), Vector3(-26.0, 22.0, -110.0)],
		["Main Keep Roof Slab", Vector3(0.0, 24.0, -151.0), Vector3(0.0, 15.0, -151.0)],
	]

	for test_item in roof_tests:
		var test: Array = test_item as Array
		var r_name: String = test[0]
		var r_from: Vector3 = test[1]
		var r_to: Vector3 = test[2]

		var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(r_from, r_to)
		var res: Dictionary = space_state.intersect_ray(q)
		if res.is_empty():
			push_error("FAIL: Roof collision NOT detected for: " + r_name)
			all_passed = false
		else:
			var col_obj: Object = res["collider"]
			print("PASS: ", r_name, " hit at Y=", snapped(res["position"].y, 0.01), " collider=", col_obj.name)

	# -------------------------------------------------------------------------
	# 2. VERIFY NATURE TRAIL ENTRANCE & WALKWAY
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Nature Trail Entrance & Traversal ---")
	var trail_points: Array[Vector3] = [
		Vector3(-4.5, 0.5, -17.5),
		Vector3(-5.5, 0.5, -21.0),
		Vector3(-6.2, 0.5, -25.0),
		Vector3(-7.5, 0.5, -30.0),
		Vector3(-9.0, 0.5, -35.5),
		Vector3(-11.2, 0.5, -41.0),
		Vector3(-13.8, 0.5, -47.5),
		Vector3(-15.8, 0.5, -52.0),
		Vector3(-17.3, 0.5, -56.8)
	]

	for i in range(trail_points.size()):
		var pt: Vector3 = trail_points[i]
		var q_down: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(pt + Vector3.UP * 1.5, pt + Vector3.DOWN * 2.0)
		var res_down: Dictionary = space_state.intersect_ray(q_down)
		if res_down.is_empty():
			push_error("FAIL: No floor collision under Nature Trail point " + str(i) + " at " + str(pt))
			all_passed = false
		else:
			var floor_y: float = res_down["position"].y
			var col_node: Object = res_down["collider"]
			print("PASS: Nature Trail pt ", i, " floor Y=", snapped(floor_y, 0.01), " col=", col_node.name)

	# Test horizontal clearance walking through entrance from clearing (-3.5, 0.5, -14.0) to (-4.5, 0.5, -18.5)
	var entrance_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(-4.5, 1.0, -14.0), Vector3(-4.5, 1.0, -18.5))
	var ent_res: Dictionary = space_state.intersect_ray(entrance_ray)
	if not ent_res.is_empty():
		var col_node: Object = ent_res["collider"]
		push_error("FAIL: Nature Trail entrance is BLOCKED at: " + str(ent_res["position"]) + " by " + col_node.name)
		all_passed = false
	else:
		print("PASS: Nature Trail entrance is completely clear (no wall blocking)!")

	# -------------------------------------------------------------------------
	# 3. VERIFY GREAT TREE & BOUGH BRIDGE TO MAGE TOWER BALCONY
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Great Tree Walkway & Bough Bridge to Mage Tower ---")
	var tree_waypoints: Array = [
		["Root Entry Ramp", Vector3(-17.05, 0.2, -56.9)],
		["Spiral Step Lower", Vector3(-22.45, 2.26, -56.76)],
		["Spiral Step Mid 1", Vector3(-24.45, 4.55, -60.82)],
		["Spiral Step Mid 2", Vector3(-19.27, 7.60, -63.10)],
		["Spiral Step Mid 3", Vector3(-17.48, 9.13, -60.49)],
		["Spiral Step Upper", Vector3(-23.51, 14.48, -59.82)],
		["Canopy Terrace", Vector3(-21.6, 17.0, -65.2)],
		["Bough Bridge Sta 1", Vector3(-21.13, 18.28, -81.1)],
		["Bough Bridge Sta 2", Vector3(-21.54, 19.13, -90.7)],
		["Bough Bridge Sta 3", Vector3(-22.15, 19.98, -100.25)],
		["Bough Bridge End", Vector3(-22.52, 20.45, -105.6)],
		["Mage Tower Balcony", Vector3(-22.5, 20.0, -107.0)],
		["Observatory Interior Doorway", Vector3(-22.28, 20.0, -107.85)]
	]

	for i in range(tree_waypoints.size()):
		var wp_data: Array = tree_waypoints[i] as Array
		var wp_name: String = wp_data[0]
		var wp_pos: Vector3 = wp_data[1]

		var q_down: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(wp_pos + Vector3.UP * 1.5, wp_pos + Vector3.DOWN * 2.0)
		var res_down: Dictionary = space_state.intersect_ray(q_down)
		if res_down.is_empty():
			push_error("FAIL: No floor collision at tree waypoint: " + wp_name + " at " + str(wp_pos))
			all_passed = false
		else:
			var floor_y: float = res_down["position"].y
			var col_node: Object = res_down["collider"]
			print("PASS: ", wp_name, " floor Y=", snapped(floor_y, 0.01), " collider=", col_node.name)

	# Verify walking along bough bridge across Z=-73 at player torso height (where GreatTreeForestWall was)
	print("\n--- Verifying Z = -73 has NO wall barrier ---")
	var z73_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(-21.0, 19.2, -70.0), Vector3(-21.0, 19.2, -76.0))
	var z73_res: Dictionary = space_state.intersect_ray(z73_ray)
	if not z73_res.is_empty():
		var col_node: Object = z73_res["collider"]
		push_error("FAIL: Bridge at Z=-73 is blocked by: " + col_node.name)
		all_passed = false
	else:
		print("PASS: Bridge at Z=-73 is completely unobstructed!")

	# Verify stepping from Bough Bridge End (-22.52, 20.45, -105.6) onto Balcony (-22.5, 20.0, -107.0)
	print("\n--- Verifying Bridge to Balcony Entry (where BalconyRailingSouth was) ---")
	var entry_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(-22.5, 20.7, -104.5), Vector3(-22.5, 20.7, -107.5))
	var entry_res: Dictionary = space_state.intersect_ray(entry_ray)
	if not entry_res.is_empty():
		var col_node: Object = entry_res["collider"]
		push_error("FAIL: Entry onto balcony is BLOCKED by: " + col_node.name)
		all_passed = false
	else:
		print("PASS: Entry from Bough Bridge onto Mage Tower Balcony is wide open!")

	# -------------------------------------------------------------------------
	# SIMULATE ACTUAL CHARACTERBODY3D WALKING FROM TREE TO BALCONY
	# -------------------------------------------------------------------------
	print("\n--- 4. CharacterBody3D Walk Simulation (Bridge -> Balcony -> Observatory) ---")
	var body: CharacterBody3D = CharacterBody3D.new()
	var body_col: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	body_col.shape = cap
	body.add_child(body_col)
	body_col.position.y = 0.9
	body.floor_snap_length = 0.35
	clearing.add_child(body)

	# Start near end of bridge
	body.global_position = Vector3(-22.52, 20.8, -104.0)
	await get_tree().physics_frame

	var target: Vector3 = Vector3(-22.3, 20.2, -107.5)
	var steps_sim: int = 120
	for step in range(steps_sim):
		var dir: Vector3 = (target - body.global_position)
		dir.y = 0.0
		if dir.length() < 0.15:
			break
		body.velocity = dir.normalized() * 4.0 + Vector3.DOWN * 9.8
		body.move_and_slide()
		await get_tree().physics_frame

	var dist_to_target: float = (Vector2(body.global_position.x, body.global_position.z) - Vector2(target.x, target.z)).length()
	if dist_to_target < 0.35:
		print("PASS: CharacterBody3D successfully walked from bridge onto balcony! Pos: ", body.global_position, " on_floor=", body.is_on_floor())
	else:
		push_error("FAIL: CharacterBody3D got stuck during traversal! Pos: " + str(body.global_position) + " Dist to target: " + str(dist_to_target))
		all_passed = false

	print("\n==================================================")
	if all_passed:
		print("ALL V8 VERIFICATION TESTS PASSED SUCCESSFULLY!")
		print("==================================================")
		get_tree().quit(0)
	else:
		push_error("SOME TESTS FAILED!")
		print("==================================================")
		get_tree().quit(1)
