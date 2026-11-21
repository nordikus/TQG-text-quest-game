extends Node

const ForestLayout := preload("res://scripts/world/forest_layout.gd")

var _passed := true
var _level: Node3D
var _world: Node
var _gate: CourtyardGate
var _seal: ArcaneBarrier
var _shard: PickupItem
var _captain_seal: PickupItem
var _chest: Interactable
var _keep: InteractableDoor
var _service_door: InteractableDoor
var _barrel: Interactable
var _book: BookPedestal
var _barracks: InteractableDoor
var _observer: Interactable

func _ready() -> void:
	_verify.call_deferred()

func _verify() -> void:
	_level = load("res://scenes/forest_clearing.tscn").instantiate()
	add_child(_level)
	_world = _level.get_node("WorldChanger")
	_gate = _world.outer_gate
	_seal = _world.bridge_seal
	_shard = _world.shard
	_captain_seal = _world.keep_key
	_chest = _world.rune_chest
	_keep = _world.keep_door
	_service_door = _world.service_room_door
	_barrel = _world.rune_barrel
	_book = _level.find_child("PedestalWithBook", true, false)
	_barracks = _level.find_child("BarracksDoor", true, false)
	_observer = _level.get_node("CastleFacade/MainKeep/Observer")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not _observer.visible and _observer.get_node("Shape").disabled and _observer.get_interaction_prompt().is_empty(),
		"The Observer is absent until a qualifying choice.")
	_check_sanctuaries()
	if OS.get_cmdline_user_args().has("reject-deal"):
		await _choose_throne_ending(1)
		_check(QuestManager.get_quest_ending("deal_at_the_throne") == "reject_deal"
			and _observer.visible and not _observer.get_node("Shape").disabled
			and not InventoryManager.has_item("great_quill") and InventoryManager.quill_uses_count == 0,
			"Refusing the Quill brings the Observer to the throne room.")
		await _verify_observer_epilogue("Ты меня удивил.")
		get_tree().quit(0 if _passed else 1)
		return
	_check_initial()
	_check_rooms()
	_check_watchtower_passages()
	await _verify_chapel_door()

	var ash_first := OS.get_cmdline_user_args().has("ash-first")
	if ash_first:
		await _verify_ash(false)
	else:
		await _verify_life()
	await _take_quill_and_rewrite()
	await _verify_observer_epilogue("Но сможешь ли ты остановиться?")

	if ash_first:
		await _verify_life()
		_check(InventoryManager.has_item("throne_hall_key"), "Seal survives Ash → Life.")
		await _rewrite()
		await _verify_ash(true)
	else:
		await _verify_ash(true)
		_check(InventoryManager.has_item(ArcaneBarrier.SHARD_ID), "Shard survives Life → Ash.")

	await _rewrite()
	_check_initial()
	_check(not _shard.visible and not _captain_seal.visible,
		"Carried quest items do not respawn as duplicates.")
	_check(InventoryManager.notes.has("captains_sealed_report"), "The chest report survives rewriting.")
	_check(InventoryManager.notes.count("waterkeeper_note") == 1 and InventoryManager.notes.count("upper_guard_ledger") == 1,
		"The service-room and cellar notes survive rewriting without duplicates.")
	get_tree().quit(0 if _passed else 1)

func _check_initial() -> void:
	_check(not _world.nature_trail.visible and not _world.burning_path.visible,
		"Neither trail exists before the decision.")
	_check(_world.life_thicket.visible and _world.ash_thicket.visible and not _world.great_tree.visible,
		"Both areas return to ordinary woodland and the Great Tree retracts.")
	_check(_gate_blocks(), "Physical outer gate is closed.")
	_check(_service_door.is_locked and not _service_door.is_open and _service_doorway().get("collider") == _service_door.left_wing
		and _barrel.get_node("Seal").visible and is_zero_approx(_barrel.get_node("Lid").rotation.x),
		"The service room and the rune barrel relock after a rewrite.")
	_check(_front_panel_is_closed(),
		"The front masonry is intact before the choice and after a rewrite.")
	_check_courtyard_branch(false)
	_check(_world.intact_bridge.visible and not _world.collapsed_bridge.visible and not _world.courtyard_roots.visible,
		"The castle returns to its initial geometry.")
	_check(_world.intact_bridge.get_node("Shoring").is_visible_in_tree() and not _remnant_smoke().emitting,
		"The wooden shoring and shed are restored while the castle embers go out.")
	_check_courtyard_fire(false)
	_check_burned_placements(false)

