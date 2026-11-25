extends Node

const EnglishText := preload("res://scripts/autoload/english_text.gd")
const SETTINGS_PATH := "user://settings.cfg"

signal interaction_prompt_changed(prompt: String)
signal interaction_prompt_cleared
signal notification_requested(message: String)

var ui_open: bool = false
var quest_panel: Node = null
var inventory_panel: Node = null
var observer_epilogue: Node = null

func _ready():
	var english := Translation.new()
	english.locale = "en"
	var russian := Translation.new()
	russian.locale = "ru"
	for source: String in EnglishText.MESSAGES:
		english.add_message(source, EnglishText.MESSAGES[source])
		russian.add_message(source, source)
	TranslationServer.add_translation(english)
	TranslationServer.add_translation(russian)
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	var locale: String = settings.get_value("display", "language", "en")
	TranslationServer.set_locale("ru" if locale == "ru" else "en")
	_register_inputs()

func set_language(locale: String) -> void:
	TranslationServer.set_locale(locale)
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("display", "language", locale)
	settings.save(SETTINGS_PATH)

func open_quest(quest_id: String):
	if quest_panel and quest_panel.has_method("open_quest"):
		SoundEffects.play_ui(&"page", -15.0)
		quest_panel.open_quest(quest_id)

func confirm_rewrite(action: Callable) -> void:
	if not ui_open and is_instance_valid(quest_panel):
		quest_panel.open_rewrite_confirmation(action)

func open_observer_epilogue(observer: Interactable, dialogue: String) -> void:
	if not ui_open and is_instance_valid(observer_epilogue):
		observer_epilogue.play(observer, dialogue)

func toggle_inventory():
	if inventory_panel and inventory_panel.has_method("toggle_inventory"):
		inventory_panel.toggle_inventory()

func notify(message: String):
	notification_requested.emit(tr(message))

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
