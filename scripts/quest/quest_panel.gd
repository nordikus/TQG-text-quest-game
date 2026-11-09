extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/Header/TitleLabel
@onready var text_label: RichTextLabel = $PanelContainer/VBoxContainer/ContentScroll/TextLabel
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer
@onready var close_button: Button = $PanelContainer/VBoxContainer/Header/CloseButton

var current_quest: Dictionary = {}
var current_node_id: String = ""

func _ready():
	GameManager.quest_panel = self
	hide_panel()
	close_button.pressed.connect(close_quest)

func _unhandled_input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		close_quest()
		get_viewport().set_input_as_handled()

func open_quest(quest_id: String):
	current_quest = QuestData.get_quest(quest_id)
	if current_quest.is_empty():
		return

	title_label.text = current_quest.get("title", "Квест")
	current_node_id = current_quest.get("start_node", "start")
	_display_node(current_node_id)
	
	visible = true
	GameManager.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_quest():
	hide_panel()
	GameManager.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func hide_panel():
	visible = false

func _display_node(node_id: String):
	current_node_id = node_id
	var nodes: Dictionary = current_quest.get("nodes", {})
	if not nodes.has(node_id):
		close_quest()
		return

	var node_data: Dictionary = nodes[node_id]
	text_label.text = node_data.get("text", "")

	for child in choices_container.get_children():
		child.queue_free()

	var choices: Array = node_data.get("choices", [])
	for choice in choices:
		var btn := Button.new()
		btn.text = choice.get("text", "Выбрать")
		btn.custom_minimum_size = Vector2(0, 44)
		var next_node: String = choice.get("next_node", "")
		btn.pressed.connect(_on_choice_selected.bind(next_node, node_data))
		choices_container.add_child(btn)

func _on_choice_selected(next_node: String, current_node_data: Dictionary):
	if next_node.is_empty():
		var ending_id: String = current_node_data.get("ending_id", "")
		var quest_id: String = current_quest.get("id", "")
		if not ending_id.is_empty() and not quest_id.is_empty():
			QuestManager.complete_quest(quest_id, ending_id)
		close_quest()
	else:
		_display_node(next_node)
