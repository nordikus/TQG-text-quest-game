class_name ThronePedestal
extends Interactable

@export var quest_id: String = "deal_at_the_throne"
@export var book_node: Node3D
@export var quill_pickup: Node3D
@export var pedestal_light: OmniLight3D

func _ready() -> void:
	super._ready()
	_update_state()
	QuestManager.quest_completed.connect(_on_quest_completed)

func _update_state() -> void:
	if not QuestManager.is_quest_completed(quest_id):
		interaction_prompt = "[E] Прочесть книгу: Сделка у Трона"
		if book_node:
			book_node.visible = true
		if quill_pickup:
			quill_pickup.visible = false
			_set_collision(quill_pickup, false)
		if pedestal_light:
			pedestal_light.light_color = Color(1.0, 0.85, 0.45, 1.0)
	else:
		interaction_prompt = ""
		var ending := QuestManager.get_quest_ending(quest_id)
		if ending == "accept_deal":
			if book_node:
				book_node.visible = false
			if quill_pickup and is_instance_valid(quill_pickup):
				quill_pickup.visible = true
				_set_collision(quill_pickup, true)
			if pedestal_light:
				pedestal_light.light_color = Color(0.85, 0.45, 1.0, 1.0)
		else:
			if book_node:
				book_node.visible = true
			if quill_pickup:
				quill_pickup.visible = false
				_set_collision(quill_pickup, false)

func _on_quest_completed(completed_id: String, ending_id: String) -> void:
	if completed_id != quest_id:
		return

	interaction_prompt = ""
	if ending_id == "accept_deal":
		if book_node:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(book_node, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
			tween.finished.connect(func():
				if is_instance_valid(book_node):
					book_node.visible = false
			)
		if quill_pickup and is_instance_valid(quill_pickup):
			quill_pickup.visible = true
			quill_pickup.scale = Vector3(0.01, 0.01, 0.01)
			_set_collision(quill_pickup, true)
			var q_tween := create_tween()
			q_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			q_tween.tween_property(quill_pickup, "scale", Vector3(1.0, 1.0, 1.0), 0.6)
		if pedestal_light:
			var l_tween := create_tween()
			l_tween.tween_property(pedestal_light, "light_color", Color(0.85, 0.45, 1.0, 1.0), 0.8)
			l_tween.parallel().tween_property(pedestal_light, "light_energy", 3.5, 0.8)
		GameManager.notify("Сделка принята! На постаменте появилось Великое перо.")
	else:
		GameManager.notify("Сделка отвергнута. История запечатана.")

	GameManager.interaction_prompt_cleared.emit()

func interact() -> void:
	if not QuestManager.is_quest_completed(quest_id):
		GameManager.open_quest(quest_id)

func _set_collision(node: Node, enabled: bool) -> void:
	if not node:
		return
	if node is CollisionShape3D:
		node.disabled = not enabled
	for child in node.get_children():
		_set_collision(child, enabled)
