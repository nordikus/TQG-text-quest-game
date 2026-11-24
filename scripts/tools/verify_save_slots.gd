extends SceneTree

const ItemDb := preload("res://scripts/inventory/item_database.gd")

var _save: Node
var _quest: Node
var _inventory: Node
var _temp: DirAccess
var _passed := true

func _initialize() -> void:
	_verify.call_deferred()

func _verify() -> void:
	_save = root.get_node("SaveManager")
	_quest = root.get_node("QuestManager")
	_inventory = root.get_node("InventoryManager")
	_temp = DirAccess.create_temp("tqg-save-test")
	_save._save_directory = _temp.get_current_dir()
	change_scene_to_file(_save.MAIN_MENU)
	await scene_changed
	TranslationServer.set_locale("ru")
	_check(TranslationServer.translate("Новая игра") == "Новая игра", "Russian keeps the original menu text.")
	TranslationServer.set_locale("en")
	var items_translated := true
	for item: Dictionary in ItemDb.ITEMS.values():
		for field in ["title", "description"]:
			items_translated = items_translated and TranslationServer.translate(item[field]) != item[field]
	_check(items_translated, "Every item and journal entry has an English title and description.")
	_check(_save.latest_slot().is_empty(), "Fresh slots are empty.")
	_press_button(current_scene, "Новая игра")
	await scene_changed
	await _frames(10)
	var player := current_scene.get_node("Player") as CharacterBody3D
	var world := current_scene.get_node("WorldChanger")
	var panel := player.get_node("QuestPanel")
	panel.open_quest("burning_grove")
	_check(panel.title_label.text == "The Burning Grove" and panel.choices_container.get_child(0).text == "Put out the fire",
		"An English quest and its choice appear in the actual quest UI.")
	panel.close_quest()
	_quest.complete_quest("burning_grove", "pass_by")
	await create_timer(3.7).timeout
	_inventory.add_item("throne_hall_key")
	_inventory.add_item("star_crystal_shard")
	_inventory.add_item("chapel_lore_note")
	_inventory.add_item("great_quill")
	_inventory.use_item("great_quill")
	_quest.complete_quest("deal_at_the_throne", "accept_deal")
	world.keep_door.interact()
	world.rune_chest.interact()
	await create_timer(0.8).timeout
	player.global_position = Vector3(7, 0.06, -129.5)
	player.rotation.y = 1.12
	player.get_node("Camera3D").rotation.x = -0.31
	await _frames(12)
	await _press_escape()
	_check(paused and player.get_node("../GameMenu").visible, "Escape opens the in-game pause menu.")
	var menu := current_scene.get_node("GameMenu")
	_press_button(menu, "Сохранить игру")
	_press_button(menu, "Сохранить")
	_check(_save.slot_info("manual").get("ending") == "pass_by", "The pause menu writes the manual Ash save.")
	_press_button(menu, "Сохранить")
	_press_button(menu, "Да")
	_check(_save.slot_info("manual")["valid"], "Confirming replacement rewrites the manual slot.")
	var manual_position := player.global_position
	var clock: float = _save._active_seconds
	await create_timer(0.20).timeout
	_check(is_equal_approx(clock, _save._active_seconds), "Paused time does not count toward autosave.")
	await _press_escape()
	_check(not paused, "Escape resumes gameplay.")

	_quest.reset_quest("burning_grove")
	world.reset_world()
	_quest.complete_quest("burning_grove", "extinguish_fire")
	await create_timer(3.75).timeout
	world.bridge_seal.interact()
	await create_timer(0.6).timeout
	player.global_position = Vector3(-10.0, 0.2, -32.0)
	await _frames(16)
	_save._active_seconds = _save.AUTOSAVE_INTERVAL - 0.12
	_check(not _save.slot_info("auto")["exists"], "The autosave slot is empty before the interval.")
	await create_timer(0.36).timeout
	_check(_save.slot_info("auto").get("ending") == "extinguish_fire" and _save.latest_slot() == "auto",
		"Five-minute autosave writes the Life route to its own slot.")
	_check(_save.slot_info("manual").get("ending") == "pass_by", "Autosave leaves the manual save intact.")

	await _press_escape()
	var pause_menu := current_scene.get_node("GameMenu")
	_press_button(pause_menu, "Загрузить игру")
	_press_button(pause_menu, "Загрузить")
	_press_button(pause_menu, "Да")
	await scene_changed
	await _frames(12)
	world = current_scene.get_node("WorldChanger")
	player = current_scene.get_node("Player")
	_check(player.global_position.is_equal_approx(manual_position) and absf(player.rotation.y - 1.12) < 0.01
		and absf(player.get_node("Camera3D").rotation.x + 0.31) < 0.01,
		"The manual load restores position and view direction.")
	_check(world.outer_gate.is_raised and world.outer_gate.position.y > 5.5
		and world.keep_door.is_open and not world.keep_door.is_locked and not world.rune_chest.get_node("Seal").visible,
		"The Ash gate, open door and opened chest are restored.")
	_check(_inventory.quill_uses_count == 1 and _inventory.notes.has("chapel_lore_note")
		and _inventory.notes.has("captains_sealed_report") and _inventory.has_item("throne_hall_key")
		and current_scene.find_child("GreatQuillPickup", true, false) == null,
		"Inventory, journal and the collected Quill survive reloading without duplicates.")
	_check(current_scene.get_node("CastleFacade/MainKeep/Observer").visible, "The Observer is restored from the rewrite count.")

	_check(_save.return_to_menu(), "Returning to the title screen succeeds.")
	await scene_changed
	_press_button(current_scene, "Продолжить")
	await scene_changed
	await _frames(12)
	world = current_scene.get_node("WorldChanger")
	_check(world.great_tree.visible and world.great_tree.position.y == 0.0 and world.wall_breach.visible
		and not world.outer_gate.is_raised and not world.bridge_seal.visible,
		"Continue restores the latest autosave, its Life geometry and its opened seal.")

	_check(_save.start_new_game(), "A fresh game starts after playing a saved game.")
	await scene_changed
	await _frames(12)
	_check(_quest.completed_quests.is_empty() and _inventory.items.is_empty() and _inventory.notes.is_empty()
		and _inventory.quill_uses_count == 0 and _save.slot_info("manual")["valid"] and _save.slot_info("auto")["valid"],
		"New Game clears the run and preserves both on-disk slots.")
	var unreadable := ConfigFile.new()
	unreadable.set_value("save", "version", -1)
	unreadable.save(_save._slot_path("manual"))
	_check(not _save.load_slot("manual") and _save.latest_slot() == "auto"
		and _quest.completed_quests.is_empty(), "An incompatible save leaves the active run intact.")
	quit(0 if _passed else 1)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _press_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()

func _press_button(menu: Node, source: String) -> void:
	for button: Button in menu.find_children("*", "Button", true, false):
		if button.text == source and not button.disabled and button.is_visible_in_tree():
			button.pressed.emit()
			return
	_check(false, "Menu button exists: " + source)
	quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		push_error("FAIL: " + message)
		_passed = false
