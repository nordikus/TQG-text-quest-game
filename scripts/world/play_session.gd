extends Node3D

const PauseMenu := preload("res://scenes/ui/game_menu.tscn")

func _ready() -> void:
	_start_session.call_deferred()

func _start_session() -> void:
	if get_tree().current_scene != self:
		return
	SaveManager.attach_level(self)
	var menu := PauseMenu.instantiate()
	menu.in_game = true
	add_child(menu)
