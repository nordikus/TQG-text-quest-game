extends Node

const ItemDb = preload("res://scripts/inventory/item_database.gd")

signal item_added(item_data: Dictionary)
signal item_consumed(item_data: Dictionary)
signal inventory_changed

var items: Array[Dictionary] = []
var notes: Array[String] = []
var quill_uses_count: int = 0

func add_item(item_id: String) -> bool:
	var def: Dictionary = ItemDb.get_item(item_id)
	if def.is_empty():
		return false
	
	if def.get("category", "item") == "note":
		if not notes.has(item_id):
			notes.append(item_id)
			item_added.emit(def)
			inventory_changed.emit()
			GameManager.notify("Получена записка: " + def.get("title", ""))
			return true
		return false

	var remaining_uses: int = def.get("max_uses", 1)
	items.append({
		"id": item_id,
		"remaining_uses": remaining_uses
	})
	item_added.emit(def)
	inventory_changed.emit()
	GameManager.notify("Получен предмет: " + def.get("title", ""))
	return true

func has_item(item_id: String) -> bool:
	for it in items:
		if it.get("id") == item_id:
			return true
	return false

func use_item(item_id: String) -> bool:
	for i in range(items.size()):
		var it = items[i]
		if it.get("id") == item_id:
			var def: Dictionary = ItemDb.get_item(item_id)
			var uses: int = it.get("remaining_uses", 1)
			if item_id == "great_quill":
				quill_uses_count += 1
			if uses > 0:
				uses -= 1
				it["remaining_uses"] = uses
				if uses == 0:
					items.remove_at(i)
					item_consumed.emit(def)
					inventory_changed.emit()
					GameManager.notify("Использовано: " + def.get("title", ""))
					return true
			inventory_changed.emit()
			GameManager.notify("Использовано: " + def.get("title", ""))
			return true
	return false

func get_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for it in items:
		var def: Dictionary = ItemDb.get_item(it.get("id", ""))
		if not def.is_empty():
			var item_copy := def.duplicate()
			item_copy["remaining_uses"] = it.get("remaining_uses", 1)
			result.append(item_copy)
	return result

func get_notes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for note_id in notes:
		var def: Dictionary = ItemDb.get_item(note_id)
		if not def.is_empty():
			result.append(def)
	return result
