@tool
extends Node3D

@export var stone: Material

const WALK_Y := 14.80
const WEST_FACE := -45.75
const EAST_FACE := -42.25
const SOUTH := 6.5
const NORTH := -89.5
const APPROACH_X := -23.0
const EXTERIOR_FACE := 10.25
const COURTYARD_FACE := 6.75
const BREACH_FLOOR := 11.83
const PASSAGE_HEIGHT := 2.84
const PASSAGE_HALF_WIDTH := 1.38

func _ready() -> void:
	var wall := _body("WallWest")
	_span(wall, WEST_FACE, EAST_FACE, 0.0, WALK_Y, NORTH, SOUTH)
	_front_wall()

func _front_wall() -> void:
	var front := _body("WallFrontLeft")
	var left := APPROACH_X - PASSAGE_HALF_WIDTH
	var right := APPROACH_X + PASSAGE_HALF_WIDTH
	var lintel := BREACH_FLOOR + PASSAGE_HEIGHT
	_span(front, -42.0, left, 0.0, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE)
	_span(front, right, -5.0, 0.0, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE)
	_span(front, left, right, 0.0, BREACH_FLOOR, COURTYARD_FACE, EXTERIOR_FACE)
	_span(front, left, right, lintel, WALK_Y, COURTYARD_FACE, EXTERIOR_FACE)

func _span(body: StaticBody3D, left: float, right: float, low: float, high: float,
		start: float, finish: float) -> void:
	var size := Vector3(right - left, high - low, finish - start)
	var at := Vector3((left + right) * 0.5, (low + high) * 0.5, (start + finish) * 0.5)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = stone
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.position = at
	body.add_child(model)

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	body.add_child(collider)

func _body(body_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	add_child(body)
	return body
