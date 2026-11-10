extends Node3D

@export var great_tree: Node3D
@export var nature_trail: Node3D
@export var forest_barrier: Node3D
@export var charred_forest_zone: Node3D
@export var fire_particles_group: Node3D
@export var burning_path: Node3D
@export var ambient_light: DirectionalLight3D
@export var corridor_forest: Node3D
@export var nature_corridor_forest: Node3D
@export var nature_barrier: Node3D

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	
	if great_tree:
		great_tree.visible = false
		great_tree.position.y = -35.0
		_set_collision_recursive(great_tree, false)
	
	if nature_trail:
		nature_trail.visible = false
		_set_collision_recursive(nature_trail, false)
	
	if charred_forest_zone:
		charred_forest_zone.visible = false
	
	if fire_particles_group:
		fire_particles_group.visible = false
	
	if burning_path:
		burning_path.visible = false
		_set_collision_recursive(burning_path, false)

func _on_quest_completed(quest_id: String, ending_id: String):
	if quest_id != "burning_grove":
		return
		
	match ending_id:
		"extinguish_fire":
			_apply_extinguish_outcome()
		"pass_by":
			_apply_burn_outcome()

func _apply_extinguish_outcome():
	if burning_path:
		burning_path.visible = false
		_set_collision_recursive(burning_path, false)
	if charred_forest_zone:
		charred_forest_zone.visible = false
	if fire_particles_group:
		fire_particles_group.visible = false

	if nature_trail:
		nature_trail.visible = true
		_set_collision_recursive(nature_trail, true)

	if great_tree:
		great_tree.visible = true
		_set_collision_recursive(great_tree, true)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(great_tree, "position:y", 0.0, 3.5)

	if nature_corridor_forest:
		var tween_ncorr := create_tween()
		tween_ncorr.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween_ncorr.tween_property(nature_corridor_forest, "position:y", -14.0, 2.5)
		tween_ncorr.finished.connect(func(): nature_corridor_forest.visible = false)

	if nature_barrier:
		var tween_nbar := create_tween()
		tween_nbar.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween_nbar.tween_property(nature_barrier, "position:y", -6.0, 3.0)
		tween_nbar.finished.connect(func():
			if is_instance_valid(nature_barrier):
				nature_barrier.queue_free()
		)

func _apply_burn_outcome():
	if great_tree:
		great_tree.visible = false
		_set_collision_recursive(great_tree, false)
	if nature_trail:
		nature_trail.visible = false
		_set_collision_recursive(nature_trail, false)

	if fire_particles_group:
		fire_particles_group.visible = true
	
	if burning_path:
		burning_path.visible = true
		_set_collision_recursive(burning_path, true)
		
	if charred_forest_zone:
		charred_forest_zone.visible = true
		
	if corridor_forest:
		var tween_corr := create_tween()
		tween_corr.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween_corr.tween_property(corridor_forest, "position:y", -14.0, 2.5)
		tween_corr.finished.connect(func(): corridor_forest.visible = false)

	if forest_barrier:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(forest_barrier, "position:y", -6.0, 3.0)
		tween.finished.connect(func():
			if is_instance_valid(forest_barrier):
				forest_barrier.queue_free()
		)

	if ambient_light:
		var tween := create_tween()
		tween.tween_property(ambient_light, "light_color", Color(1.0, 0.65, 0.4), 2.0)

func _set_collision_recursive(node: Node, enabled: bool) -> void:
	if not node:
		return
	if node is CollisionShape3D:
		node.disabled = not enabled
	elif node is CollisionPolygon3D:
		node.disabled = not enabled
	for child in node.get_children():
		_set_collision_recursive(child, enabled)
