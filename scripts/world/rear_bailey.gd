@tool
extends Node3D

const FruitTree := preload("res://scenes/world/tree_deciduous_lowpoly.tscn")
const Cargo := preload("res://scripts/world/courtyard_cargo.gd")
const OAK := Color(0.31, 0.19, 0.11)
const CUT_WOOD := Color(0.46, 0.31, 0.17)
const STONE := Color(0.415, 0.424, 0.374)
const IRON := Color(0.17, 0.18, 0.17)
const SOIL := Color(0.21, 0.145, 0.087)
const CANVAS := Color(0.55, 0.47, 0.33)

var _materials: Dictionary[Color, StandardMaterial3D]

func _ready() -> void:
	_keep_elevations()
	_stoneyard()
	_orchard()
	_cistern()
	for point in [Vector3(-35.4, 0.34, -47.0), Vector3(34.9, 0.34, -48.0),
			Vector3(-31.9, 0.34, -84.82), Vector3(32.7, 0.34, -84.82),
			Vector3(-6.5, 0.34, -84.72), Vector3(6.5, 0.34, -84.72)]:
		_lantern(point)

func _keep_elevations() -> void:
	var dressed := STONE.lightened(0.13)
	for height in [0.42, 6.18, 12.35]:
		_box("DressedStoneCourse", Vector3(0, height, -75.56), Vector3(64.78, 0.19, 0.25), dressed)
		for x in [-32.46, 32.46]:
			_box("DressedStoneCourse", Vector3(x, height, -61.08), Vector3(0.25, 0.19, 29.08), dressed)
	for x in [-28.3, -12.0, 12.0, 28.3]:
		_box("KeepButtressFoot", Vector3(x, 0.33, -75.95), Vector3(1.33, 0.66, 0.95), STONE, true)
		_box("KeepButtress", Vector3(x, 3.51, -75.83), Vector3(0.94, 6.58, 0.70), STONE, true)
		_box("KeepButtressCap", Vector3(x, 6.86, -75.80), Vector3(1.16, 0.27, 0.79), dressed)
		_box("UpperKeepButtress", Vector3(x, 9.83, -75.68), Vector3(0.69, 5.72, 0.42), STONE)
		_box("KeepButtressCap", Vector3(x, 12.71, -75.70), Vector3(0.87, 0.21, 0.50), dressed)
	for x in [-22.9, -17.2, -6.8, 6.8, 17.2, 22.9]:
		_shutter(Vector3(x, 8.58, -75.54), PI, dressed)
	for x in [-24.8, -8.6, 0.0, 8.6, 24.8]:
		_shutter(Vector3(x, 14.68, -75.54), PI, dressed)
	for z in [-69.35, -63.15, -56.95]:
		_shutter(Vector3(32.43, 8.58, z), PI / 2.0, dressed)
		_shutter(Vector3(-32.43, 8.58, z - 0.51), -PI / 2.0, dressed)

func _shutter(at: Vector3, yaw: float, dressed: Color) -> void:
	var opening := Transform3D(Basis(Vector3.UP, yaw), at)
	var facing := Vector3(0, yaw, 0)
	_box("WindowShadow", opening * Vector3(0, 0, 0.021), Vector3(0.92, 2.02, 0.073), IRON.darkened(0.28),
		false, facing)
	for x in [-0.53, 0.53]:
		_box("WindowJamb", opening * Vector3(x, 0, 0.106), Vector3(0.18, 1.94, 0.25), dressed, false, facing)
	_box("WindowLintel", opening * Vector3(0, 1.009, 0.125), Vector3(1.24, 0.27, 0.28), dressed, false, facing)
	_box("WindowSill", opening * Vector3(0, -1.025, 0.156), Vector3(1.28, 0.17, 0.34), dressed, false, facing)
	for i in 4:
		var x := -0.317 + 0.21 * i
		_box("ShutterBoard", opening * Vector3(x, -0.035, 0.075), Vector3(0.193, 1.80, 0.07),
			OAK.lightened(0.05 * sin(i * 1.8)), false, facing)
	for height in [-0.56, 0.53]:
		_box("ShutterStrap", opening * Vector3(0, height, 0.12), Vector3(0.85, 0.087, 0.052), IRON, false, facing)

