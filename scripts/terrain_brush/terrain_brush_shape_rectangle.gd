extends TerrainBrushShape

class_name TerrainBrushShapeRectangle

@export var half_size: Vector2 = Vector2.ONE
@export var curve: Curve = Curve.new()

func create_curve_values() -> PackedFloat32Array:
	const length := 32
	var result := PackedFloat32Array()
	result.resize(length)
	
	var step = 1.0 / float(length)
	for i in range(length):
		result[i] = self.curve.sample(i * step)
	
	return result

func update_curve(new_curve: Curve) -> void:
	if self.curve != new_curve:
		self.curve = new_curve
		self.on_change.emit()

func update_half_size(new_half_size: Vector2) -> void:
	if self.half_size != new_half_size:
		self.half_size = new_half_size
		self.on_change.emit()

func size() -> Vector3:
	return Vector3(self.half_size.x * 2.0, 0.0, self.half_size.y * 2.0)

func evaluate(local_brush_center: Vector3, local_target_position: Vector3) -> float:
	var diff := (Vector2(local_target_position.x, local_target_position.z) - Vector2(local_brush_center.x, local_brush_center.z)).abs()
	if diff.x > self.half_size.x || diff.y > self.half_size.y:
		return 0.0
	
	var max_dim := maxf(diff.x / self.half_size.x, diff.y / self.half_size.y)
	var ratio = 1.0 - max_dim
	return self.curve.sample(ratio)
