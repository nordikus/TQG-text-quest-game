extends Node3D

const THRONE_QUEST := "deal_at_the_throne"

@onready var body_shape: CollisionShape3D = $Body/Shape

func _ready() -> void:
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_reset.connect(_on_quest_reset)
	InventoryManager.inventory_changed.connect(_update_presence)
	_update_presence()

func _on_quest_completed(quest_id: String, _ending: String) -> void:
	if quest_id == THRONE_QUEST:
		_update_presence()

func _on_quest_reset(quest_id: String) -> void:
	if quest_id == THRONE_QUEST:
		_update_presence()

func _update_presence() -> void:
	visible = (QuestManager.get_quest_ending(THRONE_QUEST) == "reject_deal"
		or InventoryManager.quill_uses_count > 0)
	body_shape.set_deferred("disabled", not visible)
