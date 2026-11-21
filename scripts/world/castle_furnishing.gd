@tool
extends Node3D

enum Place { WORKSHOP, COURTYARD, SUPPLY_SHELTER, BURNED_SHELTER, BARRACKS, KEEP, CHAPEL, OBSERVATORY, BRIDGE, BURNED_YARD }

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
		Place.CHAPEL:
			_chapel()
		Place.OBSERVATORY:
			_observatory()
		Place.BRIDGE:
			_bridge()
		Place.BURNED_YARD:
			_burned_yard()

func _chapel() -> void:
	_box(Vector3(0.93, 0.260, 0), Vector3(8.62, 0.015, 1.52), BLUE.darkened(0.48))
	for z in [-0.690, 0.690]:
		_box(Vector3(0.93, 0.269, z), Vector3(8.60, 0.006, 0.038), BRASS.darkened(0.12))
	for row_x in [4.21, 2.48, 0.72]:
		for z in [-3.27, 3.27]:
			var pew := Vector3(row_x, 0.25, z)
			_box(pew + Vector3.UP * 0.49, Vector3(0.66, 0.12, 2.76), WOOD_EDGE, true)
			_box(pew + Vector3(0.29, 0.82, 0), Vector3(0.105, 0.65, 2.76), OAK, true,
				Vector3(0, 0, -0.09))
			_box(pew + Vector3(0.31, 1.135, 0), Vector3(0.15, 0.077, 2.82), WOOD_EDGE)
			for end in [-1.32, 1.32]:
				_box(pew + Vector3(0.012, 0.37, end), Vector3(0.73, 0.73, 0.15), OAK, true)
				_box(pew + Vector3(0.04, 0.75, end), Vector3(0.61, 0.07, 0.173), WOOD_EDGE)

	var altar := Vector3(-2.5, 1.22, 0)
	_box(altar + Vector3.UP * 0.011, Vector3(1.05, 0.018, 2.36), BLUE.darkened(0.17))
	for z in [-1.05, 1.05]:
		_box(altar + Vector3(0.805, -0.19, z), Vector3(0.015, 0.41, 0.32), BLUE.darkened(0.17))
		_box(altar + Vector3(0.812, -0.367, z), Vector3(0.018, 0.038, 0.32), BRASS)
		for i in 3:
			_candle(altar + Vector3(-0.42 + i * 0.32, 0.0, z), 0.17 + 0.07 * sin(i * 1.5))
	for z in [-2.02, 2.02]:
		var stand := Vector3(-3.71, 0.25, z)
		_round(stand + Vector3.UP * 0.055, 0.225, 0.11, IRON, true)
		_round(stand + Vector3.UP * 0.57, 0.045, 1.11, IRON, true)
		_round(stand + Vector3.UP * 1.115, 0.145, 0.06, BRASS)
		_candle(stand + Vector3.UP * 1.145, 0.37)
		_light(stand + Vector3.UP * 1.65, 0.66, 3.4)
	var votive_shelf := Vector3(-6.15, 1.21, 0)
	_box(votive_shelf, Vector3(0.48, 0.15, 3.87), LIMESTONE, true)
	for z in [-1.52, 0.0, 1.52]:
		_box(votive_shelf + Vector3(-0.09, -0.23, z), Vector3(0.34, 0.42, 0.21), LIMESTONE)
	for i in 8:
		var z := -1.65 + i * 0.47
		_candle(votive_shelf + Vector3(0.07 * sin(i * 6.1), 0.075, z), 0.15 + 0.09 * absf(sin(i * 1.6)))
	_light(votive_shelf + Vector3(0.41, 0.47, 0), 0.52, 3.1)
	_round(Vector3(5.28, 0.58, 4.79), 0.29, 0.66, LIMESTONE, true)
	_round(Vector3(5.28, 0.97, 4.79), 0.42, 0.19, LIMESTONE.lightened(0.05), true)
	_round(Vector3(5.28, 1.069, 4.79), 0.29, 0.012, BLUE.darkened(0.42))

