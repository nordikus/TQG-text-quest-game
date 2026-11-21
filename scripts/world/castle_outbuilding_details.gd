@tool
extends Node3D

@export_enum("Chapel", "Barracks") var building := 0

var stone := _material(Color(0.43, 0.42, 0.37))
var edge := _material(Color(0.59, 0.55, 0.46))
var slate := _material(Color(0.16, 0.27, 0.32))
var oak := _material(Color(0.30, 0.18, 0.11))
var iron := _material(Color(0.14, 0.16, 0.16), 0.6)
var bronze := _material(Color(0.52, 0.34, 0.16), 0.55)

func _ready() -> void:
	if building == 0:
		_chapel()
	else:
		_barracks()

func _chapel() -> void:
	_chapel_side_walls()
	for x in [-4.9, -1.62, 1.68, 4.95]:
		_box(Vector3(x, 6.89, 0), Vector3(0.31, 0.32, 13.0), oak)
		for z in [-6.24, 6.24]:
			_box(Vector3(x, 6.46, z), Vector3(0.43, 0.58, 0.36), stone)
	var center := Vector3(5.85, 0, 0)
	_box(center + Vector3.UP * 9.60, Vector3(2.85, 4.65, 2.85), stone)
	_box(center + Vector3.UP * 11.85, Vector3(3.03, 0.29, 3.03), edge)
	for x in [-1.16, 1.16]:
		for z in [-1.16, 1.16]:
			_box(center + Vector3(x, 13.08, z), Vector3(0.46, 2.46, 0.46), stone)
			_box(center + Vector3(x, 14.21, z), Vector3(0.61, 0.23, 0.61), edge)
	_box(center + Vector3.UP * 14.42, Vector3(3.15, 0.29, 3.15), edge)
	_cylinder(center + Vector3.UP * 15.29, 0.0, 2.38, 1.64, 4, slate, PI / 4.0)
	_cylinder(center + Vector3.UP * 13.00, 0.34, 0.61, 0.88, 12, bronze)
	_cylinder(center + Vector3.UP * 12.52, 0.61, 0.61, 0.12, 12, bronze)
	_box(center + Vector3.UP * 13.53, Vector3(2.7, 0.14, 0.18), oak)
	_box(center + Vector3.UP * 16.34, Vector3(0.085, 0.59, 0.085), bronze)
	_polygon(PackedVector3Array([
		Vector3(7.412, 7.14, -7.17), Vector3(7.412, 11.53, 0), Vector3(7.412, 7.14, 7.17),
	]), stone)
	_polygon(PackedVector3Array([
		Vector3(7.43, 7.65, -0.43), Vector3(7.43, 8.93, -0.43), Vector3(7.43, 8.93, 0.43),
		Vector3(7.43, 7.65, -0.43), Vector3(7.43, 8.93, 0.43), Vector3(7.43, 7.65, 0.43),
		Vector3(7.43, 8.93, -0.43), Vector3(7.43, 9.64, 0), Vector3(7.43, 8.93, 0.43),
	]), _glass(Color(0.35, 0.52, 0.72)))
	_box(Vector3(7.46, 8.36, 0), Vector3(0.09, 1.5, 0.073), iron)
	_box(Vector3(7.46, 8.41, 0), Vector3(0.09, 0.075, 0.89), iron)
	_rosette(Vector3(7.035, 5.86, 0), 0.94)
	_rosette(Vector3(-6.382, 4.62, 0), 1.02)
	for z in [-3.48, 3.48]:
		_box(Vector3(7.16, 2.98, z), Vector3(0.52, 5.95, 0.46), stone)
		_box(Vector3(7.23, 5.78, z), Vector3(0.68, 0.22, 0.64), edge)
		_box(Vector3(7.24, 0.32, z), Vector3(0.71, 0.64, 0.65), edge)

