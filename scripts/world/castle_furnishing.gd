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
	_dining_room()
	_keep_kitchen()
	_keep_cellar()
	_keep_stair_guards()
	_upper_service_room()
	_steward_room()


func _dining_room() -> void:
	for x in [20.55, 27.15]:
		var table := Vector3(x, 0.25, 6.25)
		_box(table + Vector3.UP * 0.012, Vector3(4.22, 0.019, 9.25), RED.darkened(0.34))
		_box(table + Vector3.UP * 0.026, Vector3(3.86, 0.011, 8.88), RED.darkened(0.20))
		_table(table, Vector2(1.86, 7.80))
		_box(table + Vector3.UP * 0.819, Vector3(0.51, 0.018, 7.37), RED)
		for side in [-1.0, 1.0]:
			for z in [3.55, 6.25, 8.95]:
				_bench(Vector3(x + 1.29 * side, 0.25, z), PI / 2.0)
			for i in 6:
				var place_at := table + Vector3(side * 0.62, 0.832, -3.12 + 1.22 * i)
				_round(place_at, 0.168, 0.034, LINEN)
				_round(place_at + Vector3(0, 0.071, 0.37), 0.072, 0.14, BRASS if i % 2 == 0 else BLUE)
		for z in [-2.15, 0.08, 2.2]:
			var platter := table + Vector3(0, 0.845, z)
			_round(platter, 0.21, 0.033, BRASS)
			for x_shift in [-0.096, 0.105]:
				_round(platter + Vector3(x_shift, 0.080, 0), 0.070, 0.13, WOOD_EDGE.lightened(0.18))
		_chandelier(Vector3(x, 3.83, 6.25))
	_table(Vector3(30.65, 0.25, -0.32), Vector2(0.90, 3.7))
	for z in [-1.34, -0.38, 0.64]:
		_round(Vector3(30.60, 1.22, z), 0.15, 0.33, BLUE)
		_round(Vector3(30.60, 1.39, z), 0.094, 0.07, BLUE.lightened(0.14))
	for x in [19.0, 28.8]:
		_wall_hanging(Vector3(x, 3.35, 14.46), RED)
	for z in [-1.22, 1.22]:
		_box(Vector3(12.56, 1.61, z), Vector3(0.15, 2.72, 0.22), LIMESTONE)
	_box(Vector3(12.54, 3.035, 0), Vector3(0.18, 0.24, 2.77), LIMESTONE)
	_lantern(Vector3(17.10, 3.88, 0), 6.05, 1.45, 7.0)
	_lantern(Vector3(18.06, 3.66, -2.03), 6.05, 1.2, 5.8)
	for x in [21.75, 22.4, 23.22]:
		_round(Vector3(x, 1.43, -3.40), 0.17, 0.08, LINEN)
	_box(Vector3(22.53, 2.59, -3.18), Vector3(2.75, 0.15, 0.17), OAK)


func _chandelier(at: Vector3) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.65
	ring.outer_radius = 0.77
	ring.rings = 12
	ring.ring_segments = 6
	_place(ring, at, IRON, Vector3.ZERO, null)
	var drop := 6.05 - at.y
	_round(at + Vector3.UP * drop * 0.5, 0.038, drop, IRON)
	for angle in [0.0, PI / 2.0]:
		_box(at, Vector3(1.41, 0.055, 0.09), IRON, false, Vector3(0, angle, 0))
	for i in 8:
		var a := TAU * i / 8.0
		var candle := at + Vector3(cos(a) * 0.702, 0.12, sin(a) * 0.702)
		_round(candle, 0.050, 0.14, LINEN)
		_round(candle + Vector3.UP * 0.098, 0.023, 0.054, Color(1.0, 0.70, 0.32))
	_light(at - Vector3.UP * 0.17, 2.6, 9.0)


func _wall_hanging(at: Vector3, color: Color) -> void:
	_box(at, Vector3(1.53, 1.99, 0.053), color)
	_box(at + Vector3(0, 1.01, -0.047), Vector3(1.88, 0.076, 0.10), OAK)
	_box(at + Vector3(0, 0.09, -0.037), Vector3(0.44, 0.44, 0.028), BRASS,
		false, Vector3(0, 0, PI / 4.0))
	_box(at + Vector3(0, -0.88, -0.037), Vector3(1.45, 0.085, 0.027), BRASS)


