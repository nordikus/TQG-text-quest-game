extends Interactable

const THRONE_QUEST := "deal_at_the_throne"
const REFUSAL_LINE := "Мало кто из смертных отказывался от возможности изменить судьбу. Ты меня удивил."
const REWRITE_LINE := "Как и любой смертный, ты поддался желанию изменить прошлое… Но сможешь ли ты остановиться?"

@onready var body_shape: CollisionShape3D = $Shape
@onready var idle: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	super._ready()
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
	visible = _refused_quill() or InventoryManager.quill_uses_count > 0
	body_shape.set_deferred("disabled", not visible)
	if visible and not idle.is_playing():
		idle.play(&"idle")
	elif not visible:
		idle.stop()

func get_interaction_prompt() -> String:
	return interaction_prompt if visible else ""

func interact() -> void:
	if visible:
		GameManager.open_observer_epilogue(self, REFUSAL_LINE if _refused_quill() else REWRITE_LINE)

func _refused_quill() -> bool:
	return QuestManager.get_quest_ending(THRONE_QUEST) == "reject_deal"