func _verify_life() -> void:
	QuestManager.complete_quest("burning_grove", "extinguish_fire")
	await get_tree().create_timer(3.75).timeout
	_check(_gate_blocks() and _world.great_tree.visible and _world.nature_trail.visible and not _world.burning_path.visible,
		"Life grows its approach while the courtyard gate stays closed.")
	_check(_world.courtyard_roots.visible and _world.castle_life.visible and not _world.castle_ash.visible,
		"Life exposes roots and lights the upper wing.")
	_check_courtyard_fire(false)
	_check(_world.living_arches.get_child(3).position.y >= -0.02, "The last living arch rose.")
	_check(_crossing_is_open() and _world.wall_breach.is_visible_in_tree(),
		"The Great Tree breaks the crest and joins the perimeter walk.")
	_check_courtyard_branch(true)
	if not InventoryManager.has_item("great_quill"):
		_check(_book.get_interaction_prompt().is_empty(), "The completed grove book stays quiet without the Quill.")
	await _verify_life_blockers()
	_check(_bridge_is_intact(), "The Life bridge carries a walkable deck across the span.")
	var corridor: Node3D = _world.intact_bridge.get_parent()
	var library_lintel := _level.find_child("BridgeLintel", true, false) as Node3D
	_check(is_zero_approx(corridor.global_rotation.y)
		and is_equal_approx(corridor.global_position.x, library_lintel.global_position.x),
		"The straight bridge and library portal share an axis.")
	var bridge_wall := corridor.get_node("IntactBridgeSpan/CentralBridgeWest/Mesh") as MeshInstance3D
	var western_wall := _level.get_node("CastleFacade/CourtyardWalls/WesternRamparts/WallWest")
	var curtain := western_wall.get_child(0) as MeshInstance3D
	var bridge_edge := (bridge_wall.global_transform * bridge_wall.get_aabb()).position.x
	var curtain_edge := (curtain.global_transform * curtain.get_aabb()).end.x
	_check(bridge_edge - curtain_edge > 2.1, "The roofed bridge clears the western curtain by over two metres.")
	var continuous := true
	for step in range(1, 43):
		var point := corridor.to_global(Vector3(0, 6.8, -step * 0.5))
		continuous = continuous and not _ray(point, point - Vector3.UP).is_empty()
	_check(continuous, "The straight span joins the tower and library end to end.")
	_check(_world.intact_bridge.get_node("Shoring").is_visible_in_tree() and not _remnant_smoke().emitting,
		"The damaged span keeps its timber supports in Life.")
	_check(_tower_has_solid_base(), "The tower has a solid wall in place of the lower door.")
	_check(_seal.visible and not _seal.get_node("Col").disabled, "The bridge initially needs the shard.")
	_seal.interact()
	_check(_seal.visible and not _seal.get_node("Col").disabled, "The bridge seal refuses bare hands.")
	_shard.interact()
	_seal.interact()
	await get_tree().create_timer(0.6).timeout
	_check(InventoryManager.has_item(ArcaneBarrier.SHARD_ID) and not _seal.visible and _seal.get_node("Col").disabled,
		"The shard removes the bridge seal and stays in inventory.")
	if not InventoryManager.has_item("throne_hall_key"):
		_service_door.interact()
		_check(_service_door.is_locked and not _service_door.is_open,
			"The shard cannot open the service room's guard lock.")
	await _verify_barrel(true)