func _chapel_side_walls() -> void:
	var arch := PackedVector2Array([
		Vector2(-0.72, -1.18), Vector2(0.72, -1.18), Vector2(0.72, 0.82),
		Vector2(0.59, 1.24), Vector2(0.31, 1.58), Vector2(0, 1.82),
		Vector2(-0.31, 1.58), Vector2(-0.59, 1.24), Vector2(-0.72, 0.82),
	])
	var blocks := ShaderMaterial.new()
	blocks.shader = preload("res://scenes/world/castle/masonry.gdshader")
	var glass := [
		_glass(Color(0.18, 0.40, 0.56)), _glass(Color(0.31, 0.61, 0.67)),
		_glass(Color(0.60, 0.36, 0.17)), _glass(Color(0.43, 0.25, 0.47)),
	]
	for z: float in [-6.7, 6.7]:
		var wall := CSGBox3D.new()
		wall.name = "NorthWindowWall" if z < 0 else "SouthWindowWall"
		wall.size = Vector3(14, 7.0, 0.6)
		wall.position = Vector3(0, 3.72, z)
		wall.material = blocks
		wall.use_collision = true
		for x: float in [-3.65, 0.0, 3.65]:
			var opening := CSGPolygon3D.new()
			opening.operation = CSGShape3D.OPERATION_SUBTRACTION
			opening.polygon = arch
			opening.depth = 0.92
			opening.position = Vector3(x, 0, 0.46)
			opening.material = blocks
			wall.add_child(opening)
			_chapel_window(Vector3(x, 3.72, z), arch, glass)
		add_child(wall)

func _chapel_window(at: Vector3, arch: PackedVector2Array, glass: Array) -> void:
	var lead := PackedVector3Array()
	var panes: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	var center := Vector3(0, 0.21, 0)
	var glass_shape := PackedVector3Array()
	for i in arch.size():
		var j := (i + 1) % arch.size()
		var a := Vector3(arch[i].x, arch[i].y, 0.0)
		var b := Vector3(arch[j].x, arch[j].y, 0.0)
		glass_shape.append(a + Vector3.FORWARD * 0.044)
		glass_shape.append(a + Vector3.BACK * 0.044)
		var mid := (a + b) * 0.5
		panes[i % panes.size()].append_array(PackedVector3Array([at + center, at + a, at + mid]))
		panes[(i + 1) % panes.size()].append_array(PackedVector3Array([at + center, at + mid, at + b]))
		var offset := Vector3(a.y - center.y, center.x - a.x, 0).normalized() * 0.017
		for point in [center - offset, a - offset, a + offset, center - offset, a + offset, center + offset]:
			lead.append(at + point + Vector3.FORWARD * 0.006)
			lead.append(at + point + Vector3.BACK * 0.006)
		var angle := atan2((b - a).y, (b - a).x)
		for face: float in [-1.0, 1.0]:
			_box(at + mid + Vector3.BACK * (0.309 * face), Vector3(a.distance_to(b) + 0.088, 0.18, 0.142),
				edge, Vector3(0, 0, angle))
	for i in panes.size():
		_polygon(panes[i], glass[i])
	var backing := StaticBody3D.new()
	backing.position = at
	var shape := ConvexPolygonShape3D.new()
	shape.points = glass_shape
	var collision := CollisionShape3D.new()
	collision.shape = shape
	backing.add_child(collision)
	add_child(backing)
	# Two planes keep the lead against the glass when viewed from either aisle or courtyard.
	for side in [0, 1]:
		var outline := PackedVector3Array()
		for i in range(side, lead.size(), 2):
			outline.append(lead[i])
		_polygon(outline, iron)
	_box(at + Vector3(0, -1.26, 0), Vector3(1.72, 0.17, 0.91), edge)

func _rosette(center: Vector3, radius: float) -> void:
	_disc(center, radius * 1.15, edge)
	_disc(center + Vector3.RIGHT * 0.012, radius * 1.01, iron)
	var glass := [
		_glass(Color(0.21, 0.61, 0.71)), _glass(Color(0.56, 0.26, 0.49)),
		_glass(Color(0.86, 0.51, 0.20)), _glass(Color(0.28, 0.47, 0.74)),
	]
	var face := center + Vector3.RIGHT * 0.025
	for i in 8:
		var theta := TAU * i / 8.0
		var vertices := PackedVector3Array([face,
			face + Vector3(0, cos(theta + 0.033), sin(theta + 0.033)) * radius,
			face + Vector3(0, cos(theta + PI / 4.0 - 0.033), sin(theta + PI / 4.0 - 0.033)) * radius])
		_polygon(vertices, glass[i % 4])
	_disc(face + Vector3.RIGHT * 0.018, radius * 0.22, bronze)