func _candle(at: Vector3, height: float) -> void:
	_round(at + Vector3.UP * 0.025, 0.095, 0.05, BRASS)
	_round(at + Vector3.UP * (0.05 + height * 0.5), 0.042, height, LINEN.lightened(0.16))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.69, 0.24)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.45, 0.10)
	glow.emission_energy_multiplier = 1.28
	var flame := SphereMesh.new()
	flame.radius = 0.026
	flame.height = 0.082
	flame.radial_segments = 6
	flame.rings = 3
	flame.material = glow
	var wick := MeshInstance3D.new()
	wick.mesh = flame
	wick.position = at + Vector3.UP * (height + 0.085)
	add_child(wick)

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
	var scales := table + Vector3(-0.20, 1.084, 0.22)
	_round(scales + Vector3.UP * 0.026, 0.13, 0.052, BRASS)
	_round(scales + Vector3.UP * 0.225, 0.022, 0.43, IRON)
	_box(scales + Vector3.UP * 0.43, Vector3(0.44, 0.031, 0.024), BRASS, false, Vector3(0, 0, 0.06))
	for x in [-0.18, 0.18]:
		_round(scales + Vector3(x, 0.34, 0.0), 0.009, 0.18, BRASS)
		_round(scales + Vector3(x, 0.242, 0.0), 0.093, 0.022, BRASS)
	_earthenware(table + Vector3(0.46, 1.084, 0.26), 0.66, BLUE.darkened(0.11))

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
	_locker(Vector3(6.35, 0.25, -1.78))
	_lantern(Vector3(-3.6, 3.28, -6.2), 3.86)
	_lantern(Vector3(4.64, 3.28, -5.1), 3.86)
	_guard_wall_rack(Vector3(7.21, 0.25, -5.92))
	_table(Vector3(2, 0.25, -7.0), Vector2(3.2, 1.6), 0.87)
	_box(Vector3(2.0, 0.923, -6.31), Vector3(2.84, 0.20, 0.17), OAK, true)
	for x in [1.23, 2.77]:
		_box(Vector3(x, 0.923, -6.219), Vector3(0.24, 0.041, 0.045), BRASS)
	_candle(Vector3(1.07, 1.12, -7.49), 0.154)
	_earthenware(Vector3(-5.63, 1.067, -8.34), 1.0, BLUE.darkened(0.16))

	# Linen and wash water stay against the dormitory walls, outside its aisle.
	_provision_rack(Vector3(-6.91, 0.25, 2.92), PI / 2.0, 0.72)
	for z in [5.05, 8.90]:
		_provision_barrel(Vector3(-6.86, 0.25, z), 0.26)
	var wash := Vector3(6.78, 0.25, 6.46)
	_table(wash, Vector2(0.94, 1.30))
	_round(wash + Vector3(-0.12, 0.89, 0.15), 0.29, 0.15, BLUE.darkened(0.19))
	_round(wash + Vector3(-0.12, 0.969, 0.15), 0.252, 0.012, BLUE.lightened(0.12))
	_box(wash + Vector3(0.11, 0.853, -0.31), Vector3(0.39, 0.085, 0.28), LINEN)

	# A bench for oiling and repairing equipment fits beside the captain's desk.
	_hearth(Vector3(5.70, 0.25, -10.40))
	var armorer := Vector3(2.38, 0.25, -9.68)
	_table(armorer, Vector2(1.60, 0.85))
	_earthenware(armorer + Vector3(0.53, 0.81, 0.03), 0.90, OAK)
	_box(armorer + Vector3(-0.17, 0.845, -0.12), Vector3(0.63, 0.067, 0.31), RED.darkened(0.18))
	_box(armorer + Vector3(-0.09, 0.90, -0.12), Vector3(0.16, 0.078, 0.32), IRON,
		false, Vector3(0, 0.34, 0))
	_box(Vector3(3.26, 1.85, -10.30), Vector3(1.12, 0.54, 0.15), OAK, true)
	_box(Vector3(3.26, 1.85, -10.213), Vector3(0.95, 0.39, 0.028), PAPER)
	for i in 5:
		_box(Vector3(3.26, 1.99 - i * 0.063, -10.194), Vector3(0.63 + 0.12 * sin(i * 2.2), 0.013, 0.009), OAK)
	_provision_barrel(Vector3(0.28, 0.25, -9.5), 0.33)

