class_name BookPedestal
extends Interactable

@export var quest_id: String = "burning_grove"
@export var uncompleted_prompt: String = "[E] Прочесть книгу: Горящая роща"
@export var completed_prompt: String = "Страницы застыли."
@export var rewrite_prompt: String = "[E] Переписать историю Великим пером"

func _ready():
	super._ready()
	_update_prompt()
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_reset.connect(_on_quest_reset)
	InventoryManager.inventory_changed.connect(_update_prompt)

func _update_prompt():
	if QuestManager.is_quest_completed(quest_id):
		if InventoryManager.has_item("great_quill"):
			interaction_prompt = rewrite_prompt
		else:
			interaction_prompt = completed_prompt
	else:
		interaction_prompt = uncompleted_prompt

func _on_quest_completed(completed_id: String, _ending_id: String):
	if completed_id == quest_id:
		_update_prompt()

func _on_quest_reset(reset_id: String):
	if reset_id == quest_id:
		_update_prompt()

func interact():
	if not QuestManager.is_quest_completed(quest_id):
		GameManager.open_quest(quest_id)
	elif InventoryManager.has_item("great_quill"):
		_rewrite_reality()
	else:
		GameManager.interaction_prompt_changed.emit(completed_prompt)

func _rewrite_reality():
	InventoryManager.use_item("great_quill")
	QuestManager.reset_quest(quest_id)
	var wc := _find_world_changer()
	if wc and wc.has_method("reset_world"):
		wc.reset_world()
	GameManager.notify("Великое перо изменило застывшие чернила! Реальность переписывается...")
	_update_prompt()
	GameManager.interaction_prompt_changed.emit(interaction_prompt)
	GameManager.open_quest(quest_id)

func _find_world_changer() -> Node:
	var nodes := get_tree().get_nodes_in_group("world_changer")
	if nodes.size() > 0:
		return nodes[0]
	return get_tree().root.find_child("WorldChanger", true, false)
