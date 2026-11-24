extends CanvasLayer

const CAMERA_MOVE_TIME := 0.65
const CAMERA_FOV := 61.0
const CHARACTERS_PER_SECOND := 33.0

@onready var _camera: Camera3D = $CinematicCamera
@onready var _hud: CanvasLayer = $"../HUD"
@onready var _bars: Control = $Letterbox
@onready var _caption: PanelContainer = %Caption
@onready var _line: Label = %Dialogue
@onready var _choices: HBoxContainer = %Choices
@onready var _walk: Button = %Walk
@onready var _end_card: ColorRect = $EndCard

var _player_camera: Camera3D
var _sequence: Tween
var _leaving := false

func _ready() -> void:
	GameManager.observer_epilogue = self
	%Finish.pressed.connect(_finish_game)
	_walk.pressed.connect(_resume_exploration)

func play(observer: Interactable, dialogue: String) -> void:
	_player_camera = get_viewport().get_camera_3d()
	if not is_instance_valid(_player_camera):
		return

	_leaving = false
	var translated := tr(dialogue)
	_line.text = translated
	_line.visible_ratio = 0.0
	_caption.hide()
	_choices.hide()
	_bars.modulate.a = 0.0
	_end_card.hide()
	show()
	_hud.hide()
	GameManager.ui_open = true
	GameManager.interaction_prompt_cleared.emit()
	observer.set_highlighted(false)

	_camera.global_transform = _player_camera.global_transform
	_camera.fov = _player_camera.fov
	_camera.make_current()
	var focus := observer.global_position + Vector3.UP * 1.74
	var framing := _camera.global_transform.looking_at(focus)
	var toward_camera := _camera.global_position - observer.global_position
	var turn := angle_difference(observer.global_rotation.y, atan2(toward_camera.x, toward_camera.z))

	_sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence.tween_property(_camera, "global_transform", framing, CAMERA_MOVE_TIME)
	_sequence.parallel().tween_property(_camera, "fov", minf(_player_camera.fov, CAMERA_FOV), CAMERA_MOVE_TIME)
	_sequence.parallel().tween_property(observer, "rotation:y", observer.rotation.y + turn, CAMERA_MOVE_TIME)
	_sequence.parallel().tween_property(_bars, "modulate:a", 1.0, CAMERA_MOVE_TIME)
	_sequence.tween_callback(_caption.show)
	_sequence.tween_property(_line, "visible_ratio", 1.0, translated.length() / CHARACTERS_PER_SECOND).set_trans(Tween.TRANS_LINEAR)
	_sequence.tween_interval(0.6)
	_sequence.tween_callback(_show_choices)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_resume_exploration()
		get_viewport().set_input_as_handled()

func _show_choices() -> void:
	_choices.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_walk.grab_focus()

func _resume_exploration() -> void:
	if not visible or _leaving:
		return
	_leaving = true
	_sequence.kill()
	_caption.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence.tween_property(_camera, "global_transform", _player_camera.global_transform, 0.45)
	_sequence.parallel().tween_property(_camera, "fov", _player_camera.fov, 0.45)
	_sequence.parallel().tween_property(_bars, "modulate:a", 0.0, 0.45)
	_sequence.tween_callback(_restore_player)

func _restore_player() -> void:
	_player_camera.make_current()
	_hud.show()
	hide()
	GameManager.ui_open = false

func _finish_game() -> void:
	if not _choices.is_visible_in_tree() or _leaving:
		return
	_leaving = true
	_caption.hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_end_card.modulate.a = 0.0
	_end_card.show()

	_sequence = create_tween()
	_sequence.tween_property(_end_card, "modulate:a", 1.0, 0.85)
	_sequence.tween_interval(1.2)
	_sequence.tween_callback(get_tree().quit)