func _verify_ash(has_shard: bool) -> void:
	QuestManager.complete_quest("burning_grove", "pass_by")
	await get_tree().create_timer(3.45).timeout
	_check(_gate.is_raised and not _gate_blocks() and _world.burning_path.visible and not _world.great_tree.visible,
		"Ash raises the courtyard gate and exposes the burnt approach.")
	_check(_world.castle_ash.visible and not _world.castle_life.visible and not _world.court_lanterns.visible,
		"The courtyard changes in Ash.")
	_check_courtyard_fire(true)
	var all_fires_active := true
	for fire: Node3D in _world.fire_particles_group.get_children():
		var smoke := fire.get_node("Smoke") as CPUParticles3D
		var flame := fire.get_node("Flame") as MeshInstance3D
		all_fires_active = all_fires_active and smoke.emitting and flame.is_visible_in_tree()
	_check(all_fires_active and not _world.corridor_forest.visible,
		"Active fire and charred trees replace the living grove.")
	_check_burned_placements(true)
	_check(not _bridge_is_intact() and _world.collapsed_bridge.visible and not _seal.visible,
		"The ruined bridge has a real gap rather than a magical lock.")
	_check(_world.collapsed_bridge.get_node("BurnedShoring").is_visible_in_tree()
		and not _world.intact_bridge.get_node("Shoring").is_visible_in_tree() and _remnant_smoke().emitting,
		"The bridge ruins expose burned shoring, a burned shed and smoldering debris.")
	_check(_tower_has_solid_base(), "Direct entry into the tower from the courtyard is unavailable.")
	_check(_front_panel_is_closed(), "Ash keeps the front masonry intact.")
	_check_courtyard_branch(false)
	_barracks.interact()
	await get_tree().create_timer(0.8).timeout
	var ash_entry := _ray(Vector3(14.0, 1.6, -112.6), Vector3(17.4, 1.6, -112.6))
	_check(ash_entry.is_empty(), "The barracks doorway is clear when opened in Ash.")
	_barracks.restore_door()
	_captain_seal.interact()
	_keep.interact()
	_service_door.interact()
	await get_tree().create_timer(0.82).timeout
	_check(InventoryManager.has_item("throne_hall_key") and _keep.is_open and absf(_keep.left_wing.rotation.y) > 1.0,
		"The reusable captain's seal opens the physical keep doors.")
	_check(InventoryManager.has_item("throne_hall_key") and _service_door.is_open and _service_doorway().is_empty(),
		"The captain's seal opens the swinging door above the kitchen.")
	var ledger := _level.find_child("UpperGuardLedger", true, false) as PickupItem
	if ledger:
		ledger.interact()
	_check(InventoryManager.notes.count("upper_guard_ledger") == 1, "The guard ledger can be taken once.")
	_chest.interact()
	_check(InventoryManager.notes.has("captains_sealed_report") == has_shard,
		"The barracks chest gives its report only to the carried crystal shard.")
	await _verify_barrel(has_shard)

func _service_doorway() -> Dictionary:
	return _ray(Vector3(21.75, 7.85, -153.8), Vector3(21.75, 7.85, -156.4))

func _verify_barrel(has_shard: bool) -> void:
	_barrel.interact()
	if not has_shard:
		_check(_barrel.get_node("Seal").visible and is_zero_approx(_barrel.get_node("Lid").rotation.x)
			and not InventoryManager.notes.has("waterkeeper_note"), "The captain's seal cannot open the rune barrel.")
		return
	await get_tree().create_timer(0.62).timeout
	_check(not _barrel.get_node("Seal").visible and _barrel.get_node("Lid").rotation.x < -1.0
		and InventoryManager.notes.count("waterkeeper_note") == 1 and InventoryManager.has_item(ArcaneBarrier.SHARD_ID),
		"The shard unseals the barrel and leaves one waterkeeper note in the journal.")