func _guard_wall_rack(at: Vector3) -> void:
	_box(at + Vector3(0.0, 1.64, 0), Vector3(0.14, 0.13, 2.12), OAK, true)
	for side: float in [-1.0, 1.0]:
		var z := side * 0.52
		_box(at + Vector3(-0.075, 1.56, z), Vector3(0.22, 0.052, 0.079), IRON)
		_box(at + Vector3(-0.155, 1.225, z), Vector3(0.15, 0.69, 0.44),
			BLUE.darkened(0.21) if side > 0 else RED, true)
		_box(at + Vector3(-0.247, 1.127, z), Vector3(0.034, 0.046, 0.43), BRASS.darkened(0.12))
		_box(at + Vector3(-0.193, 1.187, z - 0.263), Vector3(0.111, 0.54, 0.14), RED.darkened(0.17),
			false, Vector3(0.26, 0, 0))
		_box(at + Vector3(-0.193, 1.187, z + 0.263), Vector3(0.111, 0.54, 0.14), RED.darkened(0.17),
			false, Vector3(-0.26, 0, 0))
	_round(at + Vector3(-0.17, 2.05, -0.45), 0.20, 0.18, IRON)
	_round(at + Vector3(-0.17, 1.92, -0.45), 0.24, 0.055, IRON)
	_box(at + Vector3(0.008, 1.808, 0), Vector3(0.48, 0.13, 2.16), WOOD_EDGE, true)

func _keep() -> void:
	_lower_library()
	_upper_library()
	_throne()
	_dining_room()
	_keep_kitchen()
	_keep_cellar()
	_keep_stair_guards()
	_upper_service_room()
	_steward_room()

func _upper_library() -> void:
	for x in [-29.19, -28.75]:
		_box(Vector3(x, 7.127, -0.45), Vector3(0.30, 0.034, 0.46), PAPER,
			false, Vector3(0, (x + 29.0) * 0.7, 0))
	_round(Vector3(-29.06, 7.17, 0.34), 0.078, 0.11, IRON)
	_box(Vector3(-29.04, 7.242, 0.34), Vector3(0.016, 0.012, 0.21), BRASS, false, Vector3(0, 0.52, -0.09))
	_lantern(Vector3(-28.55, 8.32, -6.16), 11.97, 1.5, 5.5)
	_lantern(Vector3(-28.55, 8.32, 7.73), 11.97, 1.28, 5.4)
	for at in [Vector3(-26.4, 6.35, -12.2), Vector3(-26.1, 6.35, 8.5)]:
		_table(at, Vector2(1.32, 0.87))
		_box(at + Vector3(0.18, 0.835, -0.12), Vector3(0.38, 0.044, 0.26), RED, false, Vector3(0, -0.20, 0))
		_candle(at + Vector3(-0.44, 0.82, 0.145), 0.15)

