extends Interactable

const PAGE_ID := "captains_sealed_report"

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
		GameManager.notify("Крышка не поддаётся.")
		return
	_opened = true
	_rune.hide()
	interaction_prompt = ""
	_opening = create_tween()
	_opening.tween_property(_lid, "rotation:x", -1.12, 0.58).set_trans(Tween.TRANS_CUBIC)
	if not InventoryManager.add_item(PAGE_ID):
		GameManager.notify("Копия донесения уже в журнале.")
	GameManager.interaction_prompt_cleared.emit()

func restore_seal() -> void:
	if _opening:
		_opening.kill()
	_opened = false
	_lid.rotation.x = 0.0
	_rune.show()
	interaction_prompt = "[E] Открыть сундук"
