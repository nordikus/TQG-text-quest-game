# Ancient Tree Path & Castle Approach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Relocate the Great Tree to the castle plateau at `(-21, 0, -110)`, replace the artificial staircase and 130m pipeline with an organic serpentine root ramp and a majestic 30-meter ancient bough bridge to the Mage Tower balcony, build a winding verdant nature trail from the altar, verify 100% pure WASD walkability, and push the project to GitHub.

**Architecture:** The Great Tree is placed adjacent to the Mage Tower balcony, turning the sky overpass into a natural 30m bough bridge. Ascent up the trunk is remodeled as an organic monolithic root ramp with a wide moss walking ridge. A ground trail adorned with glowing fireflies, moss, and ferns connects the altar clearing to the tree's base through the living woods.

**Tech Stack:** Godot 4.7.2 (GDScript, CharacterBody3D, StaticBody3D, Jolt Physics 3D, MultiMeshInstance3D), Git.

**Spec:** `docs/superpowers/specs/2026-11-09-ancient-tree-path-design.md`

## Global Constraints

- Engine: Godot 4.7.2 stable headless console `Godot_v4.7.2-stable_win64_console.exe`.
- Player metrics: capsule radius 0.4m, height 1.8m, `floor_snap_length = 0.35`, `floor_max_angle = 0.907rad` (52°).
- Walkability invariant: pure WASD holding forward with ZERO jumping required across the entire path.
- Visual style: Low-poly stylized fantasy (faceted geometries, untextured flat-shaded materials with palette colors, natural organic curves).
- No emojis, concise reporting.
- Remote repository: `https://github.com/nordikus/TQG-text-quest-game`.

## Review Focus

1. Player getting stuck on vertical step edges: verified by ensuring every ramp segment's leading edge is buried below the previous surface (`diff < 0`).
2. Player colliding with trunk collision cylinder ($R = 2.65$m): verified by ensuring walk trajectory stays at $R \ge 3.4$m.
3. Bridge alignment with `TowerBalcony` ($X = -22.5, Y = 20.6, Z = -157$): verified by landing within $\pm 0.1$m vertically and horizontally flush.
4. Ground trail clearance: verified by ensuring $> 1.5$m width between forest trees along the trail.
5. Tree sprout animation: verified that `world_changer.gd` correctly animates `GreatTree.position.y` from $-35.0$ to $0.0$.

---

### Task 1: Relocate Great Tree & Clean Up Legacy Bridge Geometry

**Files:**
- Modify: `scenes/forest_clearing.tscn`
- Modify: `scenes/world/great_tree.tscn`
- Test: `scripts/tools/test_task1_relocation.gd`

**Interfaces:**
- Consumes: `scenes/world/great_tree.tscn`, `scenes/forest_clearing.tscn`
- Produces: `GreatTree` placed at `(-21.0, 0.0, -110.0)` with legacy 130m bridge nodes removed.

- [ ] **Step 1: Write test script to verify GreatTree relocation and node hierarchy**

Create `scripts/tools/test_task1_relocation.gd`:
```gdscript
@tool
extends SceneTree

func _init() -> void:
	var clearing = load("res://scenes/forest_clearing.tscn").instantiate()
	var gt = clearing.get_node_or_null("GreatTree")
	assert(gt != null, "GreatTree node must exist")
	assert(gt.position.distance_to(Vector3(-21.0, 0.0, -110.0)) < 0.1, "GreatTree must be at (-21, 0, -110)")
	
	var tree_scene = load("res://scenes/world/great_tree.tscn").instantiate()
	var stairs = tree_scene.get_node_or_null("BranchStairs")
	assert(stairs != null, "BranchStairs must exist")
	# Legacy bridge nodes removed
	var legacy_walkway = tree_scene.get_node_or_null("CanopyWalkwayToTower")
	assert(legacy_walkway == null, "CanopyWalkwayToTower must be removed from legacy tree")
	print("PASS: Task 1 verification successful")
	clearing.queue_free()
	tree_scene.queue_free()
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/test_task1_relocation.gd`
Expected: FAIL (GreatTree still at old position `(-9, 0, -10)`).

- [ ] **Step 3: Update `scenes/forest_clearing.tscn` and `scenes/world/great_tree.tscn`**

