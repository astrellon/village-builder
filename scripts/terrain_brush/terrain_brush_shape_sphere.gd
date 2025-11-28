extends TerrainBrushShape

class_name TerrainBrushShapeSphere

@export var radius: float = 1.0
@export var curve: Curve = Curve.new()

func size() -> Vector3:
	return Vector3(self.radius * 2.0, self.radius * 2.0, self.radius * 2.0)

func evaluate(local_brush_center: Vector3, local_target_position: Vector3) -> float:
	var dist = (local_target_position - local_brush_center).length()
	if dist > self.radius:
		return 0.0
	
	var ratio = 1.0 - (dist / self.radius)
	return self.curve.sample(ratio)
