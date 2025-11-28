extends TerrainBrushShape

class_name TerrainBrushShapeCircle

@export var radius: float = 1.0
@export var curve: Curve = Curve.new()

func create_curve_values() -> PackedFloat32Array:
	const length := 32
	var result := PackedFloat32Array()
	result.resize(length)
	
	var step = 1.0 / float(length)
	for i in range(length):
		result[i] = self.curve.sample(i * step)
	
	return result

func size() -> Vector3:
	return Vector3(self.radius * 2.0, 0.0, self.radius * 2.0)

func evaluate(local_brush_center: Vector3, local_target_position: Vector3) -> float:
	var dist = (Vector2(local_target_position.x, local_target_position.z) - Vector2(local_brush_center.x, local_brush_center.z)).length()
	if dist > self.radius:
		return 0.0
	
	var ratio = 1.0 - (dist / self.radius)
	return self.curve.sample(ratio)