func _stoneyard() -> void:
	var center := Vector3(-24.1, 0, -86.80)
	_box("WorkingSurface", center + Vector3.UP * 0.012, Vector3(13.7, 0.022, 3.72), STONE.darkened(0.37))
	for x in [-5.65, 4.72]:
		for z in [-1.34, 1.22]:
			var height: float = 2.85 - 0.30 * z
			_box("PostFoot", center + Vector3(x, 0.16, z), Vector3(0.43, 0.32, 0.43), STONE, true)
			_box("ShedPost", center + Vector3(x, height * 0.5 + 0.23, z), Vector3(0.22, height, 0.22), OAK, true)
			var brace_start := center + Vector3(x, height - 0.65, z)
			var brace_end := center + Vector3(x * 0.83, height + 0.09, z)
			_beam(brace_start, brace_end, 0.15, CUT_WOOD)
	for z in [-1.34, 1.22]:
		_box("Purlin", center + Vector3(-0.47, 3.08 - z * 0.30, z), Vector3(10.78, 0.16, 0.18), OAK)
	for i in 15:
		var panel := center + Vector3(-5.74 + i * 0.756, 3.22, 0)
		_box("RoofPlank", panel, Vector3(0.755, 0.14, 3.42), OAK.lightened(0.10 + 0.07 * sin(i * 1.8)),
			false, Vector3(0.291, 0, 0))
	_box_collider(center + Vector3(-0.448, 3.22, 0), Vector3(11.339, 0.14, 3.42), Vector3(0.291, 0, 0))
	_box("WorkBench", center + Vector3(-3.37, 0.89, -0.61), Vector3(2.67, 0.14, 0.86), CUT_WOOD, true)
	for x in [-4.49, -2.25]:
		for z in [-0.95, -0.30]:
			_box("BenchLeg", center + Vector3(x, 0.40, z), Vector3(0.15, 0.81, 0.15), OAK, true)
	_box("StoneBlank", center + Vector3(-3.77, 1.05, -0.62), Vector3(0.74, 0.19, 0.48), STONE,
		false, Vector3(0, 0.14, 0))
	_box("MalletHead", center + Vector3(-2.87, 1.04, -0.85), Vector3(0.21, 0.16, 0.12), IRON)
	_box("MalletHandle", center + Vector3(-2.86, 0.985, -0.65), Vector3(0.063, 0.06, 0.42), OAK)
	for row in 3:
		for i in (4 - row):
			_box("CutStone", center + Vector3(1.53 + i * 0.78 + row * 0.23, 0.21 + row * 0.42, -0.54),
				Vector3(0.74, 0.42, 0.88), STONE.lightened(0.05 * sin(i * 3.1 + row)), true)
	_box("Canvas", center + Vector3(2.65, 0.906, -0.54), Vector3(2.40, 0.065, 1.06), CANVAS, false,
		Vector3(0, -0.08, 0))
	var crates := Node3D.new()
	crates.name = "MasonsCargo"
	crates.position = center + Vector3(-5.0, 0, 0.32)
	crates.set_script(Cargo)
	add_child(crates)
	_cart(center + Vector3(-0.19, 0, 1.06))

