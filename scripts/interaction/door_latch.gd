class_name DoorLatch
extends Interactable

@export var target_door: InteractableDoor
@export var is_unlatched: bool = false

func _ready():
	super._ready()
	_update_prompt()

func _update_prompt():
	interaction_prompt = "[E] Отодвинуть железный засов" if not is_unlatched else "Засов открыт"

func interact():
	if is_unlatched:
		return
	is_unlatched = true
	_update_prompt()
	GameManager.interaction_prompt_changed.emit(interaction_prompt)
	GameManager.notify("Тяжелый железный засов отодвинут! Дверь отперта.")

	if is_instance_valid(target_door):
		target_door.is_locked = false
		target_door.locked_hint = ""
		target_door._update_prompt()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 0.4, 0.4)
