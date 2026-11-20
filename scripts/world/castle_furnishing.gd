@tool
extends Node3D

enum Place { WORKSHOP, COURTYARD, SUPPLY_SHELTER, BURNED_SHELTER, BARRACKS, KEEP }

@export var place: Place = Place.WORKSHOP

const LIMESTONE := Color(0.39, 0.37, 0.31)
const OAK := Color(0.30, 0.19, 0.115)
const WOOD_EDGE := Color(0.42, 0.28, 0.17)
const IRON := Color(0.15, 0.16, 0.16)
const BRASS := Color(0.58, 0.40, 0.20)
const PAPER := Color(0.77, 0.67, 0.47)
const BLUE := Color(0.25, 0.43, 0.60)
const CHAR := Color(0.125, 0.086, 0.061)
const LINEN := Color(0.67, 0.60, 0.46)
const RED := Color(0.43, 0.15, 0.13)

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
		Place.BARRACKS:
			_barracks()
		Place.KEEP:
			_keep()

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

	var bed := Vector3(-2.17, 0.25, -1.71)
	_bed(bed, -PI / 4.0, BLUE, "AstromancerBed")
	_box(Vector3(-0.90, 0.262, -2.07), Vector3(0.94, 0.024, 1.64), BLUE.darkened(0.21),
		false, Vector3(0, -PI / 4.0, 0))
	_box(Vector3(0.25, 0.48, -3.13), Vector3(0.77, 0.46, 0.56), OAK, true)
	_box(Vector3(0.25, 0.731, -3.13), Vector3(0.82, 0.044, 0.61), WOOD_EDGE)
	_box(Vector3(0.25, 0.52, -2.831), Vector3(0.14, 0.08, 0.026), BRASS)
	_box(Vector3(-2.22, 2.30, -2.81), Vector3(0.50, 0.07, 0.09), IRON,
		false, Vector3(0, -PI / 4.0, 0))
	_lantern(Vector3(-2.05, 1.98, -2.64), 2.30, 0.76, 3.1)

func _barracks() -> void:
	for row in 2:
		for column in 3:
			var bed := Vector3(1.4 + column * 2.12, 0.25, 4.2 + row * 4.55)
			var quilt := RED.lerp(BLUE, float((column + row) % 3) * 0.42)
			_bed(bed, 0.0 if row == 1 else PI, quilt, "GuardBed%d" % (row * 3 + column + 1))
			_locker(bed + Vector3(0, 0, -1.46 if row == 1 else 1.46))
	_table(Vector3(-4.52, 0.25, 6.88), Vector2(1.27, 3.25))
	for x in [-5.71, -3.33]:
		for z in [5.88, 7.92]:
			_bench(Vector3(x, 0.25, z), PI / 2.0)
	for z in [5.88, 7.89]:
		_round(Vector3(-4.38, 1.08, z), 0.14, 0.055, PAPER)
		_round(Vector3(-4.84, 1.17, z + 0.41), 0.09, 0.23, OAK)
	_box(Vector3(-4.53, 0.261, 6.88), Vector3(3.07, 0.017, 4.07), RED.darkened(0.22))
	_box(Vector3(3.57, 0.261, 6.43), Vector3(6.68, 0.017, 1.13), BLUE.darkened(0.34))
	for z in [3.22, 5.43, 7.63, 9.92]:
		_box(Vector3(0, 3.66, z), Vector3(14.77, 0.25, 0.30), OAK)
	for x in [-4.52, 3.60]:
		_lantern(Vector3(x, 3.15, 5.43), 3.535)
		_lantern(Vector3(x, 3.15, 9.92), 3.535)
	for z in [3.25, 9.70]:
		_box(Vector3(-7.28, 2.55, z), Vector3(0.12, 0.11, 2.18), OAK)
		for offset in [-0.63, 0, 0.63]:
			_box(Vector3(-7.17, 2.48, z + offset), Vector3(0.18, 0.15, 0.061), IRON)
		_box(Vector3(-7.23, 2.04, z - 0.62), Vector3(0.14, 0.88, 0.52), RED)
		_box(Vector3(-7.23, 2.11, z + 0.61), Vector3(0.14, 0.75, 0.43), BLUE)
	for x in [-5.15, -2.66]:
		_box(Vector3(x, 1.53, 1.495), Vector3(0.17, 2.56, 0.13), OAK)
	_box(Vector3(-3.905, 2.82, 1.495), Vector3(2.67, 0.21, 0.13), WOOD_EDGE)

	_bench(Vector3(-6.61, 0.25, -4.96), PI / 2.0)
	_table(Vector3(-5.20, 0.25, -8.13), Vector2(2.2, 1.08))
	_box(Vector3(-5.22, 1.066, -8.14), Vector3(0.46, 0.02, 0.30), PAPER, false, Vector3(0, 0.21, 0))
	_gear_rack(Vector3(6.25, 0.25, -3.65))
	_locker(Vector3(6.05, 0.25, -9.06))
	_lantern(Vector3(-3.6, 3.28, -6.2), 3.86)
	_lantern(Vector3(4.64, 3.28, -5.1), 3.86)

