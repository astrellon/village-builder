extends Resource

class_name TerrainBrushShape

func size() -> Vector3:
	return Vector3.ZERO

func evaluate(_local_brush_center: Vector3, _local_target_position: Vector3) -> float:
	return 0.0