func _cart(at: Vector3) -> void:
	_box("CartTray", at + Vector3.UP * 0.48, Vector3(1.2, 0.13, 1.06), CUT_WOOD, true)
	for x in [-0.57, 0.57]:
		_box("CartSide", at + Vector3(x, 0.68, -0.09), Vector3(0.082, 0.31, 1.04), OAK, true)
		_box("CartHandle", at + Vector3(x * 0.80, 0.36, 0.66), Vector3(0.082, 0.088, 1.51), CUT_WOOD, true)
		_cylinder("WheelHub", at + Vector3(x * 1.26, 0.36, -0.04), 0.11, 0.11, 0.17, IRON,
			Vector3(0, 0, PI * 0.5))
		var rim := TorusMesh.new()
		rim.inner_radius = 0.326
		rim.outer_radius = 0.391
		rim.rings = 12
		rim.ring_segments = 5
		rim.material = _material(OAK)
		var axle := at + Vector3(x * 1.26, 0.39, -0.04)
		_visual("WheelRim", rim, axle, Vector3(0, 0, PI * 0.5))
		var wheel := CylinderShape3D.new()
		wheel.radius = 0.39
		wheel.height = 0.13
		_collider(wheel, axle, Vector3(0, 0, PI * 0.5))
		for angle in [0.0, PI / 3.0, TAU / 3.0]:
			_box("Spoke", axle, Vector3(0.057, 0.68, 0.046), CUT_WOOD, false, Vector3(angle, 0, 0))

func _orchard() -> void:
	for position_x in [12.8, 18.2, 23.6, 29.0]:
		var tree := FruitTree.instantiate() as Node3D
		tree.name = "OrchardTree"
		tree.position = Vector3(position_x, 0, -86.96)
		tree.rotation.y = position_x * 0.67
		tree.scale = Vector3.ONE * (0.64 + 0.08 * sin(position_x))
		add_child(tree)
		for i in 6:
			var angle := TAU * i / 6.0 + tree.rotation.y
			var point := tree.position + Vector3(cos(angle) * 0.98, 2.03 + i * 0.065, sin(angle) * 0.82)
			var fruit := SphereMesh.new()
			fruit.radius = 0.084
			fruit.height = 0.17
			fruit.radial_segments = 7
			fruit.rings = 3
			fruit.material = _material(Color(0.54, 0.20, 0.11).lightened(i * 0.034))
			_visual("OrchardFruit", fruit, point)
	for x in [14.32, 20.0, 25.68, 31.36]:
		_herb_bed(Vector3(x, 0, -78.55))
	for x in [12.0, 30.6]:
		_box("OrchardBench", Vector3(x, 0.49, -85.94), Vector3(1.72, 0.13, 0.43), CUT_WOOD, true)
		for end: float in [-0.58, 0.58]:
			_box("BenchFoot", Vector3(x + end, 0.21, -85.94), Vector3(0.25, 0.42, 0.40), STONE, true)

func _herb_bed(at: Vector3) -> void:
	_box("HerbSoil", at + Vector3.UP * 0.13, Vector3(4.23, 0.25, 2.39), SOIL, true)
	for z in [-1.20, 1.20]:
		_box("RaisedBedEdge", at + Vector3(0, 0.21, z), Vector3(4.42, 0.38, 0.16), OAK, true)
	for x in [-2.18, 2.18]:
		_box("RaisedBedEdge", at + Vector3(x, 0.21, 0), Vector3(0.15, 0.38, 2.34), OAK, true)
	for i in 21:
		var row := i % 3
		var x := -1.85 + floorf(i / 3.0) * 0.61 + 0.10 * sin(i * 2.99)
		var herb := at + Vector3(x, 0.26, -0.76 + 0.74 * row)
		var color := Color(0.26, 0.43, 0.16).lerp(Color(0.331, 0.41, 0.22), row / 3.0)
		for tilt: float in [-0.24, 0.24]:
			_cylinder("HerbLeaves", herb + Vector3(tilt * 0.29, 0.138, 0), 0.015, 0.087, 0.28, color,
				Vector3(0.22 * sin(i), 0, tilt))