func _take_quill_and_rewrite() -> void:
	await _choose_throne_ending(0)
	var quill := _level.find_child("GreatQuillPickup", true, false) as PickupItem
	quill.interact()
	_check(InventoryManager.has_item("great_quill"), "The throne quest gives the Great Quill.")
	_check(not _observer.visible, "Accepting and taking the Quill do not summon the Observer.")
	_check(_book.get_interaction_prompt() == _book.rewrite_prompt, "The Quill restores the grove book prompt.")
	await _rewrite()

func _choose_throne_ending(choice: int) -> void:
	var pedestal := _level.get_node("CastleFacade/MainKeep/ThroneBookPedestal") as ThronePedestal
	pedestal.interact()
	var choices: VBoxContainer = GameManager.quest_panel.choices_container
	(choices.get_child(choice) as Button).pressed.emit()
	await get_tree().process_frame
	(choices.get_child(0) as Button).pressed.emit()
	await get_tree().process_frame

func _verify_observer_epilogue(expected_line: String) -> void:
	_check_sanctuaries()
	var player := _level.get_node("Player") as CharacterBody3D
	var camera := player.get_node("Camera3D") as Camera3D
	var ray := camera.get_node("InteractionRay") as RayCast3D
	var position_before := player.global_transform
	var camera_before := camera.transform
	player.global_position = _observer.to_global(Vector3(0, 0.02, 2.65))
	player.velocity = Vector3.ZERO
	camera.look_at(_observer.global_position + Vector3.UP * 1.58)
	for frame in 4:
		await get_tree().physics_frame
	_check(ray.current_target == _observer, "The normal interaction ray targets the Observer.")

	var interact := InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	Input.parse_input_event(interact)
	Input.flush_buffered_events()
	var release := interact.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)

	var epilogue: CanvasLayer = GameManager.observer_epilogue
	var choices := epilogue.get_node("%Choices") as HBoxContainer
	var line := epilogue.get_node("%Dialogue") as Label
	_check(epilogue.visible and GameManager.ui_open and not choices.is_visible_in_tree()
		and get_viewport().get_camera_3d() == epilogue.get_node("CinematicCamera"),
		"Interaction starts the cinematic before opening the ending choices.")
	await get_tree().create_timer(4.2).timeout
	_check(line.text.ends_with(expected_line) and is_equal_approx(line.visible_ratio, 1.0)
		and choices.is_visible_in_tree(), "The Observer delivers the matching line before the choice.")

	var uses := InventoryManager.quill_uses_count
	(choices.get_node("Walk") as Button).pressed.emit()
	await get_tree().create_timer(0.55).timeout
	_check(not GameManager.ui_open and not epilogue.visible and get_viewport().get_camera_3d() == camera
		and InventoryManager.quill_uses_count == uses, "Walking restores the player camera and preserves the run.")
	player.global_transform = position_before
	camera.transform = camera_before

func _verify_life_blockers() -> void:
	_barracks.interact()
	await get_tree().create_timer(0.8).timeout
	var roots_span_door := true
	for height in [0.5, 1.45, 2.4, 3.35]:
		for z in [-113.67, -112.6, -111.53]:
			var hit := _ray(Vector3(14.0, height, z), Vector3(17.4, height, z))
			var body: Node = hit.get("collider")
			roots_span_door = roots_span_door and body != null and _world.courtyard_roots.is_ancestor_of(body)
	_barracks.restore_door()
	_check(roots_span_door, "Life roots fill the barracks frame even if its door is open.")

func _remnant_smoke() -> CPUParticles3D:
	return _world.castle_ash.get_node("RemnantFires/Embers5/Smoke")

