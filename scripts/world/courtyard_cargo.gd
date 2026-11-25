@tool
extends Node3D

@export var burned := false

const OAK := Color(0.35, 0.22, 0.12)
const BRACE := Color(0.49, 0.32, 0.17)
const CHAR := Color(0.105, 0.082, 0.063)

func _ready() -> void:
	if burned:
		_burned_crate(Vector3(-0.53, 0, 0.05))
		_burned_crate(Vector3(0.69, 0, -0.16))
		_board(Vector3(0.50, 0.13, 0.42), Vector3(0.15, 0.095, 1.47),
			CHAR.lightened(0.08), Vector3(-0.11, 0.78, 0.18))
		return
	_crate(Vector3(-0.62, 0, 0.12), -0.13)
	_crate(Vector3(0.62, 0, -0.08), 0.26)

func _crate(at: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation.y = yaw
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.95, 0.88, 0.90)
	var collision := CollisionShape3D.new()
	collision.position.y = 0.44
	collision.shape = shape
	body.add_child(collision)
	_board(Vector3(0, 0.44, 0), Vector3(0.83, 0.82, 0.82), OAK.darkened(0.25), Vector3.ZERO, body)
	for side in [-1.0, 1.0]:
		for i in 4:
			var y := 0.115 + i * 0.218
			_board(Vector3(0, y, side * 0.413), Vector3(0.88, 0.20, 0.045),
				OAK.lightened(0.038 * sin(i * 2.7)), Vector3.ZERO, body)
			_board(Vector3(side * 0.42, y, 0), Vector3(0.042, 0.20, 0.82),
				OAK.lightened(0.03 * cos(i * 2.7)), Vector3.ZERO, body)
		_board(Vector3(0, 0.44, side * 0.45), Vector3(0.10, 1.05, 0.046),
			BRACE, Vector3(0, 0, 0.70 * side), body)
	for i in 4:
		_board(Vector3(-0.33 + i * 0.22, 0.86, 0), Vector3(0.207, 0.05, 0.86),
			OAK.lightened(i * 0.021), Vector3.ZERO, body)

func _burned_crate(at: Vector3) -> void:
	_board(at + Vector3(0, 0.075, 0), Vector3(0.93, 0.13, 0.82), CHAR, Vector3(0, -0.17, 0), self, true)
	for i in 4:
		var angle := 0.62 * i - 0.72
		var offset := Vector3(0.17 * sin(i * 2.5), 0.19 + 0.04 * i, -0.25 + 0.15 * i)
		_board(at + offset, Vector3(0.19, 0.07, 0.79 - 0.08 * i),
			CHAR.lightened(0.03 * (i % 3)), Vector3(0.30 * sin(i), angle, 0.12))
	for offset in [Vector3(-0.40, 0.31, -0.32), Vector3(0.38, 0.22, -0.32)]:
		_board(at + offset, Vector3(0.13, offset.y * 1.8, 0.14),
			CHAR.darkened(0.2), Vector3(0.20, 0.13, 0.16), self, true)

func _board(at: Vector3, size: Vector3, color: Color, tilt: Vector3,
		holder: Node3D = null, solid := false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = tilt
	(holder if holder else self).add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		instance.add_child(body)
