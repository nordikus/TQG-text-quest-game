extends Control

@onready var prompt_label: Label = $PromptLabel
@onready var crosshair: ColorRect = $Crosshair

func _ready():
	prompt_label.text = ""
	prompt_label.visible = false
	GameManager.interaction_prompt_changed.connect(_on_prompt_changed)
	GameManager.interaction_prompt_cleared.connect(_on_prompt_cleared)

func _on_prompt_changed(text: String):
	prompt_label.text = text
	prompt_label.visible = true

func _on_prompt_cleared():
	prompt_label.text = ""
	prompt_label.visible = false