func _throne() -> void:
	const VELVET := Color(0.39, 0.086, 0.095)
	var dais := Vector3(0, 1.03, -10.20)
	for x in [-0.83, 0.83]:
		for z in [-0.63, 0.63]:
			_box(dais + Vector3(x, 0.23, z), Vector3(0.28, 0.46, 0.27), OAK, true)
			_box(dais + Vector3(x, 0.076, z), Vector3(0.30, 0.145, 0.29), BRASS.darkened(0.13))
		_box(dais + Vector3(x, 0.63, 0.58), Vector3(0.18, 0.75, 0.19), OAK)
		_box(dais + Vector3(x, 0.96, -0.03), Vector3(0.26, 0.14, 1.36), WOOD_EDGE, true)
		_round(dais + Vector3(x, 1.06, 0.63), 0.133, 0.16, BRASS)
		_box(dais + Vector3(x, 1.67, -0.70), Vector3(0.20, 1.98, 0.30), OAK)
		_round(dais + Vector3(x, 2.69, -0.70), 0.114, 0.18, BRASS)
	_box(dais + Vector3(0, 0.58, 0), Vector3(1.97, 0.23, 1.58), OAK, true)
	_box(dais + Vector3(0, 0.728, 0.06), Vector3(1.51, 0.14, 1.37), VELVET)
	_box(dais + Vector3(0, 0.66, 0.792), Vector3(1.76, 0.042, 0.028), BRASS)
	_box(dais + Vector3(0, 1.74, -0.72), Vector3(1.52, 1.86, 0.25), OAK, true)
	_box(dais + Vector3(0, 1.73, -0.545), Vector3(1.38, 1.58, 0.17), VELVET)
	_box(dais + Vector3(0, 2.60, -0.70), Vector3(1.72, 0.21, 0.31), WOOD_EDGE)
	_box(dais + Vector3(0, 1.91, -0.447), Vector3(0.30, 0.30, 0.033), BRASS, false,
		Vector3(0, 0, PI / 4))
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 2.21, 0.273, 2.54), Vector3(0.056, 0.004, 17.50), BRASS.darkened(0.24))
		_box(Vector3(side * 2.05, 0.274, 2.75), Vector3(0.022, 0.005, 17.02), BRASS.darkened(0.24))
	for x in [-5.48, 5.48]:
		for z in [2.28, 8.7]:
			_round(Vector3(x, 0.31, z), 0.28, 0.13, LIMESTONE, true)
			_round(Vector3(x, 0.94, z), 0.075, 1.15, IRON, true)
			_round(Vector3(x, 1.54, z), 0.24, 0.11, BRASS)
			_candle(Vector3(x, 1.60, z), 0.26)
			_light(Vector3(x, 2.02, z), 0.52, 4.7)

func _observatory() -> void:
	_round(Vector3(0, 20.26, 0), 0.69, 0.20, OAK)
	_round(Vector3(0, 20.41, 0), 0.57, 0.12, BRASS.darkened(0.17))
	for i in 6:
		var angle := i * TAU / 6.0
		var radial := Vector3(cos(angle), 0, sin(angle))
		_box(Vector3(0, 20.64, 0) + radial * 0.48, Vector3(0.23, 0.42, 0.26), OAK, false, Vector3(0, -angle, 0))
	_round(Vector3(0, 20.99, 0), 0.83, 0.20, WOOD_EDGE)
	_round(Vector3(0, 21.095, 0), 0.70, 0.017, BRASS)
	_round(Vector3(0, 21.108, 0), 0.55, 0.015, IRON)
	_round(Vector3(0.74, 21.116, 0.53), 0.24, 0.052, BRASS)
	_round(Vector3(0.74, 21.148, 0.53), 0.19, 0.017, BLUE.darkened(0.45))
	for angle in [0.42, 2.54, 4.66]:
		var radial := Vector3(cos(angle), 0, sin(angle))
		_box(Vector3(0, 21.38, 0) + radial * 0.62, Vector3(0.075, 0.51, 0.095), BRASS,
			false, Vector3(0, -angle, -0.33))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.577
	ring.outer_radius = 0.635
	ring.rings = 16
	ring.ring_segments = 6
	_place(ring, Vector3(0, 21.70, 0), BRASS, Vector3(-0.21, 0.3, 0.24), null)

	var chart_table := Vector3(0.65, 20.15, -2.90)
	_table(chart_table, Vector2(1.17, 0.75))
	_box(chart_table + Vector3(0.02, 0.822, -0.03), Vector3(0.66, 0.024, 0.45), PAPER,
		false, Vector3(0, -0.23, 0))
	_round(chart_table + Vector3(0.10, 0.847, 0.11), 0.175, 0.027, BRASS)
	_candle(chart_table + Vector3(-0.42, 0.81, 0.23), 0.14)