func _keep() -> void:
	# Furnish the wide bays while leaving the stair, portals and central aisle open.
	for z in [-10.8, -6.25, -1.7, 6.7]:
		_table(Vector3(-29.05, 0.25, z), Vector2(1.86, 2.72))
		_bench(Vector3(-27.34, 0.25, z), PI / 2.0)
		_box(Vector3(-29.31, 1.071, z + 0.28), Vector3(0.46, 0.026, 0.35), PAPER,
			false, Vector3(0, 0.21, 0))
		_round(Vector3(-29.55, 1.135, z - 0.78), 0.083, 0.15, BRASS)
	for z in [-8.5, -2.2, 4.2]:
		_lantern(Vector3(-27.95, 3.4, z), 6.05)
	for z in [-12.75, -8.35, -3.95, 4.3]:
		_ledger_shelf(Vector3(-31.58, 0.25, z))
	for z in [-10.8, 0.7, 10.1]:
		_table(Vector3(27.5, 0.25, z), Vector2(3.2, 1.47))
		_bench(Vector3(27.5, 0.25, z + 1.27))
		_round(Vector3(26.56, 1.105, z), 0.14, 0.10, PAPER)
		_round(Vector3(27.28, 1.192, z - 0.27), 0.16, 0.27, BLUE)
	for z in [-12.0, -10.75, -9.5, 10.35, 11.6]:
		_locker(Vector3(30.8, 0.25, z))
	for z in [-10.65, 0.8, 10.2]:
		_lantern(Vector3(26.0, 3.5, z), 6.05)
	for z in [-10.65, 9.2]:
		_table(Vector3(26.7, 6.35, z), Vector2(3.1, 1.25))
		_box(Vector3(26.72, 7.175, z), Vector3(2.82, 0.031, 0.38), RED)
		for x in [25.7, 26.7, 27.7]:
			_round(Vector3(x, 7.21, z), 0.17, 0.045, PAPER)

func _bed(at: Vector3, yaw: float, quilt: Color, bed_name: String) -> void:
	var frame := Transform3D(Basis(Vector3.UP, yaw), at)
	var rotation := Vector3(0, yaw, 0)
	var support := _box(frame * Vector3(0, 0.38, 0), Vector3(1.22, 0.18, 2.19), OAK, true, rotation)
	support.name = bed_name
	for x in [-0.54, 0.54]:
		for z in [-1.04, 1.04]:
			var height := 0.97 if z > 0 else 0.51
			_box(frame * Vector3(x, height * 0.5, z), Vector3(0.13, height, 0.13), WOOD_EDGE, false, rotation)
	_box(frame * Vector3(0, 0.73, 1.03), Vector3(0.99, 0.42, 0.075), OAK, true, rotation)
	_box(frame * Vector3(0, 0.52, -0.028), Vector3(1.09, 0.13, 1.98), LINEN, true, rotation)
	_box(frame * Vector3(0, 0.635, 0.76), Vector3(0.63, 0.103, 0.35), PAPER, false, rotation)
	_box(frame * Vector3(0, 0.617, -0.27), Vector3(1.125, 0.065, 1.42), quilt, false, rotation)
	_box(frame * Vector3(0, 0.652, 0.34), Vector3(1.115, 0.022, 0.13), quilt.lightened(0.30), false, rotation)

