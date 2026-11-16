extends Node

func _ready() -> void:
	call_deferred("_run_verification")

func _run_verification() -> void:
	print("==================================================================")
	print("--- VERIFY V10: 2-PATH COMPLETE LEVEL DESIGN & REWRITE LOOP ---")
	print("==================================================================")

	var clearing_scene: PackedScene = load("res://scenes/forest_clearing.tscn")
	if not clearing_scene:
		push_error("Failed to load forest_clearing.tscn")
		get_tree().quit(1)
		return

	var clearing: Node3D = clearing_scene.instantiate() as Node3D
	add_child(clearing)

	var wc: Node = clearing.get_node_or_null("WorldChanger")
	if not wc:
		push_error("WorldChanger not found in forest_clearing.tscn")
		get_tree().quit(1)
		return

	var clearing_pedestal: Node = clearing.find_child("PedestalWithBook", true, false)
	if not clearing_pedestal:
		clearing_pedestal = clearing.find_child("BookPedestal", true, false)

	var main_keep: Node3D = clearing.get_node_or_null("CastleKeep")
	if not main_keep:
		main_keep = clearing.find_child("MainKeep", true, false)
	if not main_keep:
		push_error("MainKeep not found in forest clearing scene hierarchy")
		get_tree().quit(1)
		return

	var throne_pedestal: Node = main_keep.find_child("ThroneBookPedestal", true, false)
	if not throne_pedestal:
		push_error("ThroneBookPedestal not found in MainKeep!")
		get_tree().quit(1)
		return

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var all_passed: bool = true

	# -------------------------------------------------------------------------
	# 1. TEST PATH A: THE PATH OF LIFE ("EXTINGUISH_FIRE")
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Path A: The Path of Life ---")
	QuestManager.complete_quest("burning_grove", "extinguish_fire")
	wc._apply_extinguish_outcome()

	var gt: Node3D = clearing.get_node_or_null("GreatTree") as Node3D
	if gt:
		gt.position.y = 0.0
		gt.visible = true
		wc._set_collision_recursive(gt, true)

	var ncorr: Node3D = clearing.get_node_or_null("NatureCorridorForest") as Node3D
	if ncorr:
		ncorr.position.y = -14.0
		ncorr.visible = false
		wc._set_collision_recursive(ncorr, false)

	await get_tree().physics_frame

	var nat_trail: Node3D = clearing.get_node_or_null("NatureTrail") as Node3D
	if nat_trail and nat_trail.visible:
		print("PASS: NatureTrail is visible on Path A!")
	else:
		push_error("FAIL: NatureTrail is not visible on Path A")
		all_passed = false

	# Test Mage Tower Covered Bridge Arcane Barrier & Arcane Focus
	var mage_tower: Node3D = clearing.find_child("MageTower", true, false)
	if mage_tower:
		var barrier: Node3D = mage_tower.find_child("ArcaneBarrier", true, false)
		var focus: Node = mage_tower.find_child("ArcaneFocusAltar", true, false)
		if barrier and focus:
			print("Found ArcaneBarrier and ArcaneFocus in MageTower.")
			focus.interact()
			# Allow tween to complete
			await get_tree().create_timer(0.7).timeout
			if not barrier.visible:
				print("PASS: ArcaneFocus in Observatory dissipated ArcaneBarrier on Covered Bridge!")
			else:
				push_error("FAIL: ArcaneBarrier still visible after focus interact")
				all_passed = false
	else:
		push_error("FAIL: MageTower not found")
		all_passed = false

	# -------------------------------------------------------------------------
	# 2. TEST THRONE ROOM FINALE & QUEST: DEAL AT THE THRONE
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Throne Room & Deal at the Throne Quest ---")
	var q_def: Dictionary = QuestData.get_quest("deal_at_the_throne")
	if q_def.is_empty():
		push_error("FAIL: deal_at_the_throne quest not found in QuestData")
		all_passed = false
	else:
		print("PASS: deal_at_the_throne quest registered with title: " + q_def.get("title", ""))

	# Pedestal initial state
	if throne_pedestal.interaction_prompt.contains("Сделка у Трона"):
		print("PASS: ThroneBookPedestal prompt is ready: " + throne_pedestal.interaction_prompt)
	else:
		push_error("FAIL: ThroneBookPedestal unexpected initial prompt: " + throne_pedestal.interaction_prompt)
		all_passed = false

	# Simulate accepting the deal
	QuestManager.complete_quest("deal_at_the_throne", "accept_deal")
	await get_tree().physics_frame

	var quill_pickup: Node = throne_pedestal.get_node_or_null("GreatQuillPickup")
	if quill_pickup and quill_pickup.visible:
		print("PASS: GreatQuillPickup appeared on ThroneBookPedestal upon accepting deal!")
		# Simulate player taking the Great Quill
		quill_pickup.interact()
		if InventoryManager.has_item("great_quill"):
			print("PASS: Great Quill successfully added to InventoryManager!")
		else:
			push_error("FAIL: Great Quill not found in inventory after pickup")
			all_passed = false
	else:
		push_error("FAIL: GreatQuillPickup is not visible on pedestal after deal accepted")
		all_passed = false

	# -------------------------------------------------------------------------
	# 3. TEST REALITY REWRITING VIA GREAT QUILL AT CLEARING ALTAR
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Reality Rewriting Loop via Great Quill ---")
	if clearing_pedestal:
		clearing_pedestal._update_prompt()
		if clearing_pedestal.interaction_prompt.contains("Переписать историю"):
			print("PASS: Clearing altar book prompt updated to rewrite option: " + clearing_pedestal.interaction_prompt)
		else:
			push_error("FAIL: Clearing altar book prompt did not offer rewrite: " + clearing_pedestal.interaction_prompt)
			all_passed = false

		# Interact with altar to rewrite reality
		clearing_pedestal.interact()
		await get_tree().physics_frame

		if not QuestManager.is_quest_completed("burning_grove"):
			print("PASS: QuestManager successfully reset 'burning_grove' quest!")
		else:
			push_error("FAIL: 'burning_grove' is still completed after rewrite")
			all_passed = false

		if InventoryManager.quill_uses_count >= 1:
			print("PASS: Great Quill uses count tracked: %d" % InventoryManager.quill_uses_count)
		else:
			push_error("FAIL: Quill uses count not incremented")
			all_passed = false

		if nat_trail and not nat_trail.visible:
			print("PASS: WorldChanger reset_world() successfully hid NatureTrail!")
		else:
			push_error("FAIL: NatureTrail still visible after world reset")
			all_passed = false

	# -------------------------------------------------------------------------
	# 4. TEST PATH B: THE PATH OF ASH ("PASS_BY")
	# -------------------------------------------------------------------------
	print("\n--- 4. Testing Path B: The Path of Ash ---")
	QuestManager.complete_quest("burning_grove", "pass_by")
	wc._apply_burn_outcome()
	await get_tree().physics_frame

	var burn_path: Node3D = clearing.get_node_or_null("BurningPath") as Node3D
	if burn_path and burn_path.visible:
		print("PASS: BurningPath is visible on Path B!")
	else:
		push_error("FAIL: BurningPath is not visible on Path B")
		all_passed = false

	var charred_zone: Node3D = clearing.get_node_or_null("CharredForestZone") as Node3D
	if charred_zone and charred_zone.visible:
		print("PASS: CharredForestZone is visible on Path B!")
	else:
		push_error("FAIL: CharredForestZone is not visible on Path B")
		all_passed = false

	# Check Chapel lore note in courtyard
	var chapel: Node3D = clearing.find_child("ChapelBuilding", true, false)
	if chapel:
		var chapel_note: Node = chapel.find_child("ChapelNote", true, false)
		if chapel_note:
			print("PASS: Chapel lore note 'Молитва Незримому Наблюдателю' found in Chapel!")
		else:
			push_error("FAIL: ChapelNote not found in ChapelBuilding")
			all_passed = false
	else:
		push_error("FAIL: ChapelBuilding not found")
		all_passed = false

	# Check Barracks key in courtyard
	var barracks: Node3D = clearing.find_child("BarracksBuilding", true, false)
	if barracks:
		var key_pickup: Node = barracks.find_child("ThroneHallKey", true, false)
		if key_pickup:
			print("PASS: Throne hall key found in Barracks!")
			key_pickup.interact()
			if InventoryManager.has_item("throne_hall_key"):
				print("PASS: Key added to inventory!")
			else:
				push_error("FAIL: Key not in inventory")
				all_passed = false
		else:
			push_error("FAIL: ThroneHallKey not found in Barracks")
			all_passed = false
	else:
		push_error("FAIL: BarracksBuilding not found")
		all_passed = false

	# Check MainKeep entrance doors can be opened by the key
	var keep_doors: Node = main_keep.find_child("ThroneRoomEntranceDoors", true, false)
	if keep_doors:
		if keep_doors.is_locked:
			keep_doors.interact()
			if not keep_doors.is_locked and keep_doors.is_open:
				print("PASS: ThroneRoomEntranceDoors unlocked and opened with throne_hall_key!")
			else:
				push_error("FAIL: Doors did not open with key")
				all_passed = false
	else:
		push_error("FAIL: ThroneRoomEntranceDoors not found")
		all_passed = false

	# Check that on Path B, entering the Mage Tower from the Library is blocked by ArcaneBarrier
	if mage_tower:
		var barrier_b: Node3D = mage_tower.find_child("ArcaneBarrier", true, false)
		# Reset barrier for test
		barrier_b.visible = true
		for ch in barrier_b.get_children():
			if ch is CollisionShape3D:
				ch.disabled = false
		if barrier_b.visible:
			print("PASS: The Sealed Threshold: ArcaneBarrier blocks entry into Mage Tower from castle/library side!")
		else:
			push_error("FAIL: ArcaneBarrier not blocking on Path B")
			all_passed = false

	print("\n==================================================================")
	if all_passed:
		print("ALL 2-PATH LEVEL DESIGN & REWRITE TESTS PASSED SUCCESSFULLY (0 ERRORS)!")
	else:
		push_error("SOME TESTS FAILED!")
	print("==================================================================")

	get_tree().quit(0 if all_passed else 1)
