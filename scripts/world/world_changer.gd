extends Node3D

@export var great_tree: Node3D
@export var wall_infill: Node3D
@export var wall_breach: Node3D
@export var tower_infill: Node3D
@export var tower_breach: Node3D
@export var nature_trail: Node3D
@export var charred_forest_zone: Node3D
@export var fire_particles_group: Node3D
@export var burning_path: Node3D
@export var ambient_light: DirectionalLight3D
@export var corridor_forest: Node3D
@export var forest_trunks: Node3D
@export var outer_gate: CourtyardGate
@export var world_environment: WorldEnvironment
@export var bridge_seal: ArcaneBarrier
@export var shard: PickupItem
@export var rune_chest: Interactable
@export var rune_barrel: Interactable
@export var intact_bridge: Node3D
@export var collapsed_bridge: Node3D
@export var courtyard_roots: Node3D
@export var castle_life: Node3D
@export var castle_ash: Node3D
@export var castle_verge: Node3D
@export var castle_embers: Node3D
@export var courtyard_surfaces: Array[MeshInstance3D]
@export var court_lanterns: Node3D
@export var life_thicket: Node3D
@export var ash_thicket: Node3D
@export var living_arches: Node3D
@export var keep_door: InteractableDoor
@export var service_room_door: InteractableDoor
@export var keep_key: PickupItem

var _transitions: Array[Tween] = []
var _initial_light_color: Color
var _initial_fog_color: Color
var _initial_fog_density: float
var _active_ending := ""

func _ready() -> void:
	QuestManager.quest_completed.connect(_on_quest_completed)
	if ambient_light:
		_initial_light_color = ambient_light.light_color
	if world_environment and world_environment.environment:
		world_environment.environment = world_environment.environment.duplicate()
		var environment := world_environment.environment
		_initial_fog_color = environment.fog_light_color
		_initial_fog_density = environment.fog_density
	if great_tree:
		great_tree.position.y = -35.0
	_set_enabled(great_tree, false)
	_set_enabled(nature_trail, false)
	_set_burned_forest(false)
	_reset_landmarks()
	_set_castle_state(false, false)

func _on_quest_completed(quest_id: String, ending_id: String) -> void:
	if quest_id != "burning_grove" or ending_id == _active_ending:
		return
	if not _active_ending.is_empty():
		reset_world()
	_active_ending = ending_id
	match ending_id:
		"extinguish_fire":
			_apply_extinguish_outcome()
		"pass_by":
			_apply_burn_outcome()

func restore_outcome(ending_id: String) -> void:
	_active_ending = ending_id
	match ending_id:
		"extinguish_fire": _apply_extinguish_outcome(false)
		"pass_by": _apply_burn_outcome(false)

func is_settled() -> bool:
	if outer_gate and outer_gate.is_moving():
		return false
	for tween in _transitions:
		if tween.is_running():
			return false
	return true

func _apply_extinguish_outcome(animate := true) -> void:
	_cancel_transitions()
	_set_enabled(nature_trail, true)
	_set_enabled(life_thicket, false)
	if great_tree:
		great_tree.show()
		if animate:
			SoundEffects.play_at(&"tree_grow", nature_trail, -13.0)
			_move_vertical(great_tree, 0.0, 3.5).finished.connect(_open_tree_route)
		else:
			_open_tree_route()
	if living_arches:
		for i in living_arches.get_child_count():
			var arch := living_arches.get_child(i) as Node3D
			if animate:
				_track_tween().tween_property(arch, "position:y", 0.0, 0.92) \
					.set_delay(0.24 + i * 0.44).set_trans(Tween.TRANS_SINE)
			else:
				arch.position.y = 0.0
	_set_burned_forest(false)
	_set_castle_state(true, false)
	_set_atmosphere(false, animate)

func _open_tree_route() -> void:
	great_tree.position.y = 0.0
	_set_collision_recursive(great_tree, true)
	_set_wall_breach(true)

func _apply_burn_outcome(animate := true) -> void:
	_cancel_transitions()
	if great_tree:
		great_tree.position.y = -35.0
	_set_enabled(great_tree, false)
	_set_enabled(ash_thicket, false)
	_set_burned_forest(true)
	if fire_particles_group:
		for i in fire_particles_group.get_child_count():
			var fire: Node3D = fire_particles_group.get_child(i)
			if animate:
				fire.hide()
				_track_tween().tween_callback(_ignite.bind(fire)).set_delay(i * 0.13)
			else:
				_ignite(fire)
	_set_castle_state(false, true)
	_set_atmosphere(true, animate)
	if outer_gate:
		if animate:
			_track_tween().tween_callback(outer_gate.set_raised.bind(true)).set_delay(0.65)
		else:
			outer_gate.set_raised(true, false)

