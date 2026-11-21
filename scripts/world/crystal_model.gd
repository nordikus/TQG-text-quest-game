@tool
extends MeshInstance3D

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var heel := Vector3(-0.08, -0.83, 0.08)
	var apex := Vector3(0.19, 0.84, -0.10)
	for i in 6:
		var a := _shoulder(i)
		var b := _shoulder(i + 1)
		var prism_a := a * Vector3(0.86, 1.0, 0.86) + Vector3.DOWN * 0.73
		var prism_b := b * Vector3(0.86, 1.0, 0.86) + Vector3.DOWN * 0.73
		var vivid := Color(0.24, 0.76, 0.82).lerp(Color(0.68, 0.95, 1.0), 0.32 + 0.25 * sin(i * 1.8))
		_facets(surface, [a, b, apex], vivid.lightened(0.12))
		_facets(surface, [prism_a, prism_b, b, prism_a, b, a], vivid)
		_facets(surface, [heel, prism_b, prism_a], vivid.darkened(0.24))
	surface.generate_normals()
	var quartz := StandardMaterial3D.new()
	quartz.vertex_color_use_as_albedo = true
	quartz.vertex_color_is_srgb = true
	quartz.cull_mode = BaseMaterial3D.CULL_DISABLED
	quartz.roughness = 0.31
	quartz.metallic = 0.31
	quartz.emission_enabled = true
	quartz.emission = Color(0.13, 0.62, 0.73)
	quartz.emission_energy_multiplier = 0.57
	surface.set_material(quartz)
	mesh = surface.commit()

func _shoulder(index: int) -> Vector3:
	var facet := index % 6
	var angle := TAU * facet / 6.0
	return Vector3(cos(angle) * 0.47, 0.33 + 0.11 * sin(facet * 1.67), sin(angle) * 0.42)

func _facets(surface: SurfaceTool, points: Array, color: Color) -> void:
	surface.set_color(color)
	for point in points:
		surface.add_vertex(point)
