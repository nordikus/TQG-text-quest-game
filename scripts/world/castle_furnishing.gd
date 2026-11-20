@tool
extends Node3D

enum Place { WORKSHOP, COURTYARD, SUPPLY_SHELTER, BURNED_SHELTER }

@export var place: Place = Place.WORKSHOP

const LIMESTONE := Color(0.39, 0.37, 0.31)
const OAK := Color(0.30, 0.19, 0.115)
const WOOD_EDGE := Color(0.42, 0.28, 0.17)
const IRON := Color(0.15, 0.16, 0.16)
const BRASS := Color(0.58, 0.40, 0.20)
const PAPER := Color(0.77, 0.67, 0.47)
const BLUE := Color(0.25, 0.43, 0.60)
const CHAR := Color(0.125, 0.086, 0.061)

var _materials: Dictionary[Color, StandardMaterial3D]

func _ready() -> void:
	match place:
		Place.WORKSHOP:
			_workshop()
		Place.COURTYARD:
			_courtyard()
		Place.SUPPLY_SHELTER:
			_shelter(false)
		Place.BURNED_SHELTER:
			_shelter(true)

func _workshop() -> void:
	var table := Vector3(-2.40, 0, 1.85)
	_box(table + Vector3.UP * 1.02, Vector3(1.46, 0.12, 0.92), WOOD_EDGE, true)
	for x in [-0.62, 0.62]:
		for z in [-0.34, 0.34]:
			_box(table + Vector3(x, 0.615, z), Vector3(0.13, 0.70, 0.13), OAK, true)
	_box(table + Vector3(0.03, 0.88, -0.35), Vector3(1.18, 0.21, 0.19), OAK)
	_box(table + Vector3(0.03, 0.88, -0.46), Vector3(0.18, 0.036, 0.04), BRASS)
	_box(table + Vector3(0.36, 1.084, -0.21), Vector3(0.47, 0.008, 0.29), PAPER, false, Vector3(0, -0.20, 0))
	_round(table + Vector3(-0.51, 1.153, 0.23), 0.085, 0.14, BLUE)
	_round(table + Vector3(-0.54, 1.09, -0.21), 0.089, 0.022, BRASS)
	_box(table + Vector3(-0.53, 1.104, -0.21), Vector3(0.13, 0.015, 0.021), IRON, false, Vector3(0, 0.58, 0))

	var shelves := Vector3(-3.39, 0, 0.05)
	for z in [-0.69, 0.69]:
		_box(shelves + Vector3(0, 1.13, z), Vector3(0.39, 1.73, 0.09), OAK, true)
	_box(shelves + Vector3(-0.18, 1.12, 0), Vector3(0.09, 1.73, 1.38), OAK)
	for y in [0.39, 0.81, 1.23, 1.65]:
		_box(shelves + Vector3(0, y, 0), Vector3(0.42, 0.09, 1.41), WOOD_EDGE, true)
	for i in 5:
		var height := 0.23 + 0.055 * sin(1.97 * i)
		_box(shelves + Vector3(0.077, 0.858 + height * 0.5, -0.52 + 0.13 * i),
			Vector3(0.22, height, 0.102), BLUE.lerp(Color(0.43, 0.23, 0.18), i / 4.0))
	_round(shelves + Vector3(0.07, 1.40, 0.48), 0.095, 0.244, BRASS)
	_round(shelves + Vector3(0.07, 1.36, 0.16), 0.071, 0.165, BLUE)
	_box(shelves + Vector3(0.06, 0.59, 0.43), Vector3(0.32, 0.30, 0.37), OAK)

	var map := Vector3(-2.40, 1.58, 2.72)
	_box(map, Vector3(1.32, 0.70, 0.11), OAK, false, Vector3(-0.10, -0.20, 0))
	_box(map + Vector3(0, 0.02, -0.066), Vector3(1.13, 0.52, 0.018), PAPER, false, Vector3(-0.10, -0.20, 0))
	for i in 3:
		_box(map + Vector3(-0.21 + 0.18 * i, 0.06 - 0.06 * i, -0.093),
			Vector3(0.39 - i * 0.07, 0.018, 0.012), BLUE, false, Vector3(0, -0.20, 0.12 * sin(i)))
	var cabinet := Vector3(-0.97, 0.60, 3.0)
	_box(cabinet, Vector3(0.78, 0.67, 0.42), OAK, true)
	for y in [0.49, 0.72]:
		_box(Vector3(cabinet.x, y, 2.772), Vector3(0.65, 0.18, 0.042), WOOD_EDGE)
		_box(Vector3(cabinet.x, y, 2.735), Vector3(0.116, 0.041, 0.046), BRASS)
	var lamp := Vector3(-2.56, 1.08, 2.15)
	_round(lamp + Vector3.UP * 0.03, 0.103, 0.06, IRON)
	_round(lamp + Vector3.UP * 0.17, 0.062, 0.22, Color(0.92, 0.67, 0.39))
	_round(lamp + Vector3.UP * 0.30, 0.095, 0.06, IRON)

