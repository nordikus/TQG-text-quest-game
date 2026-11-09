class_name BookPedestal
extends Interactable

@export var quest_id: String = "burning_grove"
@export var uncompleted_prompt: String = "[E] Прочесть книгу: Горящая роща"
@export var completed_prompt: String = "Страницы застыли."

func _ready():
	super._ready()
	_update_prompt()
	QuestManager.quest_completed.connect(_on_quest_completed)

func _update_prompt():
	if QuestManager.is_quest_completed(quest_id):
		interaction_prompt = completed_prompt
	else:
		interaction_prompt = uncompleted_prompt

func _on_quest_completed(completed_id: String, _ending_id: String):
	if completed_id == quest_id:
		_update_prompt()

func interact():
	if not QuestManager.is_quest_completed(quest_id):
		GameManager.open_quest(quest_id)
	else:
		GameManager.interaction_prompt_changed.emit(completed_prompt)