func _check_burned_placements(burned: bool) -> void:
	var green_floor := _world.corridor_forest.get_node("FlammableGrass") as MultiMeshInstance3D
	var burned_floor := _world.charred_forest_zone.get_node("CharcoalAndBark") as MultiMeshInstance3D
	_check(green_floor.is_visible_in_tree() == not burned and burned_floor.is_visible_in_tree() == burned,
		"The forest floor swaps green undergrowth and charcoal with the fire state.")
	var clear := true
	var variants_match := true
	for living: Node3D in _world.corridor_forest.get_node("HandPlanted").get_children():
		var charred: Node3D = _world.charred_forest_zone.get_node_or_null(NodePath(living.name))
		var ground := Vector2(living.global_position.x, living.global_position.z)
		clear = clear and ForestLayout.distance_to_path(ground, ForestLayout.ASH_PATH) > ForestLayout.ASH_CORE
		variants_match = (variants_match and charred != null
			and living.is_visible_in_tree() != burned and charred.is_visible_in_tree() == burned
			and living.global_transform.is_equal_approx(charred.global_transform))
	_check(variants_match, "Hand-planted trees exchange living and charred variants at the same positions.")
	for rock_name in ["Rock_MidEast", "BorderRock4", "BorderRock6"]:
		var rock := _level.find_child(rock_name, true, false) as Node3D
		var ground := Vector2(rock.global_position.x, rock.global_position.z)
		clear = clear and ForestLayout.distance_to_path(ground, ForestLayout.ASH_PATH) - rock.scale.x > ForestLayout.ASH_CORE
	_check(clear, "Rocks and tree trunks clear the central lane of the fire route.")

func _check_rooms() -> void:
	var castle := _level.get_node("CastleFacade")
	var well: StaticBody3D = castle.get_node("CourtyardWell")
	var post := _ray(well.global_position + Vector3(-0.94, 0.83, 0.5),
		well.global_position + Vector3(-0.94, 0.83, -0.5))
	var roof := _ray(well.global_position + Vector3.UP * 2.9, well.global_position + Vector3.UP * 0.78)
	_check(post.get("collider") == well and roof.get("collider") == well and roof.position.y > 2.7,
		"The courtyard well has physical posts and a roof.")
	var quarters := castle.get_node("BarracksBuilding/GuardQuartersAndArmory")
	var beds := 0
	for child in quarters.get_children():
		if child is StaticBody3D and child.name.begins_with("GuardBed"):
			beds += 1
	var entry := _ray(Vector3(20.08, 1.75, -112), Vector3(20.08, 1.75, -108.9))
	var partition := _ray(Vector3(24.8, 1.75, -112), Vector3(24.8, 1.75, -108.9))
	_check(beds == 6 and entry.is_empty() and partition.get("collider") == castle.get_node("BarracksBuilding/DormitoryWallEast"),
		"The six-bed guard dormitory has a separate walkable doorway.")
	var rack := _ray(Vector3(29.25, 1.68, -116.25), Vector3(30.8, 1.68, -116.25))
	var rack_post := _ray(Vector3(13.8, 1.43, -106.99), Vector3(14.6, 1.43, -106.99))
	_check(not rack.is_empty() and (rack.get("collider") as Node).get_parent() == quarters
		and not rack_post.is_empty() and (rack_post.get("collider") as Node).get_parent().name == "ArchitecturalDetails",
		"The barracks racks block the player where their rails and posts are visible.")
	var target := _ray(Vector3(12.88, 1.46, -105.1), Vector3(14.00, 1.46, -105.1))
	_check(not target.is_empty() and (target.get("collider") as Node).get_parent().name == "WellGardenAndPracticeYard",
		"The training targets face the yard and have physical faces.")
	var hall := castle.get_node("MainKeep/Architecture")
	var pillars_are_solid := true
	for side in [1, 2]:
		for index in [1, 2, 3]:
			var pillar := hall.get_node("HallPillar%d_%d" % [side, index]) as StaticBody3D
			var center := pillar.global_position
			center.y = 1.45
			var outside := center + Vector3.RIGHT * (0.92 if side == 1 else -0.92)
			pillars_are_solid = pillars_are_solid and _ray(outside, center).get("collider") == pillar
	_check(pillars_are_solid, "All six throne hall columns have solid shafts.")
	_check(_ray(Vector3(18.1, 7.8, -150.6), Vector3(18.1, 7.8, -145.7)).is_empty(),
		"The gallery above the kitchen opens directly into the steward's room.")
	var bedroom := castle.get_node("MageTower/AstromancerWorkshop/AstromancerBed") as StaticBody3D
	_check(bedroom != null and not (bedroom.get_child(0) as CollisionShape3D).disabled,
		"The astromancer has a bed with collision beside the workshop.")

