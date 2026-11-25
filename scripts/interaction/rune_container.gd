class_name RuneContainer
extends Interactable

@export var note_id: String
@export var closed_prompt := "[E] Открыть сундук"

@onready var _lid: Node3D = $Lid
@onready var _rune: Node3D = $Seal
var _opening: Tween
var _opened := false

func _ready() -> void:
	super._ready()
	restore_seal()

func interact() -> void:
	if _opened:
		return
	if not InventoryManager.has_item(ArcaneBarrier.SHARD_ID):
		SoundEffects.play_at(&"locked", self, -15.0, 0.5)
		GameManager.notify(LOCKED_TEXT)
		return
	_opened = true
	SoundEffects.play_at(&"container", self, -13.0, 0.5)
	_rune.hide()
	interaction_prompt = ""
	_opening = create_tween()
	_opening.tween_property(_lid, "rotation:x", -1.12, 0.58).set_trans(Tween.TRANS_CUBIC)
	if not InventoryManager.add_item(note_id):
		GameManager.notify("Эта запись уже в журнале.")
	GameManager.interaction_prompt_cleared.emit()

func restore_seal() -> void:
	if _opening:
		_opening.kill()
	_opened = false
	_lid.rotation.x = 0.0
	_rune.show()
	interaction_prompt = closed_prompt

func get_save_state() -> Dictionary:
	return {"opened": _opened}

func apply_save_state(state: Dictionary) -> void:
	if state.get("opened", false):
		_opened = true
		_lid.rotation.x = -1.12
		_rune.hide()
		interaction_prompt = ""
