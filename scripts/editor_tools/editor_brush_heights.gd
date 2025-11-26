class_name EditorBrushHeights
extends EditorTool

func process_input(controller: EditorController, event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.is_released():
		var height_change := 0.0
		if event.button_index == 1:
			height_change = 1.0
		elif event.button_index == 2:
			height_change = -1.0
		
		if is_zero_approx(height_change):
			return false
		
		var result := controller.do_mouse_raycast(event)
		if result.has('position'):
			var hit_position = result['position']
			controller.terrain_manager.terrain_data.brush_heights(hit_position, controller.terrain_brush, height_change, controller.is_shift_down)
			
			return true
	
	return false
