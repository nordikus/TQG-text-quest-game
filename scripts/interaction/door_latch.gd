class_name DoorLatch
extends Interactable

@export var target_door: InteractableDoor
@export var is_unlatched: bool = false
@onready var _initial_y := position.y
@onready var _latch_shape := get_node_or_null("Col") as CollisionShape3D
var _slide: Tween

func _ready():
	super._ready()
	_update_prompt()

func _update_prompt():
	interaction_prompt = "[E] Отодвинуть железный засов" if not is_unlatched else "Засов открыт"

func interact():
	if is_unlatched:
		return
	is_unlatched = true
	if _latch_shape:
		_latch_shape.disabled = true
	_update_prompt()
	GameManager.interaction_prompt_changed.emit(interaction_prompt)
	GameManager.notify("Тяжелый железный засов отодвинут! Дверь отперта.")

	if is_instance_valid(target_door):
		target_door.is_locked = false
		target_door._update_prompt()

	_slide = create_tween()
	_slide.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slide.tween_property(self, "position:y", _initial_y + 0.4, 0.4)

func restore_latch() -> void:
	if _slide:
		_slide.kill()
	position.y = _initial_y
	is_unlatched = false
	if _latch_shape:
		_latch_shape.disabled = false
	_update_prompt()
	if is_instance_valid(target_door):
		target_door.restore_door()
