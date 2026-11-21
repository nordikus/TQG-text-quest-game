@tool
extends StaticBody3D

const WALK_HEIGHT := 14.8
const SILL := WALK_HEIGHT - 0.06
const EAVES := 19.0
const SIDES := 16
const SECTOR := TAU / SIDES
const INSIDE := 2.76
const OUTSIDE := 3.32

@export var stone: Material
@export var trim: Material
@export var roof: Material
@export var corner := false

func _ready() -> void:
	var eaves := EAVES + (2.3 if corner else 0.0)
	var doorways := [8, 12] if corner else [0, 8]
	var arrow_slits := [0, 4] if corner else [4, 12]
	var foundation_base := PackedVector3Array()
	var foundation_top := PackedVector3Array()
	for i in SIDES:
		var radial := _radial(i * SECTOR - SECTOR * 0.5)
		foundation_base.append(radial * 3.52)
		foundation_top.append(radial * OUTSIDE + Vector3.UP * SILL)
	_prism(foundation_base, foundation_top)

	for i in SIDES:
		var start := (i - 0.5) * SECTOR
		var finish := start + SECTOR
		if i in doorways:
			_sector(start, finish, WALK_HEIGHT + 2.77, eaves)
		elif (i + 1) % SIDES in doorways or posmod(i - 1, SIDES) in doorways:
			_sector(start, finish, WALK_HEIGHT + 2.42, eaves)
		elif i in arrow_slits:
			_arrow_slit(start, finish, eaves)
		else:
			_sector(start, finish, SILL, eaves)

	_cylinder("Cornice", 3.45, 3.39, 0.28, eaves - 0.05, trim)
	_cylinder("SlateRoof", 0.08, 3.59, 3.52, eaves + 0.09, roof)
	_watch_station()

func _watch_station() -> void:
	var oak := StandardMaterial3D.new()
	oak.albedo_color = Color(0.27, 0.18, 0.105)
	oak.roughness = 0.91
	_board(Vector3(2.09, 15.14, 0.16), Vector3(0.53, 0.14, 1.82), oak)
	for z in [-0.51, 0.83]:
		_board(Vector3(2.09, 14.945, z), Vector3(0.43, 0.36, 0.14), oak)
	_board(Vector3(2.263, 16.0, 0.32), Vector3(0.58, 0.138, 1.06), oak)
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.55, 0.32, 0.13)
	bronze.metallic = 0.57
	bronze.roughness = 0.76
	var lantern := StandardMaterial3D.new()
	lantern.albedo_color = Color(0.96, 0.67, 0.31)
	lantern.emission_enabled = true
	lantern.emission = Color(1.0, 0.54, 0.14)
	lantern.emission_energy_multiplier = 0.53
	_board(Vector3(2.07, 16.22, 0.34), Vector3(0.15, 0.27, 0.16), lantern)
	for y in [16.076, 16.362]:
		_board(Vector3(2.07, y, 0.34), Vector3(0.21, 0.044, 0.21), bronze)
	_board(Vector3(2.07, 16.38, 0.34), Vector3(0.09, 0.03, 0.024), bronze)
	var light := OmniLight3D.new()
	light.position = Vector3(1.89, 16.24, 0.34)
	light.light_color = Color(0.99, 0.72, 0.40)
	light.light_energy = 0.72
	light.omni_range = 4.2
	add_child(light)

func _board(at: Vector3, size: Vector3, material: Material) -> void:
	var plank := BoxMesh.new()
	plank.size = size
	plank.material = material
	_visual(plank).position = at

func _arrow_slit(start: float, finish: float, eaves: float) -> void:
	const WINDOW_BOTTOM := 16.47
	const WINDOW_TOP := 17.78
	var left_jamb := lerpf(start, finish, 0.39)
	var right_jamb := lerpf(start, finish, 0.61)
	_sector(start, finish, SILL, WINDOW_BOTTOM)
	_sector(start, left_jamb, WINDOW_BOTTOM, WINDOW_TOP)
	_sector(right_jamb, finish, WINDOW_BOTTOM, WINDOW_TOP)
	_sector(start, finish, WINDOW_TOP, eaves)

func _sector(start: float, finish: float, bottom: float, top: float) -> void:
	var left := _radial(start)
	var right := _radial(finish)
	var base := PackedVector3Array([
		left * OUTSIDE, right * OUTSIDE, right * INSIDE, left * INSIDE,
	])
	var low := PackedVector3Array()
	var high := PackedVector3Array()
	for point in base:
		low.append(point + Vector3.UP * bottom)
		high.append(point + Vector3.UP * top)
	_prism(low, high)

func _prism(low: PackedVector3Array, high: PackedVector3Array) -> void:
	var side_count := low.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in side_count:
		var next := (i + 1) % side_count
		_triangle(surface, low[i], low[next], high[next])
		_triangle(surface, low[i], high[next], high[i])
	for i in range(1, side_count - 1):
		_triangle(surface, low[0], low[i + 1], low[i])
		_triangle(surface, high[0], high[i], high[i + 1])
	surface.generate_normals()
	surface.set_material(stone)
	_visual(surface.commit())

	var shape := ConvexPolygonShape3D.new()
	shape.points = low + high
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)

func _radial(angle: float) -> Vector3:
	return Vector3(sin(angle), 0, cos(angle))

func _cylinder(part_name: String, top_radius: float, bottom_radius: float, height: float,
		bottom: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = SIDES
	mesh.rings = 0
	mesh.material = material
	var instance := _visual(mesh)
	instance.name = part_name
	instance.position.y = bottom + height * 0.5

func _visual(mesh: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	add_child(instance)
	return instance