func _cistern() -> void:
	var at := Vector3(0, 0, -87.21)
	const SIDES := 14
	var water := CylinderMesh.new()
	water.height = 0.035
	water.top_radius = 1.32
	water.bottom_radius = 1.32
	water.radial_segments = SIDES
	water.rings = 0
	var blue := _material(Color(0.105, 0.245, 0.27)).duplicate() as StandardMaterial3D
	blue.roughness = 0.29
	blue.metallic = 0.27
	water.material = blue
	_visual("CisternWater", water, at + Vector3.UP * 0.35)
	for i in SIDES:
		var angle := TAU * i / SIDES
		var radial := Vector3(sin(angle), 0, cos(angle))
		var rotation := Vector3(0, angle, 0)
		_box("CisternMasonry", at + radial * 1.555 + Vector3.UP * 0.34, Vector3(0.706, 0.68, 0.40),
			STONE.darkened(0.07 + 0.08 * sin(i * 2.1)), true, rotation)
		_box("CisternCap", at + radial * 1.555 + Vector3.UP * 0.708, Vector3(0.692, 0.13, 0.46),
			STONE.lightened(0.12), true, rotation)
	_box("GutterPost", at + Vector3(0, 0.84, -1.50), Vector3(0.45, 1.63, 0.46), STONE, true)
	_box("GutterHead", at + Vector3(0, 1.61, -1.15), Vector3(0.39, 0.22, 0.98), STONE, true,
		Vector3(0.08, 0, 0))
	for x in [-0.166, 0.166]:
		_box("GutterEdge", at + Vector3(x, 1.745, -1.16), Vector3(0.075, 0.145, 0.98), STONE)

func _lantern(at: Vector3) -> void:
	_box("LanternBase", at - Vector3.UP * 0.20, Vector3(0.39, 0.28, 0.39), STONE, true)
	_box("LanternPost", at + Vector3.UP * 0.64, Vector3(0.14, 1.62, 0.14), OAK, true)
	_box("LanternFoot", at + Vector3.UP * 1.48, Vector3(0.28, 0.11, 0.28), IRON)
	_box("LanternCap", at + Vector3.UP * 1.84, Vector3(0.31, 0.15, 0.31), IRON)
	for x in [-0.11, 0.11]:
		for z in [-0.11, 0.11]:
			_box("LanternFrame", at + Vector3(x, 1.67, z), Vector3(0.036, 0.31, 0.036), IRON)
	var glow := BoxMesh.new()
	glow.size = Vector3(0.17, 0.24, 0.17)
	var glass := _material(Color(0.93, 0.64, 0.27)).duplicate() as StandardMaterial3D
	glass.emission_enabled = true
	glass.emission = glass.albedo_color
	glass.emission_energy_multiplier = 1.1
	glow.material = glass
	_visual("LanternGlass", glow, at + Vector3.UP * 1.67)
	var light := OmniLight3D.new()
	light.position = at + Vector3.UP * 1.68
	light.light_color = Color(1.0, 0.73, 0.43)
	light.light_energy = 0.78
	light.omni_range = 5.8
	add_child(light)

func _beam(from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var direction := to - from
	var rotation := Basis(Quaternion(Vector3.UP, direction.normalized())).get_euler()
	_box("CornerBrace", from.lerp(to, 0.5), Vector3(width, direction.length(), width), color, false, rotation)

func _cylinder(part: String, at: Vector3, top: float, bottom: float, height: float, color: Color,
		rotation := Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 9
	mesh.rings = 0
	mesh.material = _material(color)
	_visual(part, mesh, at, rotation)

func _box(part: String, at: Vector3, size: Vector3, color: Color, solid := false, rotation := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	var model := _visual(part, mesh, at, rotation)
	if solid:
		_box_collider(Vector3.ZERO, size, Vector3.ZERO, model)

func _box_collider(at: Vector3, size: Vector3, rotation: Vector3, holder: Node3D = null) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_collider(shape, at, rotation, holder)

func _collider(shape: Shape3D, at: Vector3, rotation: Vector3, holder: Node3D = null) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation = rotation
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	(holder if holder else self).add_child(body)

func _visual(part: String, mesh: Mesh, at: Vector3, rotation := Vector3.ZERO) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	model.name = part
	model.mesh = mesh
	model.position = at
	model.rotation = rotation
	add_child(model, true)
	return model

func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.93
		_materials[color] = material
	return _materials[color]