func _verify_chapel_door() -> void:
	var chapel := _level.get_node("CastleFacade/ChapelBuilding") as Node3D
	var door := chapel.get_node("ChapelDoor") as InteractableDoor
	var left := door.left_wing
	var right := door.right_wing
	var outside_left := chapel.to_global(Vector3(9.4, 1.6, -0.52))
	var outside_right := chapel.to_global(Vector3(9.4, 1.6, 0.52))
	var inside_left := chapel.to_global(Vector3(4.8, 1.6, -0.52))
	var inside_right := chapel.to_global(Vector3(4.8, 1.6, 0.52))
	_check(_ray(outside_left, inside_left).get("collider") == left
		and _ray(inside_right, outside_right).get("collider") == right,
		"Both closed chapel leaves sit in the doorway and can be targeted from either side.")
	door.interact()
	await get_tree().create_timer(0.78).timeout
	var left_tip := chapel.to_local(left.to_global(Vector3(1.3, 0, 0)))
	var right_tip := chapel.to_local(right.to_global(Vector3(-1.3, 0, 0)))
	_check(door.is_open and left_tip.x > 8.25 and right_tip.x > 8.25
		and _ray(outside_left, inside_left).is_empty() and _ray(inside_right, outside_right).is_empty(),
		"Both leaves swing into the yard and clear the chapel aisle.")
	door.interact()
	await get_tree().create_timer(0.78).timeout
	_check(not door.is_open and _ray(outside_left, inside_left).get("collider") == left
		and _ray(inside_right, outside_right).get("collider") == right,
		"The chapel leaves close back into the door frame.")
	var note := chapel.get_node("ChapelNote") as PickupItem
	_check(note.visible, "The chapel prayer remains available at the altar.")

func _check_sanctuaries() -> void:
	var chapel := _level.get_node("CastleFacade/ChapelBuilding") as Node3D
	var observer_model := (_observer.get_node("Model") as MeshInstance3D).mesh
	var model_found := false
	for sanctuary: Node3D in [chapel, _level.get_node("StoneAltar")]:
		for part: MeshInstance3D in sanctuary.find_children("*", "MeshInstance3D", true, false):
			model_found = model_found or part.mesh == observer_model
	var behind_altar := _ray(chapel.to_global(Vector3(-4.5, 0.9, -1.3)),
		chapel.to_global(Vector3(-4.5, 0.9, 1.3)))
	_check(not model_found and behind_altar.is_empty(),
		"Neither sanctuary contains an Observer model and the former statue site is clear.")