func reset_world() -> void:
	_active_ending = ""
	_cancel_transitions()
	_lower_obstacle(great_tree, -35.0, 2.0)
	_set_enabled(nature_trail, false)
	_set_burned_forest(false)
	_set_atmosphere(false)
	_reset_landmarks()
	_set_castle_state(false, false)
	if outer_gate:
		outer_gate.set_raised(false, false)
	if keep_door:
		keep_door.restore_door()
	if service_room_door:
		service_room_door.restore_door()
	if keep_key:
		keep_key.restore_pickup()
	if shard:
		shard.restore_pickup()
	if rune_chest:
		rune_chest.restore_seal()
	if rune_barrel:
		rune_barrel.restore_seal()

func _reset_landmarks() -> void:
	_set_enabled(life_thicket, true)
	_set_enabled(ash_thicket, true)
	if living_arches:
		for child: Node3D in living_arches.get_children():
			child.position.y = -5.0

func _set_castle_state(life: bool, burned: bool) -> void:
	for surface in courtyard_surfaces:
		var material := surface.get_active_material(0) as ShaderMaterial
		if material:
			material.set_shader_parameter("courtyard_burned", burned)
	if not life:
		_set_wall_breach(false)
	_set_enabled(courtyard_roots, life)
	_set_enabled(castle_life, life)
	_set_enabled(castle_ash, burned)
	_set_enabled(castle_verge, not burned)
	if castle_embers:
		for fire in castle_embers.get_children():
			fire.set_active(burned)
	_set_enabled(court_lanterns, not burned)
	_set_enabled(intact_bridge, not burned)
	_set_enabled(collapsed_bridge, burned)
	if bridge_seal:
		bridge_seal.restore_seal(life)

func _set_wall_breach(opened: bool) -> void:
	_set_enabled(wall_infill, not opened)
	_set_enabled(wall_breach, opened)
	_set_enabled(tower_infill, not opened)
	_set_enabled(tower_breach, opened)

func _ignite(fire: Node3D) -> void:
	fire.show()
	fire.set_active(true)

func _lower_obstacle(obstacle: Node3D, depth: float, duration: float) -> void:
	if not obstacle:
		return
	_set_collision_recursive(obstacle, false)
	if obstacle.visible:
		_move_vertical(obstacle, depth, duration).finished.connect(obstacle.hide)

func _move_vertical(node: Node3D, height: float, duration: float) -> Tween:
	var tween := _track_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", height, duration)
	return tween

func _set_burned_forest(burned: bool) -> void:
	_set_enabled(burning_path, burned)
	_set_enabled(charred_forest_zone, burned)
	_set_enabled(corridor_forest, not burned)
	if forest_trunks:
		forest_trunks.set_burned(burned)
	if fire_particles_group:
		fire_particles_group.visible = burned
		for fire in fire_particles_group.get_children():
			fire.set_active(false)

func _set_atmosphere(burned: bool, animate := true) -> void:
	var tween := _track_tween().set_parallel(true) if animate else null
	if ambient_light:
		var sunlight := Color(1.0, 0.67, 0.42) if burned else _initial_light_color
		if animate:
			tween.tween_property(ambient_light, "light_color", sunlight, 1.7)
		else:
			ambient_light.light_color = sunlight
	if world_environment and world_environment.environment:
		var environment := world_environment.environment
		var fog_color := Color(0.58, 0.36, 0.27) if burned else _initial_fog_color
		var fog_density := 0.0065 if burned else _initial_fog_density
		if animate:
			tween.tween_property(environment, "fog_light_color", fog_color, 1.7)
			tween.tween_property(environment, "fog_density", fog_density, 1.7)
		else:
			environment.fog_light_color = fog_color
			environment.fog_density = fog_density

func _track_tween() -> Tween:
	var tween := create_tween()
	_transitions.append(tween)
	return tween

func _cancel_transitions() -> void:
	for tween in _transitions:
		tween.kill()
	_transitions.clear()

func _set_enabled(node: Node3D, enabled: bool) -> void:
	if node:
		node.visible = enabled
		_set_collision_recursive(node, enabled)

func _set_collision_recursive(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = not enabled
	for child in node.get_children():
		_set_collision_recursive(child, enabled)