func _disc(center: Vector3, radius: float, material: Material) -> void:
	var points := PackedVector3Array()
	for i in 24:
		var a := TAU * i / 24
		var b := TAU * (i + 1) / 24
		points.append(center)
		points.append(center + Vector3(0, cos(a), sin(a)) * radius)
		points.append(center + Vector3(0, cos(b), sin(b)) * radius)
	_polygon(points, material)

func _barracks() -> void:
	var trim := _material(Color(0.39, 0.25, 0.15))
	for z in [-8.5, -4.3, 4.3, 8.5]:
		var surround := Vector3(-8.035, 3.92, z)
		_box(surround, Vector3(0.21, 1.81, 1.56), iron)
		for side in [-1.0, 1.0]:
			_box(surround + Vector3(-0.13, 0, side * 0.40), Vector3(0.14, 1.53, 0.64), oak)
			for y in [-0.46, 0.46]:
				_box(surround + Vector3(-0.218, y, side * 0.40), Vector3(0.06, 0.12, 0.65), trim)
		_box(surround + Vector3(-0.10, -0.95, 0), Vector3(0.39, 0.18, 1.74), edge)
	for z in [-9.96, -6.4, 6.4, 9.96]:
		_box(Vector3(-8.09, 2.88, z), Vector3(0.23, 5.42, 0.23), trim)
	_box(Vector3(-8.12, 5.54, 0), Vector3(0.26, 0.28, 21.5), oak)
	for z in [-6.22, 6.22]:
		_box(Vector3(-8.16, 0.30, z), Vector3(0.31, 0.47, 9.25), stone)
	# A training rack sits on the side bay, clear of the entrance and armory route.
	var center := Vector3(-9.0, 0, 7.15)
	for z in [-1.54, 1.54]:
		_box(center + Vector3(-0.85, 1.66, z), Vector3(0.20, 3.32, 0.20), oak, Vector3.ZERO, true)
	_box(center + Vector3(-0.16, 3.77, 0), Vector3(2.09, 0.17, 3.76), trim, Vector3(0, 0, 0.24), true)
	_box(center + Vector3(0.27, 1.36, 0), Vector3(0.24, 0.19, 2.70), oak, Vector3.ZERO, true)
	for z in [-0.91, 0.02, 0.9]:
		_box(center + Vector3(0.36, 1.13, z), Vector3(0.08, 2.26, 0.08), trim, Vector3(0.14, 0, 0.08))
		_box(center + Vector3(0.28, 2.35, z + 0.16), Vector3(0.09, 0.37, 0.18), iron,
			Vector3(0.14, 0, 0.08))
	_shield(Vector3(-8.36, 4.67, 0), 0.73)
	_shield(Vector3(-8.93, 1.52, 6.59), 0.47)

func _shield(center: Vector3, size: float) -> void:
	var border := PackedVector3Array([
		center + Vector3(0, size, -size * 0.71), center + Vector3(0, size, size * 0.71),
		center + Vector3(0, -size * 0.18, size * 0.59), center + Vector3(0, -size * 0.92, 0),
		center + Vector3(0, -size * 0.18, -size * 0.59),
	])
	var painted := _material(Color(0.36, 0.11, 0.10))
	var vertices := PackedVector3Array()
	for i in border.size():
		vertices.append(center + Vector3.LEFT * 0.09)
		vertices.append(border[i])
		vertices.append(border[(i + 1) % border.size()])
	_polygon(vertices, painted)
	_box(center + Vector3(-0.092, 0.10, 0), Vector3(0.045, size * 0.85, size * 0.19), bronze)
	_box(center + Vector3(-0.096, 0.15, 0), Vector3(0.045, size * 0.17, size * 0.81), bronze)

func _box(at: Vector3, size: Vector3, material: Material, tilt := Vector3.ZERO, solid := false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	_add(mesh, at, tilt)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		body.rotation = tilt
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

func _cylinder(at: Vector3, top: float, bottom: float, height: float, sides: int, material: Material, yaw := 0.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 0
	mesh.material = material
	_add(mesh, at, Vector3(0, yaw, 0))

func _polygon(points: PackedVector3Array, material: StandardMaterial3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points:
		surface.add_vertex(point)
	surface.generate_normals()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	_add(surface.commit(), Vector3.ZERO, Vector3.ZERO)

func _add(mesh: Mesh, at: Vector3, tilt: Vector3) -> void:
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.position = at
	model.rotation = tilt
	add_child(model)

func _glass(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.48
	return material

func _material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.88
	return material
