extends Node

signal quest_completed(quest_id: String, ending_id: String)
signal quest_reset(quest_id: String)

var completed_quests: Dictionary = {}

func complete_quest(quest_id: String, ending_id: String):
	completed_quests[quest_id] = ending_id
	quest_completed.emit(quest_id, ending_id)

func reset_quest(quest_id: String) -> void:
	if quest_id in completed_quests:
		completed_quests.erase(quest_id)
		quest_reset.emit(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_quest_ending(quest_id: String) -> String:
	return completed_quests.get(quest_id, "")