func _keep_kitchen() -> void:
	for x in [17.0, 23.0]:
		_lantern(Vector3(x, 3.97, -7.38), 6.05, 1.65, 7.3)
	_hearth(Vector3(20.64, 0.25, -14.46))
	_provision_rack(Vector3(14.08, 0.25, -8.9), PI / 2.0)
	_provision_rack(Vector3(14.08, 0.25, -12.42), PI / 2.0)
	for z in [-11.95, -7.78]:
		var bench := Vector3(24.13, 0.25, z)
		_table(bench, Vector2(1.48, 2.72))
		_box(bench + Vector3(0.22, 0.829, 0.22), Vector3(0.75, 0.036, 0.91), WOOD_EDGE.darkened(0.19))
		_box(bench + Vector3(0.31, 0.88, 0.19), Vector3(0.29, 0.025, 0.116), IRON)
		_box(bench + Vector3(0.51, 0.89, 0.19), Vector3(0.13, 0.050, 0.081), OAK)
		for i in 3:
			_round(bench + Vector3(-0.31, 0.88, -0.69 + i * 0.25), 0.086, 0.145,
				Color(0.42, 0.29, 0.14).lightened(0.09 * i))
	_provision_barrel(Vector3(18.48, 0.25, -13.77), 0.38)
	_box(Vector3(23.4, 2.52, -14.36), Vector3(2.29, 0.13, 0.16), OAK)
	for i in 4:
		var x := 22.62 + 0.46 * i
		_box(Vector3(x, 2.29, -14.27), Vector3(0.059, 0.46, 0.054), IRON)
		_round(Vector3(x, 1.99, -14.25), 0.14 + 0.025 * i, 0.09, IRON,
			false, Vector3(PI / 2.0, 0, 0))
	_box(Vector3(28.68, 2.63, -5.76), Vector3(0.28, 0.07, 0.095), IRON)
	_round(Vector3(28.83, 2.78, -5.76), 0.078, 0.235, Color(0.93, 0.65, 0.31))
	_round(Vector3(28.83, 2.64, -5.76), 0.104, 0.055, IRON)
	_light(Vector3(29.04, 2.80, -5.76), 1.40, 5.35)


func _hearth(at: Vector3) -> void:
	_box(at + Vector3(0, 0.13, 0.86), Vector3(3.38, 0.26, 1.57), LIMESTONE, true)
	_box(at + Vector3(0, 1.02, 0.15), Vector3(2.41, 1.96, 0.29), CHAR, true)
	for x in [-1.45, 1.45]:
		_box(at + Vector3(x, 1.23, 0.80), Vector3(0.48, 2.19, 1.48), LIMESTONE, true)
	_box(at + Vector3(0, 2.33, 0.80), Vector3(3.38, 0.38, 1.48), LIMESTONE, true)
	for i in 4:
		_box(at + Vector3(0, 2.66 + i * 0.285, 0.63 - i * 0.07),
			Vector3(2.98 - i * 0.48, 0.285, 1.36 - i * 0.21), LIMESTONE, true)
	_box(at + Vector3(0, 4.727, 0.42), Vector3(1.06, 2.146, 0.78), LIMESTONE, true)
	_box(at + Vector3(0, 1.78, 0.85), Vector3(2.50, 0.087, 0.093), IRON)
	_round(at + Vector3(0, 1.56, 0.92), 0.043, 0.42, IRON)
	_round(at + Vector3(0, 1.13, 0.92), 0.43, 0.49, IRON)
	_round(at + Vector3(0, 1.36, 0.92), 0.47, 0.06, IRON)
	for i in 5:
		var x := -0.53 + 0.26 * i
		var z := 0.94 + 0.29 * sin(i * 2.2)
		_box(at + Vector3(x, 0.38, z), Vector3(0.29, 0.15, 0.61), CHAR,
			false, Vector3(0, sin(i * 2.6), 0))
		_round(at + Vector3(x, 0.445, z), 0.103, 0.064, Color(0.92, 0.35, 0.10))
	_light(at + Vector3(0, 1.15, 1.3), 1.8, 5.85)


func _keep_cellar() -> void:
	_provision_rack(Vector3(23.96, -3.55, -11.51), PI / 2.0, 0.88)
	_provision_rack(Vector3(21.17, -3.55, -14.29), 0.0, 0.88)
	for x in [19.20, 20.24, 21.26, 22.28]:
		_provision_barrel(Vector3(x, -3.55, -9.05), 0.41)
	_table(Vector3(20.96, -3.55, -11.3), Vector2(1.9, 0.9))
	for x in [20.51, 21.24]:
		_round(Vector3(x, -2.66, -11.3), 0.184, 0.13, LINEN)
	_lantern(Vector3(18.5, -1.45, -12.60), -1.0, 1.35, 6.35)
	_lantern(Vector3(22.45, -1.45, -10.55), -1.0, 1.30, 6.1)
	_lantern(Vector3(16.3, 1.95, -8.20), 6.05, 0.9, 5.35)


