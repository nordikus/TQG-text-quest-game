extends RayCast3D

var current_target: Node = null

func _physics_process(_delta: float):
	if GameManager.ui_open:
		if current_target:
			current_target = null
			GameManager.interaction_prompt_cleared.emit()
		return

	force_raycast_update()
	var collider := get_collider()

	if collider is Interactable:
		if collider != current_target:
			current_target = collider
			GameManager.interaction_prompt_changed.emit(current_target.get_interaction_prompt())
	elif current_target:
		current_target = null
		GameManager.interaction_prompt_cleared.emit()

func _unhandled_input(event: InputEvent):
	if GameManager.ui_open:
		return
	if event.is_action_pressed("interact") and current_target:
		current_target.interact()
