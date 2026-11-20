class_name ArcaneFocus
extends Interactable

@export var barrier_node: Node3D
@export var is_activated: bool = false
var _barrier_tween: Tween
var _barrier_scale_y := 1.0

func _ready():
	super._ready()
	if is_instance_valid(barrier_node):
		var mesh := barrier_node.get_node_or_null("Mesh") as MeshInstance3D
		if mesh:
			_barrier_scale_y = mesh.scale.y
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
			_barrier_tween = create_tween()
			_barrier_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_barrier_tween.tween_property(mesh_inst, "scale:y", 0.01, 0.6)
			_barrier_tween.finished.connect(func():
				if is_instance_valid(barrier_node):
					barrier_node.visible = false
			)
		else:
			barrier_node.visible = false

func restore_seal() -> void:
	if _barrier_tween:
		_barrier_tween.kill()
	is_activated = false
	_update_prompt()
	if not is_instance_valid(barrier_node):
		return
	var mesh := barrier_node.get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		mesh.scale.y = _barrier_scale_y
	for child in barrier_node.get_children():
		if child is CollisionShape3D:
			child.disabled = false
	barrier_node.show()
