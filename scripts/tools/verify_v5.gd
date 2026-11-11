extends Node3D

const ARTIFACT_DIR := "C:/Users/nordiko/.gemini/antigravity/brain/d1e7294e-616a-4e05-be16-80c2d1747d6d"

func _ready() -> void:
	print("--- Starting Castle, Courtyard & Inventory Verification ---")
	_run()

func _run() -> void:
	var clearing_scene: PackedScene = load("res://scenes/forest_clearing.tscn")
	var clearing = clearing_scene.instantiate()
	add_child(clearing)

	var castle = clearing.get_node_or_null("CastleFacade")
	assert(castle != null, "CastleFacade must exist in forest_clearing.tscn")

	# Functional assertions
	print("Checking inventory initial state...")
	assert(InventoryManager.items.size() == 0, "Initial items must be empty")
	assert(InventoryManager.notes.size() == 0, "Initial notes must be empty")

	var key_pickup = castle.get_node_or_null("BarracksBuilding/ThroneHallKey")
	assert(key_pickup != null, "KeyPickup (ThroneHallKey) must exist in BarracksBuilding")
	assert(key_pickup.item_id == "throne_hall_key", "KeyPickup must be throne_hall_key")

	var note_pickup = castle.get_node_or_null("BarracksBuilding/CaptainNote")
	assert(note_pickup != null, "NotePickup (CaptainNote) must exist in BarracksBuilding")
	assert(note_pickup.item_id == "guard_captain_note", "NotePickup must be guard_captain_note")

	var chapel_note = castle.get_node_or_null("ChapelBuilding/ChapelNote")
	assert(chapel_note != null, "ChapelNote must exist in ChapelBuilding")
	assert(chapel_note.item_id == "chapel_lore_note", "ChapelNote must be chapel_lore_note")

	var throne_doors = castle.get_node_or_null("MainKeep/ThroneRoomEntranceDoors")
	assert(throne_doors != null, "ThroneRoomEntranceDoors must exist")
	assert(throne_doors.is_locked == true, "Throne doors must be locked initially")
	assert(throne_doors.required_item_id == "throne_hall_key", "Throne doors must require throne_hall_key")

	# Prepare camera and viewport for screenshots
	var vp := get_viewport()
	vp.size = Vector2i(1280, 720)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 70.0
	clearing.add_child(cam)

	# 1. Capture Courtyard Overview (before interactions) - Pure green grass, dirt paths, well
	cam.global_position = Vector3(0.0, 9.0, -82.0)
	cam.look_at(Vector3(0.0, 2.5, -118.0), Vector3.UP)
	cam.fov = 75.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_castle_courtyard_overview.png")
	print("Saved: v6_castle_courtyard_overview.png")

	# 2. Capture Barracks Entrance (Wide 2.8m Doorway, plinth and porch across courtyard)
	cam.global_position = Vector3(8.0, 2.2, -104.0)
	cam.look_at(Vector3(16.3, 1.8, -109.0), Vector3.UP)
	cam.fov = 65.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_barracks_entrance.png")
	print("Saved: v6_barracks_entrance.png")

	# 3. Capture Barracks Interior with Key & Note on Captain's desk
	cam.global_position = Vector3(25.0, 1.35, -114.5)
	cam.look_at(Vector3(25.5, 0.95, -116.0), Vector3.UP)
	cam.fov = 55.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_barracks_interior.png")
	print("Saved: v6_barracks_interior.png")

	# 4. Capture Chapel Interior with Altar, Lore Note & Statue
	cam.global_position = Vector3(-20.5, 1.8, -92.0)
	cam.look_at(Vector3(-28.0, 1.4, -92.0), Vector3.UP)
	cam.fov = 65.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_chapel_interior.png")
	print("Saved: v6_chapel_interior.png")

	# 5. Capture Mage Tower from courtyard
	cam.global_position = Vector3(-6.0, 6.0, -96.0)
	cam.look_at(Vector3(-26.0, 14.0, -110.0), Vector3.UP)
	cam.fov = 75.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_mage_tower_courtyard.png")
	print("Saved: v6_mage_tower_courtyard.png")

	# 6. Functional assertions: Pickup items
	throne_doors.interact()
	assert(throne_doors.is_locked == true, "Door must stay locked without key")
	assert(throne_doors.is_open == false, "Door must stay closed without key")
	print("Verified door locked without key.")

	key_pickup.interact()
	assert(InventoryManager.has_item("throne_hall_key") == true, "Key must be in inventory")
	note_pickup.interact()
	assert(InventoryManager.notes.has("guard_captain_note") == true, "Captain note must be in notes")
	chapel_note.interact()
	assert(InventoryManager.notes.has("chapel_lore_note") == true, "Chapel note must be in notes")
	print("Verified key & notes pickup into inventory.")

	# Capture Inventory UI (Items Tab)
	if GameManager.inventory_panel:
		GameManager.inventory_panel.open_inventory()
		for i in range(15):
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_inventory_items_tab.png")
		print("Saved: v6_inventory_items_tab.png")

		# Capture Inventory UI (Notes Tab)
		GameManager.inventory_panel._on_tab_changed("notes")
		for i in range(15):
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_inventory_notes_tab.png")
		print("Saved: v6_inventory_notes_tab.png")

		GameManager.inventory_panel.close_inventory()
		for i in range(5):
			await get_tree().process_frame

	# Unlock and open throne doors
	throne_doors.interact()
	assert(throne_doors.is_locked == false, "Door must be unlocked after key interact")
	assert(throne_doors.is_open == true, "Door must be open")
	assert(InventoryManager.has_item("throne_hall_key") == false, "Key must be consumed from inventory")
	assert(throne_doors.get_node("DoorBlockerLeft").disabled == true, "Left door blocker must be disabled when open")
	assert(throne_doors.get_node("DoorBlockerRight").disabled == true, "Right door blocker must be disabled when open")
	print("Verified door unlocked, single-use key consumed, and doorway blockers disabled.")

	# 7. Capture Throne Room looking through opened 6.4m wide grand doors
	cam.global_position = Vector3(0.0, 2.2, -128.0)
	cam.look_at(Vector3(0.0, 2.2, -150.0), Vector3.UP)
	cam.fov = 70.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_throne_room_doors_opened.png")
	print("Saved: v6_throne_room_doors_opened.png")

	# 8. Capture Throne Dais up close with raised carpet and closed rear wall
	cam.global_position = Vector3(0.0, 2.2, -143.0)
	cam.look_at(Vector3(0.0, 2.0, -149.0), Vector3.UP)
	cam.fov = 65.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_throne_room_interior.png")
	print("Saved: v6_throne_room_interior.png")

	# 9. Capture Burning Path approach to castle gate (verify no stone pavers on ground)
	var wc = clearing.get_node_or_null("WorldChanger")
	if wc:
		wc._apply_burn_outcome()
		var corr_forest = clearing.get_node_or_null("CorridorForest")
		if corr_forest:
			corr_forest.position.y = -14.0
			corr_forest.visible = false
		cam.global_position = Vector3(2.5, 2.0, -74.0)
		cam.look_at(Vector3(0.0, 3.5, -82.5), Vector3.UP)
		cam.fov = 70.0
		for i in range(15):
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v6_burning_path_gate_approach.png")
		print("Saved: v6_burning_path_gate_approach.png")

	print("--- All V6 verifications passed and screenshots saved ---")
	get_tree().quit(0)
