@tool
extends Node3D

const OAK := Color(0.30, 0.19, 0.115)
const WOOD_EDGE := Color(0.42, 0.28, 0.17)
const BRASS := Color(0.58, 0.40, 0.20)
const RED := Color(0.43, 0.15, 0.13)
const BLUE := Color(0.25, 0.43, 0.60)
const LINEN := Color(0.67, 0.60, 0.46)
const CHAR := Color(0.125, 0.086, 0.061)

@export var size := Vector3(0.78, 3.76, 3.52)
@export var layout_seed := 0

var _timber: Dictionary[Color, StandardMaterial3D]

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 913 + layout_seed
	var row_height := (size.y - 0.36) / 4.0
	var width := size.z - 0.20
	var colors := [RED, BLUE.darkened(0.17), Color(0.24, 0.30, 0.19), LINEN.darkened(0.24), WOOD_EDGE, CHAR]
	var volumes: Array[Transform3D] = []
	var spines: Array[Color] = []
	var fittings: Array[Transform3D] = []
	var gilding: Array[Color] = []
	for end in [-1.0, 1.0]:
		_box(Vector3(0, size.y * 0.5, end * (size.z * 0.5 - 0.059)),
			Vector3(size.x, size.y, 0.114), OAK)
		_box(Vector3(size.x * 0.49, size.y * 0.5, end * (size.z * 0.5 - 0.058)),
			Vector3(0.035, size.y * 0.86, 0.082), WOOD_EDGE)
	_box(Vector3(-size.x * 0.5 + 0.052, size.y * 0.5, 0),
		Vector3(0.099, size.y, width), OAK.darkened(0.23))
	_box(Vector3(0.012, size.y - 0.063, 0), Vector3(size.x + 0.02, 0.12, size.z), WOOD_EDGE)
	for row in 4:
		var tray := 0.19 + row * row_height
		_box(Vector3(0, tray, 0), Vector3(size.x, 0.099, width), WOOD_EDGE)
		var edge_z := -width * 0.5 + 0.06
		while edge_z < width * 0.5 - 0.19:
			var binding := rng.randf_range(0.105, 0.168)
			var height := rng.randf_range(0.29, row_height * 0.83)
			if rng.randf() < 0.28:
				edge_z += binding * rng.randf_range(0.95, 2.6)
				continue
			var cover: Color = colors[rng.randi_range(0, colors.size() - 1)]
			var front := rng.randf_range(0.12, 0.235)
			var center := Vector3(front, tray + 0.050 + height * 0.5, edge_z + binding * 0.5)
			volumes.append(Transform3D(Basis.from_scale(Vector3(0.30, height, binding)), center))
			spines.append(cover)
			if rng.randf() < 0.54:
				var band := center + Vector3(0.153, height * 0.29, 0)
				fittings.append(Transform3D(Basis.from_scale(Vector3(0.008, 0.024, binding * 0.68)), band))
				gilding.append(BRASS)
			edge_z += binding + rng.randf_range(0.009, 0.025)
	_batch_book_parts(volumes, spines)
	_batch_book_parts(fittings, gilding)

func _batch_book_parts(parts: Array[Transform3D], colors: Array[Color]) -> void:
	if parts.is_empty():
		return
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.91
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	box.material = material
	var models := MultiMesh.new()
	models.transform_format = MultiMesh.TRANSFORM_3D
	models.use_colors = true
	models.mesh = box
	models.instance_count = parts.size()
	var bounds := parts[0] * box.get_aabb()
	for i in parts.size():
		models.set_instance_transform(i, parts[i])
		models.set_instance_color(i, colors[i])
		bounds = bounds.merge(parts[i] * box.get_aabb())
	models.custom_aabb = bounds
	var renderer := MultiMeshInstance3D.new()
	renderer.multimesh = models
	add_child(renderer)

func _box(at: Vector3, dimensions: Vector3, color: Color) -> void:
	if not _timber.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.91
		_timber[color] = material
	var box := BoxMesh.new()
	box.size = dimensions
	box.material = _timber[color]
	var model := MeshInstance3D.new()
	model.mesh = box
	model.position = at
	add_child(model)
