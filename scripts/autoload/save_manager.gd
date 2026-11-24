extends Node

const LEVEL := "res://scenes/forest_clearing.tscn"
const MAIN_MENU := "res://scenes/ui/game_menu.tscn"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL := 300.0
const SLOT_FILES := {"manual": "manual.cfg", "auto": "autosave.cfg"}

var _level: Node3D
var _pending: Dictionary = {}
var _changing_scene := false
var _active_seconds := 0.0
var _retry_in := 0.0
var _save_directory := "user://saves"

func _process(delta: float) -> void:
	if not is_instance_valid(_level) or _changing_scene or get_tree().paused:
		return
	_active_seconds += delta
	if _active_seconds < AUTOSAVE_INTERVAL:
		return
	_retry_in -= delta
	if _retry_in > 0.0 or GameManager.ui_open or not can_save():
		return
	if _save_slot("auto"):
		_active_seconds = 0.0
		GameManager.notify("Автосохранение записано.")
	else:
		_retry_in = 30.0
		GameManager.notify("Не удалось записать сохранение.")

func attach_level(level: Node3D) -> void:
	_level = level
	_active_seconds = _pending.get("auto_elapsed", 0.0)
	_retry_in = 0.0
	if not _pending.is_empty():
		var world := level.get_node("WorldChanger")
		world.restore_outcome(QuestManager.get_quest_ending("burning_grove"))
		for path: String in _pending["interactions"]:
			var node := level.get_node_or_null(NodePath(path))
			if node is Interactable and node.has_method("apply_save_state"):
				node.apply_save_state(_pending["interactions"][path])
		for pickup in get_tree().get_nodes_in_group("interactable"):
			if pickup is PickupItem and level.is_ancestor_of(pickup):
				pickup.restore_loaded_pickup()
		var player := level.get_node("Player") as CharacterBody3D
		player.global_position = _pending["position"]
		player.rotation.y = _pending["yaw"]
		player.get_node("Camera3D").rotation.x = _pending["pitch"]
		player.reset_physics_interpolation()
	_pending.clear()
	_changing_scene = false

func start_new_game() -> bool:
	return _enter_level({})

func load_slot(slot: String) -> bool:
	var data := _read_slot(slot)
	return not data.is_empty() and _enter_level(data)

func _enter_level(data: Dictionary) -> bool:
	if _changing_scene:
		return false
	if get_tree().change_scene_to_file(LEVEL) != OK:
		return false
	_changing_scene = true
	get_tree().paused = false
	GameManager.ui_open = false
	_pending = data
	QuestManager.completed_quests = data.get("quests", {})
	InventoryManager.items.assign(data.get("items", []))
	InventoryManager.notes.assign(data.get("notes", []))
	InventoryManager.quill_uses_count = data.get("quill_uses", 0)
	return true

func return_to_menu() -> bool:
	if _changing_scene or get_tree().change_scene_to_file(MAIN_MENU) != OK:
		return false
	get_tree().paused = false
	GameManager.ui_open = false
	_level = null
	return true

func can_save() -> bool:
	return (not _changing_scene and is_instance_valid(_level)
		and _level.get_node("Player").is_on_floor() and _level.get_node("WorldChanger").is_settled())

func save_manual() -> bool:
	return can_save() and _save_slot("manual")

func slot_info(slot: String) -> Dictionary:
	var data := _read_slot(slot)
	if data.is_empty():
		return {"valid": false, "exists": FileAccess.file_exists(_slot_path(slot))}
	return {
		"valid": true, "exists": true,
		"timestamp": data["timestamp"],
		"ending": data["quests"].get("burning_grove", ""),
	}

func latest_slot() -> String:
	var manual := slot_info("manual")
	var automatic := slot_info("auto")
	if not manual["valid"]:
		return "auto" if automatic["valid"] else ""
	if automatic["valid"] and automatic["timestamp"] > manual["timestamp"]:
		return "auto"
	return "manual"

func _save_slot(slot: String) -> bool:
	var player := _level.get_node("Player") as CharacterBody3D
	var interactions := {}
	for node in get_tree().get_nodes_in_group("interactable"):
		if _level.is_ancestor_of(node) and node.has_method("get_save_state"):
			interactions[String(_level.get_path_to(node))] = node.get_save_state()
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "progress", {
		"timestamp": Time.get_unix_time_from_system(),
		"position": player.global_position,
		"yaw": player.rotation.y,
		"pitch": player.get_node("Camera3D").rotation.x,
		"quests": QuestManager.completed_quests,
		"items": InventoryManager.items,
		"notes": InventoryManager.notes,
		"quill_uses": InventoryManager.quill_uses_count,
		"interactions": interactions,
		"auto_elapsed": 0.0 if slot == "auto" else minf(_active_seconds, AUTOSAVE_INTERVAL),
	})
	var path := _slot_path(slot)
	var temporary := path + ".tmp"
	if DirAccess.make_dir_recursive_absolute(_save_directory) != OK or config.save(temporary) != OK:
		return false
	return DirAccess.rename_absolute(temporary, path) == OK

func _read_slot(slot: String) -> Dictionary:
	if not SLOT_FILES.has(slot):
		return {}
	var config := ConfigFile.new()
	if config.load(_slot_path(slot)) != OK or config.get_value("save", "version", 0) != SAVE_VERSION:
		return {}
	var data: Variant = config.get_value("save", "progress", {})
	if not data is Dictionary or not _is_valid(data):
		return {}
	return data

func _slot_path(slot: String) -> String:
	return _save_directory.path_join(SLOT_FILES[slot])

func _is_valid(data: Dictionary) -> bool:
	var position: Variant = data.get("position")
	if not position is Vector3 or not position.is_finite():
		return false
	for key in ["timestamp", "yaw", "pitch", "auto_elapsed"]:
		var value: Variant = data.get(key)
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(value):
			return false
	if not data.get("quests") is Dictionary or not data.get("interactions") is Dictionary:
		return false
	var quests: Dictionary = data["quests"]
	if quests.get("burning_grove", "") not in ["", "extinguish_fire", "pass_by"]:
		return false
	if quests.get("deal_at_the_throne", "") not in ["", "accept_deal", "reject_deal"]:
		return false
	if not data.get("quill_uses") is int or data["quill_uses"] < 0:
		return false
	if not data.get("items") is Array or not data.get("notes") is Array:
		return false
	for item in data["items"]:
		if not item is Dictionary or not item.get("id") is String or not item.get("remaining_uses") is int:
			return false
	for note in data["notes"]:
		if not note is String:
			return false
	for path in data["interactions"]:
		if not path is String or not data["interactions"][path] is Dictionary:
			return false
		for state in data["interactions"][path].values():
			if not state is bool:
				return false
	return true
