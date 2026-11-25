extends Node3D

const Layout := preload("res://scripts/world/forest_layout.gd")
const FOREST := preload("res://assets/audio/forest_loop.ogg")
const SPRING := preload("res://assets/audio/spring_loop.ogg")

@onready var _level := get_parent()
@onready var _player := _level.get_node("Player") as CharacterBody3D
@onready var _burning := _level.get_node("BurningPath") as Node3D
@onready var _life_trail := _level.get_node("NatureTrail") as Node3D

var _forest := AudioStreamPlayer.new()
var _spring := AudioStreamPlayer3D.new()
var _mix_level := -22.0
var _until_check := 0.0

func _ready() -> void:
	var birds := FOREST
	birds.loop = true
	_forest.stream = birds
	_forest.volume_db = -45.0
	add_child(_forest)
	_forest.play()

	var water := SPRING
	water.loop = true
	_spring.stream = water
	_spring.position = Vector3(-4.95, 0.15, -35.85)
	_spring.volume_db = -19.0
	_spring.unit_size = 2.5
	_spring.max_distance = 13.0
	add_child(_spring)

func _physics_process(delta: float) -> void:
	_forest.volume_db = move_toward(_forest.volume_db, _mix_level, delta * 31.0)
	_until_check -= delta
	if _until_check > 0.0:
		return
	_until_check = 0.25
	var camera := get_viewport().get_camera_3d()
	var at := camera.global_position if camera else _player.global_position + Vector3.UP * 1.6
	var roof := PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * 14.0, 1, [_player.get_rid()])
	var sheltered := not _player.get_world_3d().direct_space_state.intersect_ray(roof).is_empty()
	var fire_distance := Layout.distance_to_path(Vector2(at.x, at.z), Layout.ASH_PATH) if _burning.visible else 20.0
	_mix_level = -45.0 if sheltered else lerpf(-42.0, -22.0, smoothstep(4.0, 20.0, fire_distance))
	if _life_trail.visible and not _spring.playing:
		_spring.play()
	elif not _life_trail.visible and _spring.playing:
		_spring.stop()