func _courtyard() -> void:
	# Well furniture and planting beds sit beside the paved approaches.
	_bench(Vector3(8.26, 0, -6.56))
	_bench(Vector3(6.72, 0, -13.02))
	var trough := Vector3(4.55, 0, -10.1)
	_box(trough + Vector3.UP * 0.22, Vector3(1.15, 0.44, 1.95), LIMESTONE, true)
	_box(trough + Vector3.UP * 0.447, Vector3(0.84, 0.018, 1.63), BLUE.darkened(0.37))
	for x in [-0.54, 0.54]:
		_box(trough + Vector3(x, 0.51, 0), Vector3(0.11, 0.18, 1.95), LIMESTONE)
	for z in [-0.93, 0.93]:
		_box(trough + Vector3(0, 0.51, z), Vector3(0.98, 0.18, 0.11), LIMESTONE)
	for z in [1.7, 4.4]:
		_herbs(Vector3(10.55, 0, z))

	var yard := Vector3(11.55, 0, -12.1)
	_box(yard + Vector3.UP * 0.012, Vector3(5.35, 0.021, 4.52), Color(0.23, 0.196, 0.127))
	for x in [-2.72, 2.72]:
		_box(yard + Vector3(x, 0.11, 0), Vector3(0.15, 0.22, 4.74), LIMESTONE, true)
	for x in [-1.62, 0, 1.63]:
		var base := yard + Vector3(x, 0, -1.38)
		_round(base + Vector3.UP * 0.13, 0.31, 0.25, LIMESTONE, true)
		_box(base + Vector3.UP * 1.09, Vector3(0.15, 2.13, 0.15), OAK, true)
		_round(base + Vector3(0, 1.44, 0.115), 0.46, 0.13, Color(0.54, 0.37, 0.18), false, Vector3(PI / 2, 0, 0))
		_round(base + Vector3(0, 1.44, 0.185), 0.12, 0.035, Color(0.42, 0.16, 0.10), false, Vector3(PI / 2, 0, 0))

func _shelter(burned: bool) -> void:
	for x in [-2.06, 2.06]:
		for z in [-1.36, 1.36]:
			_box(Vector3(x, 0.14, z), Vector3(0.45, 0.28, 0.47), LIMESTONE, true)
			var height: float = 0.44 + 0.24 * sin(2.0 * x + z) if burned else 2.96 + z * 0.23
			_box(Vector3(x, 0.28 + height * 0.5, z), Vector3(0.20, height, 0.20),
				CHAR if burned else OAK, not burned)
	if burned:
		for i in 8:
			_box(Vector3(-1.73 + i * 0.45, 0.20 + 0.05 * sin(i), 0.49 * cos(i)),
				Vector3(0.26, 0.13, 1.14 + sin(i) * 0.39), CHAR.lightened(0.09 * sin(i)), false,
				Vector3(0.34 * sin(i), 1.13 * i, 0.15 * cos(i)))
		_round(Vector3(1.15, 0.28, 0.61), 0.32, 0.57, CHAR, false, Vector3(0.15, 0.11, 0.9))
		return
	for i in 11:
		var x := -2.22 + i * 0.443
		_box(Vector3(x, 3.32, 0), Vector3(0.443, 0.14, 3.38),
			OAK.lightened(0.06 * sin(i * 1.7)), false, Vector3(-0.222, 0, 0))
	for z in [-1.35, 1.35]:
		_box(Vector3(0, 3.22 + z * 0.23, z), Vector3(4.59, 0.16, 0.17), WOOD_EDGE)
	var cart := Vector3(0.58, 0, 0.15)
	_box(cart + Vector3.UP * 0.57, Vector3(1.49, 0.20, 1.12), WOOD_EDGE, true)
	for x in [-0.78, 0.78]:
		_round(cart + Vector3(x, 0.33, 0), 0.34, 0.13, OAK, false, Vector3(0, 0, PI / 2))
		_round(cart + Vector3(x * 1.08, 0.33, 0), 0.083, 0.10, IRON, false, Vector3(0, 0, PI / 2))
		_box(cart + Vector3(x * 0.69, 0.53, 1.0), Vector3(0.11, 0.11, 1.66), OAK, false, Vector3(0.13, 0, 0))
	for z in [-0.72, 0.11]:
		_round(Vector3(-1.27, 0.42, z), 0.32, 0.84, OAK, true)
		for y in [0.20, 0.65]:
			_round(Vector3(-1.27, y, z), 0.333, 0.07, IRON)

func _bench(center: Vector3) -> void:
	_box(center + Vector3.UP * 0.50, Vector3(1.60, 0.12, 0.38), WOOD_EDGE, true)
	for x in [-0.65, 0.65]:
		_box(center + Vector3(x, 0.24, 0), Vector3(0.20, 0.48, 0.37), LIMESTONE, true)

func _herbs(center: Vector3) -> void:
	_box(center + Vector3.UP * 0.24, Vector3(2.10, 0.48, 1.39), LIMESTONE, true)
	_box(center + Vector3.UP * 0.49, Vector3(1.89, 0.035, 1.17), OAK.darkened(0.35))
	for i in 6:
		var at := center + Vector3(-0.75 + (i % 3) * 0.75, 0.59, -0.28 + 0.55 * floorf(i / 3.0))
		_round(at, 0.13 + 0.06 * absf(sin(i * 2.3)), 0.16, Color(0.26, 0.41, 0.20))
		_round(at + Vector3.UP * 0.10, 0.056, 0.08, Color(0.61, 0.48, 0.29))

func _box(at: Vector3, size: Vector3, color: Color, solid := false, tilt := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var shape: BoxShape3D
	if solid:
		shape = BoxShape3D.new()
		shape.size = size
	_place(mesh, at, color, tilt, shape)

func _round(at: Vector3, radius: float, height: float, color: Color, solid := false, tilt := Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 0
	var shape: CylinderShape3D
	if solid:
		shape = CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
	_place(mesh, at, color, tilt, shape)

func _place(mesh: PrimitiveMesh, at: Vector3, color: Color, tilt: Vector3, shape: Shape3D) -> void:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		_materials[color] = material
	mesh.material = _materials[color]
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	if shape:
		var body := StaticBody3D.new()
		body.position = at
		body.rotation = tilt
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		body.add_child(visual)
		add_child(body)
	else:
		visual.position = at
		visual.rotation = tilt
		add_child(visual)
