extends Node3D

const ARTIFACT_DIR := "C:/Users/nordiko/.gemini/antigravity/brain/d1e7294e-616a-4e05-be16-80c2d1747d6d"

func _ready() -> void:
	print("--- Starting Castle & Mage Tower Interior Verification (V7) ---")
	_run()

func _run() -> void:
	var clearing_scene: PackedScene = load("res://scenes/forest_clearing.tscn")
	var clearing = clearing_scene.instantiate()
	add_child(clearing)

	var castle = clearing.get_node_or_null("CastleFacade")
	assert(castle != null, "CastleFacade must exist in forest_clearing.tscn")

	var tower = castle.get_node_or_null("MageTower")
	assert(tower != null, "MageTower must exist in CastleFacade")

	var keep = castle.get_node_or_null("MainKeep")
	assert(keep != null, "MainKeep must exist in CastleFacade")

	var barracks = castle.get_node_or_null("BarracksBuilding")
	assert(barracks != null, "BarracksBuilding must exist in CastleFacade")

	var chapel = castle.get_node_or_null("ChapelBuilding")
	assert(chapel != null, "ChapelBuilding must exist in CastleFacade")

	# Check new nodes in MageTower
	var altar_focus = tower.get_node_or_null("ArcaneFocusAltar")
	assert(altar_focus != null, "ArcaneFocusAltar must exist in MageTower")
	assert(altar_focus.is_activated == false, "ArcaneFocusAltar must be inactive initially")

	var star_shard = tower.get_node_or_null("StarCrystalShard")
	assert(star_shard != null, "StarCrystalShard must exist in MageTower")
	assert(star_shard.item_id == "star_crystal_shard", "Shard must be star_crystal_shard")

	var astro_journal = tower.get_node_or_null("AstromancerJournal")
	assert(astro_journal != null, "AstromancerJournal must exist in MageTower")
	assert(astro_journal.item_id == "astromancer_journal", "Journal must be astromancer_journal")

	var barrier = tower.get_node_or_null("ArcaneBarrier")
	assert(barrier != null, "ArcaneBarrier must exist in MageTower")
	var barrier_col = barrier.get_node_or_null("Col")
	assert(barrier_col != null, "ArcaneBarrier must have Col")
	assert(barrier_col.disabled == false, "Barrier col must be enabled initially")

	var tower_door = tower.get_node_or_null("TowerCourtyardDoor")
	assert(tower_door != null, "TowerCourtyardDoor must exist")
	assert(tower_door.is_locked == true, "Tower courtyard door must be locked initially")

	var tower_latch = tower.get_node_or_null("TowerDoorLatch")
	assert(tower_latch != null, "TowerDoorLatch must exist")
	assert(tower_latch.is_unlatched == false, "Tower latch must be latched initially")

	# Check new nodes in MainKeep (Royal Library)
	var chronicle_note = keep.get_node_or_null("ChronicleOfTheFire")
	assert(chronicle_note != null, "ChronicleOfTheFire must exist in MainKeep")
	assert(chronicle_note.item_id == "chronicle_of_the_fire", "Chronicle must be chronicle_of_the_fire")

	var scholars_desk = keep.get_node_or_null("ScholarsDesk")
	assert(scholars_desk != null, "ScholarsDesk must exist in MainKeep")

	var throne_doors = keep.get_node_or_null("ThroneRoomEntranceDoors")
	assert(throne_doors != null, "ThroneRoomEntranceDoors must exist")

	print("Node hierarchy assertions passed.")

	# Camera setup for visual captures
	var vp = get_viewport()
	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)

	# 1. Capture Observatory Interior (Altar, floating crystal, shard, journal)
	# Tower is at world (-26.0, 0.0, -110.0)
	cam.global_position = Vector3(-24.2, 21.8, -108.5)
	cam.look_at(Vector3(-26.0, 21.4, -110.0), Vector3.UP)
	cam.fov = 70.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_observatory_interior.png")
	print("Saved: v7_observatory_interior.png")

	# 2. Capture Spiral Staircase looking down from Tier 3
	cam.global_position = Vector3(-26.0, 20.8, -108.8)
	cam.look_at(Vector3(-26.0, 16.0, -110.0), Vector3.UP)
	cam.fov = 75.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_spiral_staircase_view.png")
	print("Saved: v7_spiral_staircase_view.png")

	# 3. Capture Covered Bridge with Glowing Arcane Barrier
	# Bridge is at X = -26.0, Y = 7.8, Z from -113.8 to -136.0 (midpoint Z = -124.9)
	cam.global_position = Vector3(-26.0, 7.8, -118.0)
	cam.look_at(Vector3(-26.0, 7.8, -125.0), Vector3.UP)
	cam.fov = 70.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_covered_bridge_barrier.png")
	print("Saved: v7_covered_bridge_barrier.png")

	# 4. Capture Royal Library & Arcane Study in MainKeep Floor 2 West
	# Keep is at world (0.0, 0.0, -151.0), Floor 2 West is centered at (-22.5, 6.22, -151.0)
	cam.global_position = Vector3(-16.0, 8.2, -145.0)
	cam.look_at(Vector3(-24.0, 7.2, -151.0), Vector3.UP)
	cam.fov = 70.0
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_royal_library_interior.png")
	print("Saved: v7_royal_library_interior.png")

	# Functional Assertions: Pickups & Inventory
	assert(InventoryManager.items.size() == 0, "Items must start empty")
	assert(InventoryManager.notes.size() == 0, "Notes must start empty")

	star_shard.interact()
	assert(InventoryManager.has_item("star_crystal_shard") == true, "Must have star_crystal_shard in items")

	astro_journal.interact()
	assert(InventoryManager.notes.has("astromancer_journal") == true, "Must have astromancer_journal in notes")

	chronicle_note.interact()
	assert(InventoryManager.notes.has("chronicle_of_the_fire") == true, "Must have chronicle_of_the_fire in notes")
	print("Verified all 3 new items collected into inventory.")

	# Capture Inventory UI
	if GameManager.inventory_panel:
		GameManager.inventory_panel.open_inventory()
		for i in range(15):
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_inventory_items_tab.png")
		print("Saved: v7_inventory_items_tab.png")

		GameManager.inventory_panel._on_tab_changed("notes")
		for i in range(15):
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_inventory_notes_tab.png")
		print("Saved: v7_inventory_notes_tab.png")

		GameManager.inventory_panel.close_inventory()
		for i in range(5):
			await get_tree().process_frame

	# Functional Assertion: Arcane Focus dispels the barrier
	barrier.interact() # Direct inspection prompt notice
	assert(barrier_col.disabled == false, "Barrier must be active before focus interaction")

	altar_focus.interact()
	assert(altar_focus.is_activated == true, "Altar focus must be activated")
	assert(barrier_col.disabled == true, "Barrier collider must be disabled after focus interaction")
	for i in range(25):
		await get_tree().process_frame
	assert(barrier.visible == false, "Barrier mesh must be hidden after tween")
	print("Verified Arcane Focus dispels barrier.")

	# Capture Bridge with Dispeled Barrier (Open passage to Library)
	cam.global_position = Vector3(-26.0, 7.8, -118.0)
	cam.look_at(Vector3(-26.0, 7.8, -135.0), Vector3.UP)
	for i in range(15):
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ARTIFACT_DIR + "/v7_covered_bridge_opened.png")
	print("Saved: v7_covered_bridge_opened.png")

	# Functional Assertion: Tower Door Latch
	tower_door.interact()
	assert(tower_door.is_open == false, "Door must stay closed when latched")
	assert(tower_door.is_locked == true, "Door must stay locked when latched")

	tower_latch.interact()
	assert(tower_latch.is_unlatched == true, "Latch must be unlatched")
	assert(tower_door.is_locked == false, "Door must be unlocked after unlatching")

	tower_door.interact()
	assert(tower_door.is_open == true, "Door must open after unlatching")
	print("Verified Tower Door unlatched and opened.")

	print("--- All V7 verifications passed and screenshots saved successfully! ---")
	get_tree().quit(0)
