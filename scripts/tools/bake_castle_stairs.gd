@tool
extends SceneTree

const OUTPUT := "res://scenes/world/castle/"

func _initialize() -> void:
	var spiral_ok := _bake_flight("tower_stairs", _tower_section, 98, 6, false)
	var grand_ok := _bake_flight("keep_stairs", _keep_section, 36, 1, true)
	var service_ok := _bake_flight("service_stairs", _straight_section.bind(2.7, 6.4, 3.05), 16, 1, true)
	var cellar_ok := _bake_flight("cellar_stairs", _straight_section.bind(2.2, 7.2, 3.8), 20, 1, true)
	quit(0 if spiral_ok and grand_ok and service_ok and cellar_ok else 1)

# One section is left and right at the actual grade, followed by the two points
# along the underside. The spiral starts at the court floor and joins the two landings.
func _tower_section(progress: float) -> PackedVector3Array:
	var step := lerpf(-1.15, 95.9, progress)
	var angle := step * (3.42 * TAU / 95.0)
	var direction := Vector3(cos(angle), 0, sin(angle))
	var outer_radius := lerpf(2.69, 3.35, smoothstep(11.0, 16.0, step))
	var grade := lerpf(0.27, 6.35, inverse_lerp(-1.15, 28.85, step))
	if step > 28.85:
		grade = lerpf(6.35, 20.15, inverse_lerp(28.85, 95.9, step))
	var high := Vector3.UP * grade
	var underside := high - Vector3.UP * 0.25
	return PackedVector3Array([
		direction * 0.42 + high, direction * outer_radius + high,
		direction * 0.42 + underside, direction * outer_radius + underside,
	])

func _keep_section(progress: float) -> PackedVector3Array:
	var z := lerpf(-10.8, 3.04, progress)
	var grade := lerpf(0.25, 6.35, progress)
	return PackedVector3Array([
		Vector3(-24.5, grade, z), Vector3(-20.5, grade, z),
		Vector3(-24.5, 0.20, z), Vector3(-20.5, 0.20, z),
	])

func _straight_section(progress: float, width: float, run: float, rise: float) -> PackedVector3Array:
	var z := -run * progress
	var height := rise * progress
	var half := width * 0.5
	return PackedVector3Array([
		Vector3(half, height, z), Vector3(-half, height, z),
		Vector3(half, -0.16, z), Vector3(-half, -0.16, z),
	])

func _bake_flight(name: String, section: Callable, risers: int, subdivisions: int, solid_base: bool) -> bool:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.set_smooth_group(-1)
	var collision := PackedVector3Array()
	var previous_visual_end := PackedVector3Array()

	for index in risers:
		var previous_grade: PackedVector3Array = section.call(float(index) / risers)
		var tread_grade: PackedVector3Array = section.call(float(index + 1) / risers)
		var tread_height := lerpf(previous_grade[0].y, tread_grade[0].y, 0.5)
		for sample in range(1, subdivisions + 1):
			var t := (index + float(sample) / subdivisions) / risers
			var next_grade: PackedVector3Array = section.call(t)
			var start := previous_grade.duplicate()
			var finish := next_grade.duplicate()
			for edge in range(2):
				start[edge].y = tread_height
				finish[edge].y = tread_height
			if sample == 1:
				if previous_visual_end.is_empty():
					previous_visual_end = previous_grade
				_face(mesh, previous_visual_end[0], previous_visual_end[1], start[1], start[0])
			_flight_segment(mesh, start, finish, not solid_base)
			_walk_segment(collision, previous_grade, next_grade, solid_base)
			previous_grade = next_grade
			previous_visual_end = finish

	var start_grade: PackedVector3Array = section.call(0.0)
	var end_grade: PackedVector3Array = section.call(1.0)
	_face(mesh, start_grade[2], start_grade[3], start_grade[1], start_grade[0])
	_face(mesh, end_grade[3], end_grade[2], previous_visual_end[0], previous_visual_end[1])
	mesh.generate_normals()

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(collision)
	var mesh_error := ResourceSaver.save(mesh.commit(), OUTPUT + name + "_mesh.res")
	var shape_error := ResourceSaver.save(shape, OUTPUT + name + "_collision.res")
	if mesh_error != OK or shape_error != OK:
		push_error("Could not bake %s: mesh %s, collision %s" % [name, mesh_error, shape_error])
		return false
	print("Baked %s: %d collision faces" % [name, collision.size() / 3])
	return true

func _flight_segment(mesh: SurfaceTool, a: PackedVector3Array, b: PackedVector3Array, curved: bool) -> void:
	_face(mesh, a[0], a[1], b[1], b[0])
	_face(mesh, a[2], a[0], b[0], b[2])
	_face(mesh, a[3], b[3], b[1], a[1])
	# Smooth the underside of the spiral across its twisted radial sections.
	if curved:
		mesh.set_smooth_group(0)
	_face(mesh, a[3], a[2], b[2], b[3])
	mesh.set_smooth_group(-1)

func _walk_segment(out: PackedVector3Array, a: PackedVector3Array, b: PackedVector3Array, solid_base: bool) -> void:
	if solid_base:
		out.append_array(PackedVector3Array([a[0], a[1], b[1], a[0], b[1], b[0]]))
		out.append_array(PackedVector3Array([a[2], a[0], b[0], a[2], b[0], b[2]]))
		out.append_array(PackedVector3Array([a[3], b[3], b[1], a[3], b[1], a[1]]))
	else:
		# A wide helix quad twists. Short radial spans keep the slope underfoot
		# close to the local helix grade instead of following the inner edge.
		const RADIAL_SPANS := 10
		for span in RADIAL_SPANS:
			var start := float(span) / RADIAL_SPANS
			var finish := float(span + 1) / RADIAL_SPANS
			var al := a[0].lerp(a[1], start)
			var ar := a[0].lerp(a[1], finish)
			var bl := b[0].lerp(b[1], start)
			var br := b[0].lerp(b[1], finish)
			out.append_array(PackedVector3Array([al, ar, br, al, br, bl]))
			var under := Vector3.DOWN * 0.25
			out.append_array(PackedVector3Array([ar + under, al + under, bl + under,
				ar + under, bl + under, br + under]))

func _face(mesh: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		mesh.add_vertex(point)
