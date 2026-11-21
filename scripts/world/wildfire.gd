extends Node3D

@export var phase := 0.0
@export_range(0.1, 1.0) var smoke_density := 1.0
@export_range(0.1, 1.0) var smoke_size := 1.0

@onready var _light: OmniLight3D = $Firelight
@onready var _smoke: CPUParticles3D = $Smoke
@onready var _sparks: CPUParticles3D = $Sparks

func _ready() -> void:
	$Flame.set_instance_shader_parameter("phase", phase)
	$FlameCross.set_instance_shader_parameter("phase", phase + 1.75)
	$FlameLow.set_instance_shader_parameter("phase", phase + 3.2)
	_smoke.amount = maxi(1, roundi(_smoke.amount * smoke_density))
	_smoke.scale_amount_max *= smoke_size
	_smoke.scale_amount_min *= smoke_size

func set_active(active: bool) -> void:
	_smoke.emitting = active
	_sparks.emitting = active
	_light.visible = active
	if active:
		_smoke.restart()
		_sparks.restart()
	set_process(active)

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 + phase
	_light.light_energy = 3.9 + 0.42 * sin(t * 11.0) + 0.28 * sin(t * 7.0)