func _locker(at: Vector3) -> void:
	_box(at + Vector3.UP * 0.24, Vector3(0.80, 0.48, 0.50), OAK, true)
	_box(at + Vector3.UP * 0.504, Vector3(0.88, 0.05, 0.57), WOOD_EDGE)
	for x in [-0.29, 0.29]:
		_box(at + Vector3(x, 0.245, -0.254), Vector3(0.06, 0.43, 0.016), IRON)

func _table(at: Vector3, size: Vector2) -> void:
	_box(at + Vector3.UP * 0.75, Vector3(size.x, 0.12, size.y), WOOD_EDGE, true)
	for x in [-1, 1]:
		for z in [-1, 1]:
			_box(at + Vector3(x * (size.x * 0.5 - 0.12), 0.345, z * (size.y * 0.5 - 0.13)),
				Vector3(0.13, 0.69, 0.13), OAK, true)

func _gear_rack(at: Vector3) -> void:
	for z in [-1.14, 1.14]:
		_box(at + Vector3(0, 1.12, z), Vector3(0.29, 2.24, 0.15), OAK, true)
	_box(at + Vector3.UP * 1.43, Vector3(0.36, 0.18, 2.47), WOOD_EDGE)
	for z in [-0.79, -0.27, 0.27, 0.79]:
		_box(at + Vector3(-0.20, 0.95, z), Vector3(0.082, 1.9, 0.08), OAK)
		_box(at + Vector3(-0.20, 1.98, z), Vector3(0.08, 0.29, 0.18), IRON)
	_round(at + Vector3(-0.24, 1.18, 0.59), 0.35, 0.105, RED, false, Vector3(0, 0, PI / 2))

func _ledger_shelf(at: Vector3) -> void:
	for z in [-0.76, 0.76]:
		_box(at + Vector3(0, 0.95, z), Vector3(0.53, 1.9, 0.12), OAK, true)
	for y in [0.18, 0.73, 1.28, 1.83]:
		_box(at + Vector3.UP * y, Vector3(0.55, 0.09, 1.43), WOOD_EDGE, true)
	for i in 7:
		var height := 0.22 + 0.04 * i
		var color := LINEN.lerp(RED, fmod(0.39 * i, 1.0))
		_box(at + Vector3(0.066, 0.775 + height * 0.5, -0.55 + i * 0.18),
			Vector3(0.34, height, 0.13), color)
		_box(at + Vector3(0.073, 1.36 + i * 0.014, -0.35 + i * 0.10),
			Vector3(0.30, 0.045, 0.39), PAPER, false, Vector3(0, 0.11 * i, 0))

func _lantern(at: Vector3, mount_y: float, energy := 1.28, reach := 6.7) -> void:
	var hanger := mount_y - at.y - 0.12
	_round(at + Vector3.UP * (0.12 + hanger * 0.5), 0.035, hanger, IRON)
	_round(at, 0.134, 0.20, Color(0.91, 0.65, 0.32))
	for y in [-0.12, 0.12]:
		_round(at + Vector3.UP * y, 0.17, 0.05, IRON)
	_light(at - Vector3.UP * 0.16, energy, reach)

