class_name Interactable
extends StaticBody3D

@export var interaction_prompt: String = "[E] Взаимодействовать"

static var _shared_highlight_mat: StandardMaterial3D = null

func _ready():
	add_to_group("interactable")

func set_highlighted(enabled: bool):
	if _shared_highlight_mat == null:
		_shared_highlight_mat = StandardMaterial3D.new()
		_shared_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shared_highlight_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_shared_highlight_mat.albedo_color = Color(0.95, 0.82, 0.4, 0.28)
	_apply_highlight_recursive(self, enabled)

func _apply_highlight_recursive(node: Node, enabled: bool):
	if node is MeshInstance3D:
		node.material_overlay = _shared_highlight_mat if enabled else null
	for child in node.get_children():
		_apply_highlight_recursive(child, enabled)

func interact():
	pass

func get_interaction_prompt() -> String:
	return interaction_prompt
