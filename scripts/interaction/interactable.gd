class_name Interactable
extends StaticBody3D

@export var interaction_prompt: String = "[E] Взаимодействовать"

func _ready():
	add_to_group("interactable")

func interact():
	pass

func get_interaction_prompt() -> String:
	return interaction_prompt