1. In `scenes/forest_clearing.tscn`, change `GreatTree` transform origin to `(-21.0, 0.0, -110.0)`.
2. In `scenes/world/great_tree.tscn`, remove `CanopyWalkwayToTower` node and its children.

- [ ] **Step 4: Run test to verify it passes**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/test_task1_relocation.gd`
Expected: PASS with "PASS: Task 1 verification successful".

- [ ] **Step 5: Clean up test script**

Remove `scripts/tools/test_task1_relocation.gd`.

---

### Task 2: Build Organic Serpentine Root Spiral Ascent

**Files:**
- Modify: `scenes/world/great_tree.tscn`
- Builder: `scripts/tools/build_root_spiral.gd`
- Test: `scripts/tools/test_root_spiral_walk.gd`

**Interfaces:**
- Consumes: `TrunkBody` at `(0, 0, 0)` in `great_tree.tscn`
- Produces: `RootSpiral` in `BranchStairs` spanning $Y = 0.5$ to $Y = 19.5$, connecting seamlessly to `CanopyTerrace`.

- [ ] **Step 1: Write test script for root spiral walk**

Create `scripts/tools/test_root_spiral_walk.gd`:
```gdscript
extends Node3D

@onready var player: CharacterBody3D = $TestPlayer
var frame_count := 0
var waypoints: Array[Vector3] = []
var cur_target := 0

func _ready() -> void:
	var stairs = $GreatTree/BranchStairs
	for child in stairs.get_children():
		if child is StaticBody3D and "RootStep" in child.name:
			waypoints.append(child.global_position + Vector3(0, 0.4, 0))
	waypoints.append($GreatTree/CanopyTerrace.global_position + Vector3(0, 0.4, 0))
	player.global_position = waypoints[0]
	print("Testing root spiral walk with %d waypoints" % waypoints.size())

func _physics_process(delta: float) -> void:
	frame_count += 1
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta
	var target = waypoints[cur_target]
	var diff = target - player.global_position
	if Vector2(diff.x, diff.z).length() < 0.9:
		if cur_target < waypoints.size() - 1:
			cur_target += 1
		else:
			print("PASS: Reached CanopyTerrace via RootSpiral in %d frames" % frame_count)
			get_tree().quit(0)
			return
	var dir = Vector3(diff.x, 0, diff.z).normalized()
	player.velocity.x = dir.x * 4.5
	player.velocity.z = dir.z * 4.5
	player.move_and_slide()
	if frame_count > 600:
		printerr("FAIL: Stuck on RootSpiral at %s" % player.global_position)
		get_tree().quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless scenes/test_ramp.tscn`
Expected: FAIL (RootStep nodes not yet created).

- [ ] **Step 3: Implement builder `scripts/tools/build_root_spiral.gd`**

Create builder script that:
1. Generates 22 serpentine root segments `RootStep0`..`RootStep21` along radius $R = 3.55$m, slope $24^\circ$.
2. Shapes each step with mossy upper deck `Vector3(3.0, 0.4, 2.6)` and organic bark flank/railing.
3. Completely buries every front edge below previous step (`diff < 0`).
4. Reaches `CanopyTerrace` deck at $Y = 19.5$ with zero lip.
5. Saves `great_tree.tscn`.

Execute builder:
`& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/build_root_spiral.gd`

- [ ] **Step 4: Run test to verify it passes**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless scenes/test_ramp.tscn`
Expected: PASS with "PASS: Reached CanopyTerrace via RootSpiral".

- [ ] **Step 5: Clean up temporary builder and runner**

Remove `scripts/tools/build_root_spiral.gd` and `scripts/tools/test_root_spiral_walk.gd`.

---

### Task 3: Build 30-Meter Ancient Bough Bridge to Mage Tower Balcony

**Files:**
- Modify: `scenes/world/great_tree.tscn`
- Builder: `scripts/tools/build_bough_bridge.gd`
- Test: `scripts/tools/test_bough_bridge_walk.gd`

**Interfaces:**
- Consumes: `CanopyTerrace` at local `(0, 19.5, -4.5)` (world `(-21, 19.5, -114.5)`) and `TowerBalcony` at world `(-22.5, 20.6, -157.0)`.
- Produces: `AncientBoughBridge` in `great_tree.tscn` spanning from terrace to balcony (approx 30m).

- [ ] **Step 1: Write test script for bough bridge walk**

