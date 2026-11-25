@tool
extends Node3D

@export var glow_color := Color(0.37, 0.88, 0.69):
	set(value):
		glow_color = value
		if is_node_ready():
			_update_color()
@export var solid_base := false
@export var lit := true

func _ready() -> void:
	_update_color()
	if solid_base:
		var body := StaticBody3D.new()
		for section in [Vector3(0.37, 0.18, 0.08), Vector3(0.24, 0.84, 0.52)]:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = section.x
			cylinder.height = section.y
			var collider := CollisionShape3D.new()
			collider.position.y = section.z
			collider.shape = cylinder
			body.add_child(collider)
		add_child(body)

func _update_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = glow_color if lit else glow_color.darkened(0.72)
	material.emission_enabled = lit
	material.emission = glow_color
	material.emission_energy_multiplier = 1.35
	$Crystal.material_override = material
	$Light.light_color = glow_color
	$Light.visible = lit
