@tool
extends MeshInstance3D

const WEST_STAIR_WAY := [
	Vector2(-2.24, -8.1), Vector2(-9.0, -8.1), Vector2(-17.6, -8.5),
	Vector2(-25.5, -8.5), Vector2(-28.4, -10.8), Vector2(-29.4, -16.1),
	Vector2(-33.2, -20.65), Vector2(-41.05, -20.65),
]
const EAST_STAIR_WAY := [
	Vector2(2.24, -38.55), Vector2(8.0, -38.55), Vector2(17.0, -40.15),
	Vector2(28.5, -40.15), Vector2(35.5, -44.0), Vector2(36.65, -49.2),
	Vector2(41.05, -49.2),
]

func _ready() -> void:
	var paving := SurfaceTool.new()
	paving.begin(Mesh.PRIMITIVE_TRIANGLES)
	_road(paving, WEST_STAIR_WAY, 1.38)
	_road(paving, EAST_STAIR_WAY, 1.43)
	_road(paving, [Vector2(-9.9, -4.75), Vector2(-9.9, -8.15)], 1.1)
	_road(paving, [Vector2(-2.24, -21.55), Vector2(-3.7, -21.55), Vector2(-11.95, -21.65)], 1.32)
	_road(paving, [Vector2(4.25, -4.45), Vector2(4.20, -6.8), Vector2(5.23, -8.84)], 0.88)
	_road(paving, [Vector2(12.75, -24.17), Vector2(12.6, -28.8), Vector2(12.65, -35.5),
		Vector2(12.7, -39.55)], 1.06)
	_polygon(paving, PackedVector2Array([
		Vector2(-2.22, 2.1), Vector2(-6.95, 2.1), Vector2(-7.9, 3.35), Vector2(-14.0, 3.35),
		Vector2(-15.3, 2.25), Vector2(-15.3, -3.95), Vector2(-14.2, -5.12),
		Vector2(-7.35, -5.12), Vector2(-6.2, -3.77), Vector2(-2.22, -3.77),
	]), 0.047)
	_polygon(paving, PackedVector2Array([
		Vector2(10.55, -27.65), Vector2(14.05, -27.65), Vector2(15.14, -28.64),
		Vector2(15.14, -35.55), Vector2(14.15, -36.54), Vector2(10.55, -36.54),
		Vector2(9.95, -35.54), Vector2(9.95, -29.05),
	]), 0.047)
	paving.generate_normals()
	mesh = paving.commit()

func _road(paving: SurfaceTool, points: Array, half_width: float) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in points.size():
		var point: Vector2 = points[i]
		var incoming := (point - Vector2(points[maxi(0, i - 1)])).normalized()
		var outgoing := (Vector2(points[mini(i + 1, points.size() - 1)]) - point).normalized()
		var tangent := (incoming + outgoing).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var nearest := outgoing if outgoing != Vector2.ZERO else incoming
		var offset := normal * half_width / maxf(0.78, tangent.dot(nearest))
		left.append(point + offset)
		right.append(point - offset)
	right.reverse()
	left.append_array(right)
	_polygon(paving, left, 0.042)

func _polygon(paving: SurfaceTool, points: PackedVector2Array, height: float) -> void:
	for i in Geometry2D.triangulate_polygon(points):
		paving.add_vertex(Vector3(points[i].x, height, points[i].y))
