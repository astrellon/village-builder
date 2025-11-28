extends Button

@export var curve: Curve

func _pressed() -> void:
	var circle := EditorController.instance.terrain_brush_circle
	
	circle.update_curve(self.curve)
	EditorController.instance.change_terrain_shape(circle)