func _light(at: Vector3, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(1.0, 0.72, 0.43)
	light.light_energy = energy
	light.omni_range = reach
	add_child(light)

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
	# The farrier works under a lean-to off the main thoroughfare.
	var workyard := Vector3(-11.20, 0, -13.81)
	_round(workyard + Vector3.UP * 0.018, 2.88, 0.031, LIMESTONE.darkened(0.31))
	for x in [-2.02, 2.02]:
		for z in [-1.52, 1.24]:
			var height: float = 2.81 + z * 0.20
			_box(workyard + Vector3(x, 0.18, z), Vector3(0.36, 0.36, 0.36), LIMESTONE, true)
			_box(workyard + Vector3(x, 0.36 + height * 0.5, z),
				Vector3(0.16, height, 0.16), OAK, true)
	for z in [-1.52, 1.24]:
		_box(workyard + Vector3(0, 3.14 + z * 0.20, z),
			Vector3(4.4, 0.16, 0.16), OAK)
	for i in 10:
		_box(workyard + Vector3(-2.13 + i * 0.474, 3.27, 0), Vector3(0.474, 0.10, 3.40),
			WOOD_EDGE.darkened(0.14 + 0.11 * sin(i * 2.37)), false, Vector3(-0.198, 0, 0))
	_table(Vector3(-10.5, 0, -13.43), Vector2(2.75, 1.18))
	_bench(Vector3(-10.5, 0, -11.60))
	_locker(Vector3(-12.69, 0, -13.24))
	_box(Vector3(-10.18, 0.868, -13.47), Vector3(0.46, 0.124, 0.32), IRON)
	_box(Vector3(-10.23, 0.998, -13.47), Vector3(0.69, 0.136, 0.26), IRON)
	_box(Vector3(-11.05, 0.29, -15.03), Vector3(1.15, 0.58, 0.79), LIMESTONE, true)
	_box(Vector3(-11.05, 0.595, -15.03), Vector3(0.89, 0.04, 0.58), IRON)
	for x in [-11.54, -10.56]:
		_box(Vector3(x, 0.668, -15.03), Vector3(0.16, 0.18, 0.76), LIMESTONE)
	for z in [-29.3, -31.6, -33.9]:
		_round(Vector3(9.3, 0.37, z), 0.35, 0.74, OAK, true)
		for y in [0.14, 0.60]:
			_round(Vector3(9.3, y, z), 0.366, 0.07, IRON)

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

func _bench(center: Vector3, yaw := 0.0) -> void:
	var frame := Transform3D(Basis(Vector3.UP, yaw), center)
	var rotation := Vector3(0, yaw, 0)
	_box(frame * (Vector3.UP * 0.50), Vector3(1.60, 0.12, 0.38), WOOD_EDGE, true, rotation)
	for x in [-0.65, 0.65]:
		_box(frame * Vector3(x, 0.24, 0), Vector3(0.20, 0.48, 0.37), LIMESTONE, true, rotation)

func _herbs(center: Vector3) -> void:
	_box(center + Vector3.UP * 0.24, Vector3(2.10, 0.48, 1.39), LIMESTONE, true)
	_box(center + Vector3.UP * 0.49, Vector3(1.89, 0.035, 1.17), OAK.darkened(0.35))
	for i in 6:
		var at := center + Vector3(-0.75 + (i % 3) * 0.75, 0.59, -0.28 + 0.55 * floorf(i / 3.0))
		_round(at, 0.13 + 0.06 * absf(sin(i * 2.3)), 0.16, Color(0.26, 0.41, 0.20))
		_round(at + Vector3.UP * 0.10, 0.056, 0.08, Color(0.61, 0.48, 0.29))

func _box(at: Vector3, size: Vector3, color: Color, solid := false, tilt := Vector3.ZERO) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var shape: BoxShape3D
	if solid:
		shape = BoxShape3D.new()
		shape.size = size
	return _place(mesh, at, color, tilt, shape)

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

func _place(mesh: PrimitiveMesh, at: Vector3, color: Color, tilt: Vector3, shape: Shape3D) -> Node3D:
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
		return body
	visual.position = at
	visual.rotation = tilt
	add_child(visual)
	return visual