func _check_watchtower_passages() -> void:
	var walls := _level.get_node("CastleFacade/CourtyardWalls")
	for tower_name in ["GateWestWatchtower", "GateEastWatchtower", "WestWatchtower", "EastWatchtower",
			"RearWestWatchtower", "RearEastWatchtower"]:
		var tower := walls.get_node(tower_name) as StaticBody3D
		var clear := true
		for x in [-0.46, 0.0, 0.46]:
			for y in [15.05, 15.8, 16.9]:
				clear = clear and _ray(tower.to_global(Vector3(x, y, -4.1)),
					tower.to_global(Vector3(x, y, 4.1))).is_empty()
		for z in range(-4, 5):
			var floor_sample := tower.to_global(Vector3(0, 15.1, z))
			clear = clear and not _ray(floor_sample, floor_sample - Vector3.UP * 0.5).is_empty()
		var outer_wall := _ray(tower.to_global(Vector3(0, 16.1, 0)), tower.to_global(Vector3(4, 16.1, 0)))
		_check(clear and outer_wall.get("collider") == tower, "%s has a continuous passage and physical walls." % tower_name)
	for tower_name in ["CornerTowerSE", "CornerTowerSW", "CornerTowerNE", "CornerTowerNW"]:
		var corner := walls.get_node(tower_name) as StaticBody3D
		var turn := corner.to_global(Vector3(0, 16.9, 0))
		var first_entry := corner.to_global(Vector3(-4.1, 16.9, 0))
		var second_entry := corner.to_global(Vector3(0, 16.9, -4.1))
		_check(_ray(first_entry, turn).is_empty() and _ray(second_entry, turn).is_empty()
			and not _ray(turn + Vector3.DOWN * 1.85, turn + Vector3.DOWN * 2.2).is_empty(),
			"%s connects two curtain walks through a playable corner." % tower_name)

	var forest := _level.get_node("ForestPines") as MultiMeshInstance3D
	var groves := [forest, _level.get_node("ForestOaks"), _world.corridor_forest.get_node("CorridorPines"),
		_world.corridor_forest.get_node("CorridorOaks")]
	var trees_clear := true
	for grove: MultiMeshInstance3D in groves:
		for i in grove.multimesh.instance_count:
			var at := grove.to_global(grove.multimesh.get_instance_transform(i).origin)
			trees_clear = trees_clear and not ForestLayout.CASTLE_TREE_CLEARANCE.has_point(Vector2(at.x, at.z))
	_check(trees_clear, "Forest trees stay outside the expanded curtain and the service yard.")

func _check_courtyard_fire(burned: bool) -> void:
	var surfaces_match: bool = _world.courtyard_surfaces.size() == 3
	for surface: MeshInstance3D in _world.courtyard_surfaces:
		var material := surface.get_active_material(0) as ShaderMaterial
		surfaces_match = surfaces_match and material != null and material.get_shader_parameter("courtyard_burned") == burned
	var ruined_cargo: Node3D = _world.castle_ash.get_node("GateCargo")
	var intact_cargo: Node3D = _world.castle_verge.get_node("GateCargo")
	_check(surfaces_match and ruined_cargo.is_visible_in_tree() == burned
		and intact_cargo.is_visible_in_tree() != burned,
		"The gate paving, courtyard ground and cargo respond to the same fire state.")
	var ruined_shelter: Node3D = _world.castle_ash.get_node("SupplyShelter")
	var intact_shelter: Node3D = _world.castle_verge.get_node("SupplyShelter")
	var shelter_smoke: CPUParticles3D = _world.castle_ash.get_node("RemnantFires/SupplyShelterEmbers/Smoke")
	_check(ruined_shelter.is_visible_in_tree() == burned
		and intact_shelter.is_visible_in_tree() != burned and shelter_smoke.emitting == burned,
		"The supply shelter burns in Ash and is restored when the fire state resets.")
	var soot_is_mounted := true
	for mark_name in ["WestStairSoot1", "WestStairSoot2", "WestCurtainSoot3", "WestCurtainSoot4"]:
		var mark := _world.castle_ash.get_node(mark_name) as Node3D
		var wall: Node = _ray(mark.global_position, mark.global_position + Vector3.LEFT * 0.06).get("collider")
		soot_is_mounted = soot_is_mounted and wall != null and wall.name in ["CourtyardWallStair", "WallWest"]
	_check(soot_is_mounted, "Soot sits against the current west wall and staircase masonry.")

