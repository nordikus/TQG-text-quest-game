class_name CourtyardGate
extends AnimatableBody3D

@export var lift_height := 6.65
var is_raised := false
var _motion: Tween
@onready var _closed_y := position.y

func is_moving() -> bool:
	return _motion != null and _motion.is_running()

func set_raised(raised: bool, animate := true) -> void:
	if _motion:
		_motion.kill()
	is_raised = raised
	var destination := _closed_y + lift_height if raised else _closed_y
	if not animate:
		position.y = destination
		return
	_motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion.tween_property(self, "position:y", destination, 2.6)
