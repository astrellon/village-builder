@abstract 
class_name TerrainBrushShape extends Resource

@warning_ignore("unused_signal")
signal on_change

@abstract func size() -> Vector3
@abstract func evaluate(_local_brush_center: Vector3, _local_target_position: Vector3) -> float