func _rewrite() -> void:
	var times: int = InventoryManager.quill_uses_count
	var confirmation: CenterContainer = GameManager.quest_panel.rewrite_panel
	_book.interact()
	_check(confirmation.is_visible_in_tree() and GameManager.ui_open
		and QuestManager.is_quest_completed("burning_grove") and InventoryManager.quill_uses_count == times,
		"The book requests confirmation before rewriting.")
	var buttons: HBoxContainer = GameManager.quest_panel.rewrite_buttons
	if times == 0:
		(buttons.get_node("Cancel") as Button).pressed.emit()
		_check(not confirmation.is_visible_in_tree() and not GameManager.ui_open
			and QuestManager.is_quest_completed("burning_grove") and InventoryManager.quill_uses_count == 0
			and InventoryManager.has_item("great_quill") and not _observer.visible,
			"Cancelling leaves the world, Quill and Observer unchanged.")
		_book.interact()
		var escape := InputEventAction.new()
		escape.action = "ui_cancel"
		escape.pressed = true
		Input.parse_input_event(escape)
		await get_tree().process_frame
		_check(not confirmation.is_visible_in_tree() and not GameManager.ui_open
			and InventoryManager.quill_uses_count == 0, "Escape also dismisses the confirmation.")
		escape.pressed = false
		Input.parse_input_event(escape)
		_book.interact()
	(buttons.get_node("Confirm") as Button).pressed.emit()
	await get_tree().create_timer(2.15).timeout
	_check(not confirmation.is_visible_in_tree() and GameManager.quest_panel.panel_container.is_visible_in_tree()
		and not QuestManager.is_quest_completed("burning_grove") and InventoryManager.quill_uses_count == times + 1,
		"Confirming rewrites once and reopens the grove choices.")
	_check(_observer.visible and not _observer.get_node("Shape").disabled,
		"Rewriting history brings the Observer to the throne room.")
	GameManager.quest_panel.close_quest()

func _gate_blocks() -> bool:
	var center := Vector3(_gate.global_position.x, 1.3, _gate.global_position.z)
	return _ray(center + Vector3.BACK * 3.0, center + Vector3.FORWARD * 3.0).get("collider") == _gate

func _bridge_is_intact() -> bool:
	var center: Vector3 = _world.intact_bridge.get_node("CentralBridgeDeck").global_position
	return not _ray(center + Vector3.UP * 0.65, center - Vector3.UP * 0.35).is_empty()

func _tower_has_solid_base() -> bool:
	var hit := _ray(Vector3(-23, 1.3, -104), Vector3(-23, 1.3, -107))
	return not hit.is_empty() and hit.collider.name == "TowerWallSouthBase"

func _front_panel_is_closed() -> bool:
	var hit := _ray(Vector3(-23, 13.12, -79.0), Vector3(-23, 13.12, -80.9))
	var merlon := _ray(Vector3(-23, 15.3, -79.0), Vector3(-23, 15.3, -81.1))
	return hit.get("collider") == _world.wall_infill and merlon.get("collider") == _world.wall_infill.get_node("Parapet")

func _crossing_is_open() -> bool:
	var approach := _ray(Vector3(-23, 16.3, -78.0), Vector3(-23, 16.3, -83.65))
	var wall_walk := _ray(Vector3(-25.7, 16.3, -81.5), Vector3(-20.3, 16.3, -81.5))
	var footing := _ray(Vector3(-23, 16.3, -81.5), Vector3(-23, 14.8, -81.5))
	return approach.is_empty() and wall_walk.is_empty() and footing.get("collider") == _world.great_tree.get_node("TrunkBody")

func _check_courtyard_branch(grown: bool) -> void:
	var tower_face := _ray(Vector3(-23, 14.55, -104.8), Vector3(-23, 14.55, -106.1))
	if grown:
		var footing := _ray(Vector3(-23, 15.18, -94.2), Vector3(-23, 13.0, -94.2))
		var trunk: Node = footing.get("collider")
		_check(tower_face.is_empty() and _world.tower_breach.is_visible_in_tree()
			and trunk != null and _world.great_tree.is_ancestor_of(trunk),
			"The growing branch spans the courtyard and breaks the tower's stonework.")
	else:
		var span := _ray(Vector3(-23, 17.8, -94.2), Vector3(-23, 10.8, -94.2))
		_check(span.is_empty() and tower_face.get("collider") == _world.tower_infill,
			"The courtyard has no span and the tower wall is sealed.")

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return _level.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to, 1))

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		_passed = false