func _bridge() -> void:
	for z in [-10.6, -13.1, -15.6, -18.1, -20.6]:
		_box(Vector3(0, 9.53, z), Vector3(3.06, 0.20, 0.21), OAK)
		for x in [-1.43, 1.43]:
			_box(Vector3(x, 8.18, z), Vector3(0.15, 2.79, 0.21), OAK, true)
	for z in [-12.13, -19.06]:
		var side := -1.0 if z > -15.0 else 1.0
		_box(Vector3(side * 1.433, 8.44, z), Vector3(0.19, 0.17, 0.49), IRON)
		_candle(Vector3(side * 1.37, 8.51, z), 0.20)
		_light(Vector3(side * 1.25, 8.75, z), 0.54, 4.3)

func _burned_yard() -> void:
	# Ash collects on the avenue edge. The burned cart stays outside the passage.
	var cart := Vector3(-10.6, 0, -32.7)
	for i in 6:
		_box(cart + Vector3(i * 0.34 - 0.85, 0.16 + 0.05 * sin(i * 1.8), 0.12 * cos(i)),
			Vector3(0.25, 0.12, 1.62 - 0.07 * i), CHAR.lightened(0.07 * sin(i)), false,
			Vector3(0.11 * sin(i), 0.38 + 0.21 * i, 0.10 * cos(i)))
	_round(cart + Vector3(-1.05, 0.32, -0.51), 0.40, 0.12, CHAR, false, Vector3(0, 0, 1.17))
	_round(cart + Vector3(-1.11, 0.36, -0.49), 0.128, 0.13, IRON, false, Vector3(0, 0, 1.17))
	_box(cart + Vector3(1.14, 0.17, 0.62), Vector3(0.14, 0.12, 1.67), CHAR, false, Vector3(0.18, -0.52, 0))
	for i in 13:
		var board := Vector3(-3.55 - absf(sin(i * 13.8)) * 4.9, 0.045, -8.2 - i * 1.67)
		_box(board, Vector3(0.12 + 0.035 * sin(i * 3.2), 0.075, 0.35 + 0.30 * absf(cos(i))),
			CHAR, false, Vector3(0, i * 1.1, 0))

func _lower_library() -> void:
	for z in [-12.95, -8.78, -4.6, -0.45, 8.8]:
		_ledger_shelf(Vector3(-31.24, 0.25, z))
	for z in [5.15, 11.25]:
		_ledger_shelf(Vector3(-13.76, 0.25, z))
	for at in [Vector3(-28.7, 0.25, -9.8), Vector3(-25.8, 0.25, 8.15), Vector3(-19.0, 0.25, 8.15)]:
		_box(at + Vector3.UP * 0.012, Vector3(3.24, 0.019, 4.03), BLUE.darkened(0.38))
		_table(at, Vector2(1.85, 2.65))
		_bench(at + Vector3(1.31, 0, 0), PI / 2.0)
		_box(at + Vector3(-0.27, 0.824, 0.32), Vector3(0.46, 0.027, 0.35), PAPER,
			false, Vector3(0, 0.21, 0))
		_round(at + Vector3(0.36, 0.916, -0.73), 0.096, 0.18, BRASS)
	var catalog := Vector3(-22.75, 0.25, 13.53)
	_table(catalog, Vector2(3.8, 0.92))
	for x in [-1.2, -0.36, 0.26, 0.97]:
		_box(catalog + Vector3(x, 0.85, -0.02), Vector3(0.56, 0.08, 0.53), BLUE.lerp(OAK, absf(x) * 0.6),
			false, Vector3(0, -0.12 * x, 0))
	for light_at in [Vector3(-28.4, 3.42, -11.0), Vector3(-28.4, 3.54, -3.35),
			Vector3(-25.6, 3.5, 8.25), Vector3(-18.85, 3.5, 8.25)]:
		_lantern(light_at, 6.05)


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
		_earthenware(table + Vector3(-0.13, 0.832, -2.68), 1.13, BLUE)
		_earthenware(table + Vector3(0.13, 0.832, 2.78), 0.92, Color(0.52, 0.31, 0.19))
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
		_earthenware(bench + Vector3(-0.34, 0.824, 0.75), 1.04, Color(0.55, 0.30, 0.17))
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
	_kitchen_stair_sign()

