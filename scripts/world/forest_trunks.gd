extends Node3D

const CHUNK_SIZE := 24.0
const CHARRED_TREE := preload("res://scenes/world/tree_dead_charred.tscn")

@export var player: Node3D
@export var pines: MultiMeshInstance3D
@export var oaks: MultiMeshInstance3D
@export var burn_pines: MultiMeshInstance3D
@export var burn_oaks: MultiMeshInstance3D
@export var ash_grove: Node3D
@export var hand_planted: Node3D

# Each tile contains transform, unscaled radius, unscaled height and its visual grove.
var _tiles: Dictionary[Vector2i, Array] = {}
var _active: Dictionary[Vector2i, StaticBody3D] = {}
var _center := Vector2i(99999, 99999)
var _burned := false

func _ready() -> void:
	_index_grove(pines, 0.36, 2.4, false)
	_index_grove(oaks, 0.45, 3.2, false)
	_index_grove(burn_pines, 0.36, 2.4, true)
	_index_grove(burn_oaks, 0.45, 3.2, true)
	for living: Node3D in hand_planted.get_children():
		_add_charred_tree(ash_grove.global_transform.affine_inverse() * living.global_transform, living.name)
	_sync(_tile_of(to_local(player.global_position)))

func _physics_process(_delta: float) -> void:
	var tile := _tile_of(to_local(player.global_position))
	if tile != _center:
		_sync(tile)

func set_burned(burned: bool) -> void:
	if _burned == burned:
		return
	_burned = burned
	for tile in _active.keys():
		_remove_tile(tile)
	_sync(_tile_of(to_local(player.global_position)))

func _tile_of(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / CHUNK_SIZE), floori(point.z / CHUNK_SIZE))

func _index_grove(grove: MultiMeshInstance3D, radius: float, height: float, burns: bool) -> void:
	var multimesh := grove.multimesh
	var grove_to_local := global_transform.affine_inverse() * grove.global_transform
	var grove_to_ash := ash_grove.global_transform.affine_inverse() * grove.global_transform
	for index in multimesh.instance_count:
		var instance := multimesh.get_instance_transform(index)
		var placement := grove_to_local * instance
		var point := placement.origin
		var tile := _tile_of(point)
		if not _tiles.has(tile):
			_tiles[tile] = []
		var dimensions := placement.basis.get_scale()
		_tiles[tile].append([point, radius * dimensions.x, height * dimensions.y, burns])
		if burns:
			_add_charred_tree(grove_to_ash * instance)

func _add_charred_tree(placement: Transform3D, tree_name: StringName = &"") -> void:
	var burned_tree := CHARRED_TREE.instantiate() as Node3D
	if not tree_name.is_empty():
		burned_tree.name = tree_name
	burned_tree.transform = placement
	ash_grove.add_child(burned_tree)

func _sync(tile: Vector2i) -> void:
	_center = tile
	for key in _active.keys():
		if absi(key.x - tile.x) > 1 or absi(key.y - tile.y) > 1:
			_remove_tile(key)
	for x in range(tile.x - 1, tile.x + 2):
		for z in range(tile.y - 1, tile.y + 2):
			var key := Vector2i(x, z)
			if _tiles.has(key) and not _active.has(key):
				_add_tile(key)

func _add_tile(key: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.name = "Grove_%d_%d" % [key.x, key.y]
	body.collision_mask = 0
	for tree: Array in _tiles[key]:
		if tree[3] and _burned:
			continue
		var stem := CylinderShape3D.new()
		stem.radius = tree[1]
		stem.height = tree[2]
		var collider := CollisionShape3D.new()
		collider.shape = stem
		collider.position = tree[0] + Vector3.UP * stem.height * 0.5
		body.add_child(collider)
	add_child(body)
	_active[key] = body

func _remove_tile(key: Vector2i) -> void:
	var body := _active[key]
	body.collision_layer = 0
	body.queue_free()
	_active.erase(key)
