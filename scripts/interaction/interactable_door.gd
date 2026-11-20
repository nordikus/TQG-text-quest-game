class_name InteractableDoor
extends Interactable

const ItemDb = preload("res://scripts/inventory/item_database.gd")

@export var required_item_id: String = ""
@export var locked_hint: String = ""
@export var is_locked: bool = false
@export var is_double_door: bool = false
@export var left_wing: Node3D
@export var right_wing: Node3D
@export var open_angle_deg: float = 90.0
@export var doorway_blockers: Array[CollisionShape3D] = []

var is_open: bool = false
var _initial_left_rot: float = 0.0
var _initial_right_rot: float = 0.0
var _animating: bool = false
var _initial_lock: bool
var _initial_hint: String
var _swing: Tween

func _ready():
	super._ready()
	if not required_item_id.is_empty():
		is_locked = true
	_initial_lock = is_locked
	_initial_hint = locked_hint
	if left_wing:
		_initial_left_rot = left_wing.rotation.y
	if right_wing:
		_initial_right_rot = right_wing.rotation.y

	if doorway_blockers.is_empty():
		for child in get_children():
			if child is CollisionShape3D:
				if child.name.begins_with("DoorBlocker") or child.name == "Col" or child.name == "ColRight":
					doorway_blockers.append(child)

	_update_blockers()
	_update_prompt()

func _update_blockers():
	for blocker in doorway_blockers:
		if is_instance_valid(blocker):
			blocker.disabled = is_open

func _update_prompt():
	if is_locked:
		if not locked_hint.is_empty():
			interaction_prompt = "[E] Заперто (%s)" % locked_hint
		else:
			var def := ItemDb.get_item(required_item_id)
			var item_title: String = def.get("title", "ключ") if not def.is_empty() else "ключ"
			interaction_prompt = "[E] Открыть (требуется: %s)" % item_title
	else:
		interaction_prompt = "[E] Закрыть двери" if is_open else "[E] Открыть двери"

func interact():
	if _animating:
		return

	if is_locked:
		if not required_item_id.is_empty() and InventoryManager.has_item(required_item_id):
			is_locked = false
			InventoryManager.use_item(required_item_id)
			_toggle_door()
		else:
			if not locked_hint.is_empty():
				GameManager.notify("Заперто: " + locked_hint)
			else:
				var def := ItemDb.get_item(required_item_id)
				var item_title: String = def.get("title", "ключ") if not def.is_empty() else "ключ"
				GameManager.notify("Заперто. Нужен: " + item_title)
			_update_prompt()
			GameManager.interaction_prompt_changed.emit(interaction_prompt)
		return

	_toggle_door()

func _toggle_door():
	_animating = true
	is_open = not is_open
	_update_blockers()
	_update_prompt()
	GameManager.interaction_prompt_changed.emit(interaction_prompt)

	_swing = create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_swing.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var target_left_rad := _initial_left_rot + (deg_to_rad(-open_angle_deg) if is_open else 0.0)
	if left_wing:
		_swing.tween_property(left_wing, "rotation:y", target_left_rad, 0.7)

	if is_double_door and right_wing:
		var target_right_rad := _initial_right_rot + (deg_to_rad(open_angle_deg) if is_open else 0.0)
		_swing.tween_property(right_wing, "rotation:y", target_right_rad, 0.7)

	_swing.finished.connect(func(): _animating = false)

func restore_door() -> void:
	if _swing:
		_swing.kill()
	_animating = false
	is_open = false
	is_locked = _initial_lock
	locked_hint = _initial_hint
	if left_wing:
		left_wing.rotation.y = _initial_left_rot
	if right_wing:
		right_wing.rotation.y = _initial_right_rot
	_update_blockers()
	_update_prompt()