func _kitchen_stair_sign() -> void:
	var plaque := Vector3(25.16, 2.16, -5.41)
	_box(plaque, Vector3(0.08, 0.35, 1.25), OAK)
	for offset in [-0.57, 0.57]:
		_box(plaque + Vector3(-0.05, 0, offset), Vector3(0.018, 0.036, 0.036), BRASS)
	var lettering := Label3D.new()
	lettering.position = plaque + Vector3.LEFT * 0.045
	lettering.rotation.y = -PI / 2.0
	lettering.text = "К караульной  →"
	lettering.font_size = 48
	lettering.pixel_size = 0.002
	lettering.outline_size = 0
	lettering.modulate = LINEN.lightened(0.18)
	add_child(lettering)

	var sconce := Vector3(31.38, 2.42, -4.23)
	_box(sconce + Vector3(0.16, 0.03, 0), Vector3(0.10, 0.37, 0.24), IRON)
	_box(sconce + Vector3(0.02, -0.11, 0), Vector3(0.33, 0.055, 0.26), IRON)
	_round(sconce + Vector3(-0.07, 0.03, 0), 0.075, 0.23, Color(0.93, 0.65, 0.31))
	_round(sconce + Vector3(-0.07, 0.16, 0), 0.102, 0.045, IRON)
	_light(sconce + Vector3.LEFT * 0.25, 1.28, 4.65)


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
	for x in [20.24, 21.26, 22.28]:
		_provision_barrel(Vector3(x, -3.55, -9.05), 0.41)
	_table(Vector3(20.96, -3.55, -11.3), Vector2(1.9, 0.9))
	for x in [20.51, 21.24]:
		_round(Vector3(x, -2.66, -11.3), 0.184, 0.13, LINEN)
	_earthenware(Vector3(21.47, -2.73, -11.12), 0.81, BLUE.darkened(0.18))
	_earthenware(Vector3(20.05, -2.73, -11.12), 1.1, Color(0.53, 0.34, 0.21))
	_lantern(Vector3(18.5, -1.45, -12.60), -1.0, 1.35, 6.35)
	_lantern(Vector3(22.45, -1.45, -10.55), -1.0, 1.30, 6.1)
	_lantern(Vector3(16.3, 1.95, -8.20), 6.05, 0.9, 5.35)


func _upper_service_room() -> void:
	_table(Vector3(19.46, 6.35, -7.28), Vector2(2.05, 3.7))
	for z in [-8.05, -6.88]:
		_box(Vector3(19.42, 7.24, z), Vector3(0.62, 0.13, 0.72), LINEN)
	for x in [18.32, 20.26, 22.32]:
		_locker(Vector3(x, 6.35, -13.90))
	_bench(Vector3(23.74, 6.35, -11.1), PI / 2.0)
	_lantern(Vector3(19.69, 9.71, -7.26), 12.0, 1.64, 8.1)
	_lantern(Vector3(27.02, 9.41, -2.31), 12.0, 1.30, 6.5)


