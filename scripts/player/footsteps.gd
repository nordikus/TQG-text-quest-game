extends AudioStreamPlayer

const STRIDE_LENGTH := 2.30
const CONTACT_HEIGHT := 0.20
const SURFACES := {
	&"forest": [preload("res://assets/audio/step_leaves_a.ogg"),
		preload("res://assets/audio/step_leaves_b.ogg"), preload("res://assets/audio/step_soil.ogg")],
	&"wood": [preload("res://assets/audio/step_wood_a.ogg"),
		preload("res://assets/audio/step_wood_b.ogg"), preload("res://assets/audio/step_wood_c.ogg")],
	&"stone": [preload("res://assets/audio/step_stone.ogg")],
	&"ash": [preload("res://assets/audio/step_gravel.ogg")],
}

@onready var _player := get_parent() as CharacterBody3D
@onready var _castle := _player.get_parent().get_node_or_null("CastleFacade")
var _distance := 0.0
var _last_clip: AudioStream
var _paving: Array[MeshInstance3D] = []

func _ready() -> void:
	_find_paving.call_deferred()

func _find_paving() -> void:
	for mesh in get_tree().get_nodes_in_group(&"footstep_paving"):
		if _player.get_parent().is_ancestor_of(mesh):
			_paving.append(mesh)

func update_footsteps(landed: bool, fall_speed: float) -> void:
	if not _player.is_on_floor():
		_distance = 0.0
		return
	if landed and fall_speed >= 2.7:
		_play_step(clampf(-13.0 + fall_speed * 0.65, -12.0, -7.0))
		_distance = 0.0
		return
	var moved := _player.get_position_delta()
	var travel := Vector2(moved.x, moved.z).length()
	if travel < 0.001:
		_distance = STRIDE_LENGTH * 0.68
		return
	_distance += travel
	if _distance >= STRIDE_LENGTH:
		_distance = fmod(_distance, STRIDE_LENGTH)
		_play_step(-15.0)

func _play_step(level_db: float) -> void:
	var choices: Array = SURFACES[_surface_at_feet()]
	var index := randi_range(0, choices.size() - 1)
	if choices[index] == _last_clip and choices.size() > 1:
		index = (index + 1) % choices.size()
	stream = choices[index]
	_last_clip = stream
	volume_db = level_db + randf_range(-1.7, 0.4)
	pitch_scale = randf_range(0.90, 1.12)
	play()

func _surface_at_feet() -> StringName:
	var feet := _player.global_position
	var query := PhysicsRayQueryParameters3D.create(feet + Vector3.UP * CONTACT_HEIGHT,
		feet - Vector3.UP * 0.40, _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	var floor_node := hit.get("collider") as Node
	if not floor_node:
		return &"forest"
	if floor_node.is_in_group(&"footstep_wood"):
		return &"wood"
	if floor_node.is_in_group(&"footstep_ash"):
		return &"ash"
	if floor_node.is_in_group(&"footstep_stone") or (_castle and _castle.is_ancestor_of(floor_node)):
		return &"stone"
	if _on_paving(feet):
		return &"stone"
	return &"forest"

func _on_paving(feet: Vector3) -> bool:
	for tile in _paving:
		var local := tile.to_local(feet)
		var bounds := tile.get_aabb()
		if absf(bounds.end.y - local.y) > 0.12 or not bounds.grow(0.001).has_point(Vector3(local.x, bounds.end.y, local.z)):
			continue
		if tile.mesh is BoxMesh:
			return true
		var faces := tile.mesh.get_faces()
		var above := local + Vector3.UP * CONTACT_HEIGHT
		var below := local - Vector3.UP * CONTACT_HEIGHT
		for index in range(0, faces.size(), 3):
			if Geometry3D.segment_intersects_triangle(above, below, faces[index], faces[index + 1], faces[index + 2]) != null:
				return true
	return false
