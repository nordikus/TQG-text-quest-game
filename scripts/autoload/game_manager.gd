extends Node

signal interaction_prompt_changed(prompt: String)
signal interaction_prompt_cleared
signal notification_requested(message: String)

var ui_open: bool = false
var quest_panel: Node = null
var inventory_panel: Node = null

func _ready():
	_register_inputs()

func open_quest(quest_id: String):
	if quest_panel and quest_panel.has_method("open_quest"):
		quest_panel.open_quest(quest_id)

func toggle_inventory():
	if inventory_panel and inventory_panel.has_method("toggle_inventory"):
		inventory_panel.toggle_inventory()

func notify(message: String):
	notification_requested.emit(message)

func _register_inputs():
	_add_action("move_forward", KEY_W)
	_add_action("move_backward", KEY_S)
	_add_action("move_left", KEY_A)
	_add_action("move_right", KEY_D)
	_add_action("jump", KEY_SPACE)
	_add_action("interact", KEY_E)
	_add_action("inventory", KEY_I)
	_add_key_to_action("inventory", KEY_TAB)

func _add_action(action_name: String, key: Key):
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func _add_key_to_action(action_name: String, key: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)
