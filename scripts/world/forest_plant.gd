@tool
extends MeshInstance3D

const FERN := Color(0.12, 0.23, 0.045)
const GRASS := Color(0.095, 0.17, 0.034)

@export var fern := false
@export var scorched := false

static var _meshes: Dictionary[Vector2i, ArrayMesh]

func _ready() -> void:
	mesh = plant_mesh(fern, scorched)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func plant_mesh(is_fern: bool, burned := false) -> ArrayMesh:
	var key := Vector2i(int(is_fern), int(burned))
	if not _meshes.has(key):
		_meshes[key] = _build_plant(is_fern, burned)
	return _meshes[key]

static func _build_plant(is_fern: bool, burned: bool) -> ArrayMesh:
	var surface := begin_surface()
	var base := Color(0.095, 0.063, 0.037) if burned else (FERN if is_fern else GRASS)
	var tips := Color(0.185, 0.110, 0.046) if burned else Color(0.26, 0.30, 0.051)
	for i in (6 if is_fern else 9):
		var angle := TAU * i * 0.382
		var along := Vector3(sin(angle), 0, cos(angle))
		var width := along.cross(Vector3.UP)
		var height := (0.26 if is_fern else 0.22) + 0.089 * sin(i * 2.37)
		var spread := (0.38 if is_fern else 0.21) + 0.09 * cos(i * 3.4)
		var center := along * 0.065
		var bend := along * spread * 0.53 + Vector3.UP * height * (0.51 if burned else 1.0)
		var tip := along * spread + Vector3.UP * height * (0.27 if burned else (0.77 if is_fern else 1.19))
		var color := base.lerp(tips, (sin(i * 3.2) + 1.0) * 0.18)
		append_leaf(surface, center, bend, tip, width * (0.042 if is_fern else 0.025), color)
		if is_fern:
			for j: float in [0.35, 0.58, 0.79]:
				var stem := center.lerp(bend, j)
				var reach := spread * (0.36 - j * 0.21) * (0.66 if burned else 1.0)
				for side: float in [-1.0, 1.0]:
					var branch := stem + side * width * reach
					append_leaf(surface, stem, branch + along * 0.047, branch + along * 0.084,
						along * 0.026, color.lightened(0.027))
	return finish_surface(surface)

static func append_leaf(surface: SurfaceTool, from: Vector3, bend: Vector3, tip: Vector3,
		width: Vector3, color: Color) -> void:
	surface.set_color(color)
	for point in [from, bend - width, tip]:
		surface.add_vertex(point)
	surface.set_color(color.darkened(0.12))
	for point in [from, tip, bend + width]:
		surface.add_vertex(point)

static func begin_surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface

static func finish_surface(surface: SurfaceTool) -> ArrayMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	surface.set_material(material)
	surface.generate_normals()
	return surface.commit()
