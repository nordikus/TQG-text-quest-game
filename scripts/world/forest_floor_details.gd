@tool
extends Node3D

const Layout := preload("res://scripts/world/forest_layout.gd")
const FERN := Color(0.12, 0.23, 0.045)
const GRASS := Color(0.095, 0.17, 0.034)
const LITTER := Color(0.18, 0.123, 0.045)
const CHAR := Color(0.055, 0.042, 0.032)

@export var living_strip: Node3D
@export var burned_strip: Node3D

func _ready() -> void:
	if not living_strip or not burned_strip:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1978
	var grove := FastNoiseLite.new()
	grove.seed = 228
	grove.frequency = 0.128
	var grasses: Array[Vector3] = []
	var ferns: Array[Vector3] = []
	var ash_grasses: Array[Vector3] = []
	var ash_ferns: Array[Vector3] = []
	var litter: Array[Vector3] = []
	var scorch: Array[Vector3] = []
	for x in range(-51, 52, 2):
		for z in range(-75, 28, 2):
			var point := Vector2(x + rng.randf_range(-0.94, 0.94), z + rng.randf_range(-0.94, 0.94))
			if point.length() < 4.9 or (absf(point.x) < 1.7 and point.y > 0 and point.y < 12.0):
				continue
			var life_distance := Layout.distance_to_path(point, Layout.LIFE_PATH)
			var ash_distance := Layout.distance_to_path(point, Layout.ASH_PATH)
			if life_distance < 2.05 or point.distance_to(Layout.TREE_BASE) < 2.5:
				continue
			var burned_here := ash_distance < 12.2 and point.y < -2.0
			var at := Vector3(point.x, 0.016, point.y)
			var patch := grove.get_noise_2dv(point)
			if burned_here and ash_distance > 2.0 and rng.randf() < 0.75:
				scorch.append(at)
			if patch < -0.09 or rng.randf() < 0.20:
				if not burned_here and rng.randf() < 0.41:
					litter.append(at)
				continue
			for i in rng.randi_range(2, 5):
				var tuft := at + Vector3(rng.randf_range(-0.65, 0.65), 0, rng.randf_range(-0.65, 0.65))
				if burned_here:
					ash_grasses.append(tuft)
				else:
					grasses.append(tuft)
			if patch > 0.16 and rng.randf() < 0.59:
				if burned_here:
					ash_ferns.append(at)
				else:
					ferns.append(at)

	var grass := _plant(false)
	var fern := _plant(true)
	_batch("MeadowTufts", self, grass, grasses, rng)
	_batch("FernColonies", self, fern, ferns, rng)
	_batch("LeafLitter", self, _debris(LITTER, false), litter, rng)
	_batch("FlammableGrass", living_strip, grass, ash_grasses, rng)
	_batch("FlammableFerns", living_strip, fern, ash_ferns, rng)
	_batch("CharcoalAndBark", burned_strip, _debris(CHAR, true), scorch, rng)

func _plant(fern: bool) -> ArrayMesh:
	var surface := _surface()
	for i in (6 if fern else 9):
		var angle := TAU * i * 0.382
		var along := Vector3(sin(angle), 0, cos(angle))
		var width := along.cross(Vector3.UP)
		var height := (0.26 if fern else 0.22) + 0.089 * sin(i * 2.37)
		var spread := (0.38 if fern else 0.21) + 0.09 * cos(i * 3.4)
		var center := along * 0.065
		var bend := along * spread * 0.53 + Vector3.UP * height
		var tip := along * spread + Vector3.UP * (height * (0.77 if fern else 1.19))
		var color := (FERN if fern else GRASS).lerp(Color(0.26, 0.30, 0.051), (sin(i * 3.2) + 1.0) * 0.18)
		_leaf(surface, center, bend, tip, width * (0.042 if fern else 0.025), color)
		if fern:
			for j in [0.35, 0.58, 0.79]:
				var stem := center.lerp(bend, j)
				var reach: float = spread * (0.36 - j * 0.21)
				for side: float in [-1.0, 1.0]:
					var branch := stem + side * width * reach
					_leaf(surface, stem, branch + along * 0.047, branch + along * 0.084,
						along * 0.026, color.lightened(0.027))
	return _finish(surface)

func _debris(color: Color, burned: bool) -> ArrayMesh:
	var surface := _surface()
	for i in 9:
		var angle := i * 2.39
		var along := Vector3(sin(angle), 0, cos(angle))
		var at := along * (0.10 + 0.026 * i)
		at.y = 0.005 + (0.04 if burned and i % 3 == 2 else 0.0)
		var tip := at + along * (0.13 if burned else 0.095) + Vector3.UP * (0.11 if burned and i % 3 == 2 else 0.017)
		var bend := at.lerp(tip, 0.50) + Vector3.UP * 0.014
		_leaf(surface, at, bend, tip, along.cross(Vector3.UP) * (0.041 if burned else 0.022),
			color.lightened(0.026 + 0.026 * sin(i * 1.72)))
	return _finish(surface)

func _leaf(surface: SurfaceTool, from: Vector3, bend: Vector3, tip: Vector3, width: Vector3, color: Color) -> void:
	_face(surface, [from, bend - width, tip], color)
	_face(surface, [from, tip, bend + width], color.darkened(0.12))

func _face(surface: SurfaceTool, points: Array, color: Color) -> void:
	surface.set_color(color)
	for point in points:
		surface.add_vertex(point)

func _surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface

func _finish(surface: SurfaceTool) -> ArrayMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	surface.set_material(material)
	surface.generate_normals()
	return surface.commit()

func _batch(batch_name: String, parent_node: Node3D, mesh: Mesh, points: Array[Vector3], rng: RandomNumberGenerator) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = points.size()
	for i in points.size():
		var size := rng.randf_range(0.70, 1.38)
		var rotation := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * size)
		batch.set_instance_transform(i, Transform3D(rotation, points[i]))
		var light := rng.randf_range(0.73, 1.0)
		batch.set_instance_color(i, Color(light, 1.0, light))
	var renderer := MultiMeshInstance3D.new()
	renderer.name = batch_name
	renderer.multimesh = batch
	renderer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent_node.add_child.call_deferred(renderer)
