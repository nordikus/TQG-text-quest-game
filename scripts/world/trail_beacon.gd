@tool
extends Node3D

@export var glow_color := Color(0.37, 0.88, 0.69):
	set(value):
		glow_color = value
		if is_node_ready():
			_update_color()

func _ready() -> void:
	_update_color()

func _update_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = glow_color
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = 1.35
	$Crystal.material_override = material
	$Light.light_color = glow_color