Create `scripts/tools/test_bough_bridge_walk.gd`:
```gdscript
extends Node3D

@onready var player: CharacterBody3D = $TestPlayer
var frame_count := 0
var waypoints: Array[Vector3] = []
var cur_target := 0

func _ready() -> void:
	# Start on CanopyTerrace
	var gt = $GreatTree
	player.global_position = gt.global_position + Vector3(0, 20.0, -4.5)
	var bridge = gt.get_node("AncientBoughBridge")
	for child in bridge.get_children():
		if child is StaticBody3D:
			waypoints.append(child.global_position + Vector3(0, 0.4, 0))
	# Destination: TowerBalcony
	waypoints.append(Vector3(-22.5, 21.0, -157.0))

func _physics_process(delta: float) -> void:
	frame_count += 1
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta
	var target = waypoints[cur_target]
	var diff = target - player.global_position
	if Vector2(diff.x, diff.z).length() < 1.0:
		if cur_target < waypoints.size() - 1:
			cur_target += 1
		else:
			print("PASS: Player walked across AncientBoughBridge to TowerBalcony in %d frames" % frame_count)
			get_tree().quit(0)
			return
	var dir = Vector3(diff.x, 0, diff.z).normalized()
	player.velocity.x = dir.x * 5.0
	player.velocity.z = dir.z * 5.0
	player.move_and_slide()
	if frame_count > 500:
		printerr("FAIL: Stuck on AncientBoughBridge at %s" % player.global_position)
		get_tree().quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless scenes/test_ramp.tscn`
Expected: FAIL (AncientBoughBridge does not exist yet).

- [ ] **Step 3: Implement builder `scripts/tools/build_bough_bridge.gd`**

Create builder script that:
1. Adds `AncientBoughBridge` node to `great_tree.tscn`.
2. Generates 4 natural curved bough segments from local `(0, 19.5, -4.5)` towards local `(-1.5, 20.6, -47.0)` (which corresponds to world `(-22.5, 20.6, -157.0)` when GreatTree is at `(-21, 0, -110)`).
3. Adds thick massive cylinder/box bark trunk with moss walking surface (width 2.8m, thickness 0.4m), organic natural branches and leafy clusters hanging above.
4. Smoothly meets `TowerBalcony` at `Y = 20.6` with zero drop.
5. Saves `great_tree.tscn`.

Execute builder:
`& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/build_bough_bridge.gd`

- [ ] **Step 4: Run test to verify it passes**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless scenes/test_ramp.tscn`
Expected: PASS with "PASS: Player walked across AncientBoughBridge to TowerBalcony".

- [ ] **Step 5: Clean up test files**

Remove `scripts/tools/build_bough_bridge.gd` and `scripts/tools/test_bough_bridge_walk.gd`.

---

### Task 4: Create Verdant Nature Trail from Altar to Great Tree

**Files:**
- Modify: `scenes/forest_clearing.tscn`
- Builder: `scripts/tools/build_nature_trail.gd`
- Test: `scripts/tools/test_nature_trail_walk.gd`

**Interfaces:**
- Consumes: StoneAltar at `(0, 0, 0)` and GreatTree at `(-21, 0, -110)` in `forest_clearing.tscn`.
- Produces: `NatureTrail` node in `forest_clearing.tscn` with path geometry, visual moss/fern props, and fireflies.

- [ ] **Step 1: Write test script for nature trail walk**

Create `scripts/tools/test_nature_trail_walk.gd`:
```gdscript
extends Node3D

@onready var player: CharacterBody3D = $Player
var waypoints: Array[Vector3] = [
	Vector3(0.0, 0.1, 8.0),     # Player spawn
	Vector3(0.0, 0.1, 0.0),     # Altar
	Vector3(-6.0, 0.1, -25.0),  # Nature trail 1
	Vector3(-12.0, 0.1, -55.0), # Nature trail 2
	Vector3(-18.0, 0.1, -85.0), # Nature trail 3
	Vector3(-21.0, 0.1, -107.0) # GreatTree base
]
var cur_target := 0
var frame_count := 0

