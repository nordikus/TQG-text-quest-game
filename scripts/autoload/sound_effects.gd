extends Node

const CUES := {
	&"page": preload("res://assets/audio/page.ogg"),
	&"pickup": preload("res://assets/audio/pickup.ogg"),
	&"ui": preload("res://assets/audio/menu.ogg"),
	&"door_open": preload("res://assets/audio/door_open.ogg"),
	&"door_close": preload("res://assets/audio/door_close.ogg"),
	&"locked": preload("res://assets/audio/locked.ogg"),
	&"bolt": preload("res://assets/audio/bolt.ogg"),
	&"container": preload("res://assets/audio/container.ogg"),
	&"seal": preload("res://assets/audio/seal.ogg"),
	&"rewrite": preload("res://assets/audio/rewrite.ogg"),
	&"tree_grow": preload("res://assets/audio/tree_grow.ogg"),
	&"gate_chain": preload("res://assets/audio/gate_chain.ogg"),
}

var _ui_player := AudioStreamPlayer.new()

func _ready() -> void:
	_ui_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_player.max_polyphony = 3
	add_child(_ui_player)

func play_ui(cue: StringName, level_db := -17.0) -> void:
	_ui_player.stream = CUES[cue]
	_ui_player.volume_db = level_db
	_ui_player.play()

func play_at(cue: StringName, source: Node3D, level_db := -12.0, height := 1.0) -> void:
	var emitter := AudioStreamPlayer3D.new()
	emitter.stream = CUES[cue]
	emitter.volume_db = level_db
	emitter.unit_size = 3.5
	emitter.max_distance = 22.0
	emitter.position.y = height
	source.add_child(emitter)
	emitter.finished.connect(emitter.queue_free)
	emitter.play()
