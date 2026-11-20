class_name PickupItem
extends Interactable

const ItemDb = preload("res://scripts/inventory/item_database.gd")

@export var item_id: String = ""
@export var restore_on_rewrite := false
@onready var _pickup_shape := get_node_or_null("Col") as CollisionShape3D

func _ready():
	super._ready()
	_update_prompt_from_item()
	restore_pickup()

func _update_prompt_from_item():
	if item_id.is_empty():
		return
	var def := ItemDb.get_item(item_id)
	if not def.is_empty():
		var action_word: String = "Прочесть" if def.get("category") == "note" else "Взять"
		interaction_prompt = "[E] %s: %s" % [action_word, def.get("title", "")]

func interact():
	if item_id.is_empty() or not is_visible_in_tree() or is_queued_for_deletion():
		return
	set_highlighted(false)
	GameManager.interaction_prompt_cleared.emit()
	InventoryManager.add_item(item_id)
	if restore_on_rewrite:
		hide()
		if _pickup_shape:
			_pickup_shape.disabled = true
	else:
		queue_free()

func restore_pickup() -> void:
	if not restore_on_rewrite:
		return
	var in_inventory := InventoryManager.has_item(item_id)
	visible = not in_inventory
	if _pickup_shape:
		_pickup_shape.disabled = in_inventory