func _physics_process(delta: float) -> void:
	frame_count += 1
	var target = waypoints[cur_target]
	var diff = target - player.global_position
	if Vector2(diff.x, diff.z).length() < 1.2:
		if cur_target < waypoints.size() - 1:
			cur_target += 1
		else:
			print("PASS: Player walked along NatureTrail to GreatTree base in %d frames" % frame_count)
			get_tree().quit(0)
			return
	var dir = Vector3(diff.x, 0, diff.z).normalized()
	player.velocity.x = dir.x * 5.0
	player.velocity.z = dir.z * 5.0
	player.move_and_slide()
	if frame_count > 600:
		printerr("FAIL: Stuck on NatureTrail at %s" % player.global_position)
		get_tree().quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/test_nature_trail_walk.gd`
Expected: FAIL (dense forest wall or trees block passage at $Z \approx -20$).

- [ ] **Step 3: Implement builder `scripts/tools/build_nature_trail.gd`**

Create builder script that:
1. Clears corridor trees on the west side along the trail line: `(0, 0) -> (-6, -25) -> (-12, -55) -> (-18, -85) -> (-21, -107)`.
2. Adds `NatureTrail` node with curved mossy earth path mesh.
3. Places glowing forest fireflies (`ForestFireflies`), bioluminescent ferns, and ancient mossy boulders guiding the player along the path.
4. Sets up natural side tree boundaries preventing the player from wandering off into unmodeled areas.
5. Saves `scenes/forest_clearing.tscn`.

Execute builder:
`& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/build_nature_trail.gd`

- [ ] **Step 4: Run test to verify it passes**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/test_nature_trail_walk.gd`
Expected: PASS with "PASS: Player walked along NatureTrail to GreatTree base".

- [ ] **Step 5: Clean up test files**

Remove `scripts/tools/build_nature_trail.gd` and `scripts/tools/test_nature_trail_walk.gd`.

---

### Task 5: End-to-End Walk Simulation & Sprout Integration

**Files:**
- Modify: `scripts/world/world_changer.gd`
- Test: `scripts/tools/test_full_gameplay_flow.gd`

**Interfaces:**
- Consumes: Complete `scenes/forest_clearing.tscn` with `NatureTrail`, `GreatTree`, and `CastleFacade`.
- Produces: Verified end-to-end walkthrough from spawn through book choice to Mage Tower balcony.

- [ ] **Step 1: Write comprehensive end-to-end simulation test**

Create `scripts/tools/test_full_gameplay_flow.gd` simulating:
1. Player spawns at `(0, 0.1, 10.5)`.
2. Triggers `world_changer._apply_extinguish_outcome()` (GreatTree sprouts at `(-21, 0, -110)`).
3. Player walks NatureTrail to GreatTree base.
4. Player ascends RootSpiral up to `CanopyTerrace`.
5. Player crosses `AncientBoughBridge` onto `TowerBalcony`.
6. Asserts `is_on_floor() == true` on every frame, 0 jumps, 0 collisions with walls.

- [ ] **Step 2: Run test and verify it passes**

Run: `& 'C:\Users\nordiko\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless -s scripts/tools/test_full_gameplay_flow.gd`
Expected: PASS with "PASS: Complete Nature Walk from Spawn to Mage Tower Balcony succeeded in N frames".

- [ ] **Step 3: Clean up temporary test script**

Remove `scripts/tools/test_full_gameplay_flow.gd`.

---

### Task 6: Git Setup, Commit & Push to GitHub

**Files:**
- Create: `.gitignore`
- Repository: `https://github.com/nordikus/TQG-text-quest-game`

**Interfaces:**
- Consumes: Clean working tree in `c:\Users\nordiko\Documents\tqg`.
- Produces: Git repository initialized, committed, and pushed to remote origin.

- [ ] **Step 1: Create `.gitignore` for Godot 4**

Create `.gitignore` containing:
```gitignore
.godot/
*.translation
*.import
.tmp/
scripts/tools/__pycache__/
```

- [ ] **Step 2: Initialize Git and stage files**

Run:
```powershell
git init
git remote add origin https://github.com/nordikus/TQG-text-quest-game
git add .
git status
```
Verify that `.godot/` is excluded and all assets, scenes, and scripts are staged.

- [ ] **Step 3: Commit changes**

Run:
```powershell
git commit -m "feat: natural tree path, relocated great tree to castle plateau, and organic bough bridge"
```

- [ ] **Step 4: Push to GitHub**

Run:
```powershell
git branch -M main
git push -u origin main
```
Expected: Successfully pushed to `https://github.com/nordikus/TQG-text-quest-game`.
