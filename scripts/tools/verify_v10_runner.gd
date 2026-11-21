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
var _book: BookPedestal
var _barracks: InteractableDoor

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
	_book = _level.find_child("PedestalWithBook", true, false)
	_barracks = _level.find_child("BarracksDoor", true, false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check_initial()
	_check_rooms()

	var ash_first := OS.get_cmdline_user_args().has("ash-first")
	if ash_first:
		await _verify_ash(false)
	else:
		await _verify_life()
	await _take_quill_and_rewrite()

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
	get_tree().quit(0 if _passed else 1)

func _check_initial() -> void:
	_check(not _world.nature_trail.visible and not _world.burning_path.visible,
		"Neither trail exists before the decision.")
	_check(_world.life_thicket.visible and _world.ash_thicket.visible and not _world.great_tree.visible,
		"Both areas return to ordinary woodland and the Great Tree retracts.")
	_check(_gate_blocks(), "Physical outer gate is closed.")
	_check(_front_panel_is_closed(),
		"The front masonry is intact before the choice and after a rewrite.")
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
		"The Great Tree breaks the front masonry and opens the crossing to the observatory.")
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

func _verify_ash(has_shard: bool) -> void:
	QuestManager.complete_quest("burning_grove", "pass_by")
	await get_tree().create_timer(3.45).timeout
	_check(_gate.is_raised and not _gate_blocks() and _world.burning_path.visible and not _world.great_tree.visible,
		"Ash raises the courtyard gate and exposes the burnt approach.")
	_check(_world.castle_ash.visible and not _world.castle_life.visible and not _world.court_lanterns.visible,
		"The courtyard changes in Ash.")
	_check_courtyard_fire(true)
	var smoke := _world.fire_particles_group.get_node("Fire1/Smoke") as CPUParticles3D
	_check(smoke.emitting and smoke.is_visible_in_tree() and not _world.corridor_forest.visible,
		"Active fire and charred trees replace the living grove.")
	_check_burned_placements(true)
	_check(not _bridge_is_intact() and _world.collapsed_bridge.visible and not _seal.visible,
		"The ruined bridge has a real gap rather than a magical lock.")
	_check(_world.collapsed_bridge.get_node("BurnedShoring").is_visible_in_tree()
		and not _world.intact_bridge.get_node("Shoring").is_visible_in_tree() and _remnant_smoke().emitting,
		"The bridge ruins expose burned shoring, a burned shed and smoldering debris.")
	_check(_tower_has_solid_base(), "Direct entry into the tower from the courtyard is unavailable.")
	_check(_front_panel_is_closed(), "Ash keeps the front masonry intact.")
	_barracks.interact()
	await get_tree().create_timer(0.8).timeout
	var ash_entry := _ray(Vector3(14.0, 1.6, -112.6), Vector3(17.4, 1.6, -112.6))
	_check(ash_entry.is_empty(), "The barracks doorway is clear when opened in Ash.")
	_barracks.restore_door()
	_captain_seal.interact()
	_keep.interact()
	await get_tree().create_timer(0.82).timeout
	_check(InventoryManager.has_item("throne_hall_key") and _keep.is_open and absf(_keep.left_wing.rotation.y) > 1.0,
		"The reusable captain's seal opens the physical keep doors.")
	_chest.interact()
	_check(InventoryManager.notes.has("captains_sealed_report") == has_shard,
		"The barracks chest gives its report only to the carried crystal shard.")

func _take_quill_and_rewrite() -> void:
	QuestManager.complete_quest("deal_at_the_throne", "accept_deal")
	var quill := _level.find_child("GreatQuillPickup", true, false) as PickupItem
	quill.interact()
	_check(InventoryManager.has_item("great_quill"), "The throne quest gives the Great Quill.")
	_check(_book.get_interaction_prompt() == _book.rewrite_prompt, "The Quill restores the grove book prompt.")
	await _rewrite()

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
	var bedroom := castle.get_node("MageTower/AstromancerWorkshop/AstromancerBed") as StaticBody3D
	_check(bedroom != null and not (bedroom.get_child(0) as CollisionShape3D).disabled,
		"The astromancer has a bed with collision beside the workshop.")

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

func _rewrite() -> void:
	var times: int = InventoryManager.quill_uses_count
	_level.find_child("PedestalWithBook", true, false).interact()
	await get_tree().create_timer(2.15).timeout
	_check(not QuestManager.is_quest_completed("burning_grove") and InventoryManager.quill_uses_count == times + 1,
		"The starting altar rewrites the grove.")

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
	return hit.get("collider") == _world.wall_infill

func _crossing_is_open() -> bool:
	return _ray(Vector3(-23, 13.05, -79.0), Vector3(-23, 14.5, -105.3)).is_empty()

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return _level.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to, 1))

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		_passed = false