func _keep_stair_guards() -> void:
	_stair_guard(Vector3(31.30, 6.35, -13.84), Vector3(31.30, 6.35, -4.85))
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


func _earthenware(at: Vector3, size: float, color: Color) -> void:
	for band: Vector4 in [Vector4(0.04, 0.10, 0.145, 0.080), Vector4(0.154, 0.145, 0.176, 0.15),
			Vector4(0.271, 0.176, 0.072, 0.105), Vector4(0.351, 0.072, 0.063, 0.073)]:
		var jar := CylinderMesh.new()
		jar.bottom_radius = band.y * size
		jar.top_radius = band.z * size
		jar.height = band.w * size
		jar.radial_segments = 10
		jar.rings = 0
		_place(jar, at + Vector3.UP * band.x * size, color.lightened(0.04 * band.x), Vector3.ZERO, null)
	_round(at + Vector3.UP * (0.387 * size), 0.082 * size, 0.035 * size, color.lightened(0.09))
	_round(at + Vector3.UP * (0.407 * size), 0.058 * size, 0.006 * size, CHAR)

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

func _table(at: Vector3, size: Vector2, top_height := 0.81) -> void:
	var leg_height := top_height - 0.12
	_box(at + Vector3.UP * (top_height - 0.06), Vector3(size.x, 0.12, size.y), WOOD_EDGE, true)
	for x in [-1, 1]:
		for z in [-1, 1]:
			_box(at + Vector3(x * (size.x * 0.5 - 0.12), leg_height * 0.5, z * (size.y * 0.5 - 0.13)),
				Vector3(0.13, leg_height, 0.13), OAK, true)

func _gear_rack(at: Vector3) -> void:
	for z in [-1.14, 1.14]:
		_box(at + Vector3(0, 1.12, z), Vector3(0.29, 2.24, 0.15), OAK, true)
	_box(at + Vector3.UP * 1.43, Vector3(0.36, 0.18, 2.47), WOOD_EDGE, true)
	for z in [-0.79, -0.27, 0.27, 0.79]:
		_box(at + Vector3(-0.20, 0.95, z), Vector3(0.082, 1.9, 0.08), OAK)
		_box(at + Vector3(-0.20, 1.98, z), Vector3(0.08, 0.29, 0.18), IRON)
	_round(at + Vector3(-0.24, 1.18, 0.59), 0.35, 0.105, RED, true, Vector3(0, 0, PI / 2))

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

	_practice_yard()
	_wagon_bay()
	_firewood_store()

func _practice_yard() -> void:
	# The targets face west toward the shooting line with a timber backstop to the east.
	var yard := Vector3(11.45, 0, -15.1)
	_box(yard + Vector3.UP * 0.012, Vector3(7.51, 0.021, 6.65), Color(0.25, 0.20, 0.139))
	for z in [-3.36, 3.36]:
		_box(yard + Vector3(0.30, 0.089, z), Vector3(7.15, 0.18, 0.16), LIMESTONE, true)
	for z in [-3.08, 0.07, 3.08]:
		_box(yard + Vector3(3.28, 1.55, z), Vector3(0.20, 3.1, 0.22), OAK, true)
	for i in 9:
		var shade := 0.05 * sin(i * 2.12)
		_box(yard + Vector3(3.37, 0.22 + i * 0.296, 0), Vector3(0.16, 0.288, 6.18),
			OAK.lightened(shade), true)
	for z: float in [-2.26, 0.0, 2.26]:
		var base := yard + Vector3(2.42, 0, z)
		_round(base + Vector3.UP * 0.13, 0.31, 0.25, LIMESTONE, true)
		_box(base + Vector3.UP * 1.01, Vector3(0.16, 1.84, 0.16), OAK, true)
		var tilt := Vector3(0, 0, PI / 2)
		_round(base + Vector3(-0.13, 1.46, 0), 0.53, 0.17, WOOD_EDGE, true, tilt)
		_round(base + Vector3(-0.223, 1.46, 0), 0.475, 0.022, Color(0.59, 0.44, 0.22), false, tilt)
		_round(base + Vector3(-0.238, 1.46, 0), 0.28, 0.013, LINEN, false, tilt)
		_round(base + Vector3(-0.25, 1.46, 0), 0.125, 0.015, RED, false, tilt)
		_box(yard + Vector3(-2.64, 0.035, z), Vector3(0.42, 0.063, 0.56), LIMESTONE)
	_bench(yard + Vector3(-2.74, 0, 3.73), 0.05)