func _upper_service_room() -> void:
	_table(Vector3(19.46, 6.35, -7.28), Vector2(2.05, 3.7))
	for z in [-8.05, -6.88]:
		_box(Vector3(19.42, 7.24, z), Vector3(0.62, 0.13, 0.72), LINEN)
	for x in [18.32, 20.26, 22.32]:
		_locker(Vector3(x, 6.35, -13.90))
	for x in [22.26, 24.32]:
		_bench(Vector3(x, 6.35, -4.32))
	_lantern(Vector3(19.69, 9.71, -7.26), 12.0, 1.64, 8.1)
	_lantern(Vector3(27.02, 9.41, -2.31), 12.0, 1.30, 6.5)


func _keep_stair_guards() -> void:
	for x in [25.40, 31.30]:
		_stair_guard(Vector3(x, 6.35, -13.84), Vector3(x, 6.35, -4.85))
	_stair_guard(Vector3(25.40, 6.35, -13.84), Vector3(31.30, 6.35, -13.84))
	_stair_guard(Vector3(28.54, 6.35, -4.76), Vector3(31.30, 6.35, -4.76))


func _stair_guard(from: Vector3, to: Vector3) -> void:
	var delta := to - from
	var length := delta.length()
	var tilt := Vector3(0, atan2(-delta.z, delta.x), 0)
	for y in [0.14, 0.905]:
		_box(from.lerp(to, 0.5) + Vector3.UP * y, Vector3(length, 0.13, 0.18), WOOD_EDGE, false, tilt)
	var bays := maxi(1, ceili(length / 0.64))
	for i in bays + 1:
		var post := from.lerp(to, i / float(bays))
		var width := 0.17 if i in [0, bays] else 0.095
		_box(post + Vector3.UP * 0.47, Vector3(width, 0.94, width), OAK)


func _steward_room() -> void:
	var desk := Vector3(19.20, 6.35, 9.61)
	_box(desk + Vector3.UP * 0.013, Vector3(5.34, 0.022, 6.12), BLUE.darkened(0.26))
	_table(desk, Vector2(3.5, 1.45))
	_bench(desk + Vector3(0, 0, 1.43))
	for x in [-0.99, -0.31, 0.61]:
		_box(desk + Vector3(x, 0.833, 0.04), Vector3(0.48, 0.046, 0.41), PAPER,
			false, Vector3(0, 0.31 * x, 0))
	_round(desk + Vector3(1.20, 0.94, 0.08), 0.085, 0.24, BRASS)
	for z in [5.65, 8.0, 10.33]:
		_ledger_shelf(Vector3(14.02, 6.35, z))
	_wall_hanging(Vector3(19.20, 9.72, 14.46), BLUE.darkened(0.12))
	for z in [6.44, 9.38, 12.3]:
		_locker(Vector3(30.45, 6.35, z))
	_table(Vector3(27.33, 6.35, 11.66), Vector2(2.58, 1.42))
	_round(Vector3(27.21, 7.42, 11.47), 0.25, 0.47, BLUE)
	_round(Vector3(27.21, 7.69, 11.47), 0.11, 0.15, BLUE.lightened(0.16))
	_lantern(Vector3(19.44, 9.80, 8.3), 12.0, 1.95, 8.4)
	_lantern(Vector3(26.84, 9.71, 9.5), 12.0, 1.4, 6.8)


func _provision_rack(at: Vector3, yaw: float, height_scale := 1.0) -> void:
	var frame := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(1, height_scale, 1)), at)
	var tilt := Vector3(0, yaw, 0)
	for x in [-1.43, 1.43]:
		_box(frame * Vector3(x, 1.32, 0), Vector3(0.14, 2.64 * height_scale, 0.69), OAK, true, tilt)
	for height in [0.22, 1.0, 1.78, 2.53]:
		_box(frame * (Vector3.UP * height), Vector3(2.83, 0.12, 0.65), WOOD_EDGE, true, tilt)
	for i in 5:
		var x := -1.11 + i * 0.55
		var color := BLUE.lerp(LINEN, (i % 3) / 3.0)
		_round(frame * Vector3(x, 1.31, 0.04), 0.16, 0.49, color)
		_round(frame * Vector3(x, 1.57, 0.04), 0.12, 0.064, color.lightened(0.19))
	for x in [-0.81, 0.07, 0.97]:
		_box(frame * Vector3(x, 0.50, 0.04), Vector3(0.63, 0.43, 0.49), OAK, false, tilt)
	for x in [-1.01, -0.45, 0.15, 0.74]:
		_round(frame * Vector3(x, 1.96, 0.01), 0.18, 0.24, LINEN.darkened(x * 0.08 + 0.12))


func _provision_barrel(at: Vector3, radius: float) -> void:
	_round(at + Vector3.UP * 0.44, radius, 0.88, OAK, true)
	for y in [0.18, 0.71]:
		_round(at + Vector3.UP * y, radius + 0.018, 0.075, IRON)


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
