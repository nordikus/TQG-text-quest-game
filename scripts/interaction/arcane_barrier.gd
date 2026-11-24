class_name ArcaneBarrier
extends Interactable

const SHARD_ID := "star_crystal_shard"

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collider: CollisionShape3D = $Col
@onready var _original_scale := _mesh.scale
var _release: Tween
var _sealed := true
var _available := true

func _ready() -> void:
	super._ready()
	interaction_prompt = "[E] Коснуться печати"

func interact() -> void:
	if not _available or not _sealed:
		return
	if not InventoryManager.has_item(SHARD_ID):
		GameManager.notify(LOCKED_TEXT)
		return
	_sealed = false
	_collider.disabled = true
	set_highlighted(false)
	GameManager.interaction_prompt_cleared.emit()
	_release = create_tween()
	_release.tween_property(_mesh, "scale:y", 0.01, 0.48)
	_release.finished.connect(hide)

func restore_seal(available: bool = true) -> void:
	if _release:
		_release.kill()
	_available = available
	_sealed = true
	_mesh.scale = _original_scale
	_collider.disabled = not available
	visible = available

func get_save_state() -> Dictionary:
	return {"sealed": _sealed}

func apply_save_state(state: Dictionary) -> void:
	if _available and state.get("sealed", true) == false:
		_sealed = false
		_collider.disabled = true
		hide()
