extends Node

signal interaction_prompt_changed(prompt: String)
signal interaction_prompt_cleared

var ui_open: bool = false
var quest_panel: Node = null

func _ready():
	_register_inputs()

func open_quest(quest_id: String):
	if quest_panel and quest_panel.has_method("open_quest"):
		quest_panel.open_quest(quest_id)

func _register_inputs():
	_add_action("move_forward", KEY_W)
	_add_action("move_backward", KEY_S)
	_add_action("move_left", KEY_A)
	_add_action("move_right", KEY_D)
	_add_action("jump", KEY_SPACE)
	_add_action("interact", KEY_E)

func _add_action(action_name: String, key: Key):
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)
