class_name PickupItem
extends Interactable

const ItemDb = preload("res://scripts/inventory/item_database.gd")

@export var item_id: String = ""

func _ready():
	super._ready()
	_update_prompt_from_item()

func _update_prompt_from_item():
	if item_id.is_empty():
		return
	var def := ItemDb.get_item(item_id)
	if not def.is_empty():
		var action_word: String = "Прочесть" if def.get("category") == "note" else "Взять"
		interaction_prompt = "[E] %s: %s" % [action_word, def.get("title", "")]

func interact():
	if item_id.is_empty():
		return
	set_highlighted(false)
	GameManager.interaction_prompt_cleared.emit()
	InventoryManager.add_item(item_id)
	queue_free()
