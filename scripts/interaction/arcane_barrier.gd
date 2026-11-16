class_name ArcaneBarrier
extends Interactable

func _ready():
	super._ready()
	interaction_prompt = "[E] Исследовать лазурный барьер"

func interact():
	GameManager.notify("Барьер запечатан древней магией. Печать поддерживается изнутри обсерватории Башни.")
