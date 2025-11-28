extends Button

@export var curve: Curve

func _pressed() -> void:
	var rectangle := EditorController.instance.terrain_brush_rectangle
	
	rectangle.update_curve(self.curve)
	EditorController.instance.change_terrain_shape(rectangle)
