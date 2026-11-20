extends RefCounted

const LIFE_PATH: Array[Vector3] = [
	Vector3(-2.8, 0, -7), Vector3(-4.5, 0, -17.5), Vector3(-6.2, 0, -25),
	Vector3(-9, 0, -35.5), Vector3(-13.8, 0, -47.5), Vector3(-17.3, 0, -56.8),
]
const ASH_PATH: Array[Vector3] = [
	Vector3(5.8, 0, -3), Vector3(11, 0, -6.5), Vector3(15.2, 0, -9),
	Vector3(18.5, 0, -17), Vector3(17.5, 0, -35), Vector3(12, 0, -53),
	Vector3(5.5, 0, -68), Vector3(0, 0, -82), Vector3(0, 0, -85),
]
const TREE_BASE := Vector2(-21, -60)
const ROOT_CLEARANCE := 9.5
const ASH_CORE := 2.75

static func distance_to_path(point: Vector2, path: Array[Vector3]) -> float:
	var distance := INF
	for index in range(path.size() - 1):
		var a := Vector2(path[index].x, path[index].z)
		var b := Vector2(path[index + 1].x, path[index + 1].z)
		var nearest := Geometry2D.get_closest_point_to_segment(point, a, b)
		distance = minf(distance, point.distance_to(nearest))
	return distance

static func clear_for_life(point: Vector2, radius: float) -> bool:
	return point.distance_to(TREE_BASE) < ROOT_CLEARANCE + radius \
		or distance_to_path(point, LIFE_PATH) < 2.7 + radius
