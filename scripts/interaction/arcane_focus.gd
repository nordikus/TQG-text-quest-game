class_name ArcaneFocus
extends Interactable

@export var barrier_node: Node3D
@export var is_activated: bool = false

func _ready():
	super._ready()
	_update_prompt()

func _update_prompt():
	interaction_prompt = "[E] Коснуться Звездного Алтаря" if not is_activated else "Печать Цитадели рассеяна"

func interact():
	if is_activated:
		return
	is_activated = true
	_update_prompt()
	GameManager.interaction_prompt_changed.emit(interaction_prompt)
	GameManager.notify("Печать Цитадели рассеяна! Мост в библиотеку открыт.")

	if is_instance_valid(barrier_node):
		for child in barrier_node.get_children():
			if child is CollisionShape3D:
				child.disabled = true
		var mesh_inst = barrier_node.get_node_or_null("Mesh")
		if mesh_inst:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(mesh_inst, "scale:y", 0.01, 0.6)
			tween.finished.connect(func():
				if is_instance_valid(barrier_node):
					barrier_node.visible = false
			)
		else:
			barrier_node.visible = false