func _wagon_bay() -> void:
	var bay := Vector3(-34.5, 0, -12.4)
	for row in 6:
		for column in 7:
			var at := bay + Vector3(-3.12 + column * 1.02, 0.028, -2.55 + row * 0.92)
			_box(at, Vector3(1.01, 0.056, 0.91), LIMESTONE.darkened(0.12 + 0.09 * sin(column * 1.8 + row)))
	var hitch := bay + Vector3(-2.95, 0, -2.86)
	for x in [0.0, 2.55, 5.10]:
		_box(hitch + Vector3(x, 0.17, 0), Vector3(0.38, 0.34, 0.41), LIMESTONE, true)
		_box(hitch + Vector3(x, 0.68, 0), Vector3(0.16, 1.10, 0.16), OAK, true)
	_box(hitch + Vector3(2.55, 1.03, 0), Vector3(5.48, 0.16, 0.15), WOOD_EDGE, true)
	var trough := bay + Vector3(2.51, 0, 2.41)
	_box(trough + Vector3.UP * 0.25, Vector3(2.02, 0.50, 0.74), LIMESTONE, true)
	_box(trough + Vector3.UP * 0.507, Vector3(1.74, 0.018, 0.52), BLUE.darkened(0.42))
	for z in [-0.33, 0.33]:
		_box(trough + Vector3(0, 0.53, z), Vector3(2.06, 0.15, 0.13), LIMESTONE)

func _firewood_store() -> void:
	var shed := Vector3(38.25, 0, -18.35)
	_box(shed + Vector3.UP * 0.035, Vector3(3.40, 0.071, 5.80), LIMESTONE.darkened(0.13))
	for z in [-2.61, 2.61]:
		for x in [-1.37, 1.37]:
			var height: float = 2.31 + x * 0.24
			_box(shed + Vector3(x, 0.15, z), Vector3(0.38, 0.30, 0.39), LIMESTONE, true)
			_box(shed + Vector3(x, 0.30 + height * 0.5, z), Vector3(0.17, height, 0.19), OAK, true)
	for x in [-1.36, 1.36]:
		_box(shed + Vector3(x, 2.59 + x * 0.24, 0), Vector3(0.20, 0.19, 5.62), OAK)
	for i in 14:
		_box(shed + Vector3(0, 2.70, -2.79 + i * 0.43), Vector3(3.70, 0.13, 0.43),
			WOOD_EDGE.darkened(0.11 + 0.075 * cos(i * 1.74)), false, Vector3(0, 0, 0.236))
	for bay in [-1.27, 1.27]:
		for row in 4:
			for index in 5 - absi(row - 1):
				var at := shed + Vector3(0.55, 0.18 + row * 0.23,
					bay + (index - (4.0 - absi(row - 1)) * 0.5) * 0.46)
				var radius := 0.15 + 0.047 * absf(cos(row * 2.53 + index * 2.35))
				var tilt := Vector3(0.07 * sin(row + index), 0, PI / 2.0)
				_round(at, radius, 1.75 - 0.12 * (index % 3), OAK.darkened(0.08 * (index % 2)), true, tilt)
				_round(at + Vector3(-0.88 + 0.06 * (index % 3), 0, 0), radius * 0.88, 0.024,
					LINEN.darkened(0.18 + 0.055 * (row % 3)), false, tilt)

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
