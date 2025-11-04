extends Node3D

var _debug_draw_toggled = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_draw"):
		self._debug_draw_toggled = !self._debug_draw_toggled
		
		var debug_draw = Viewport.DEBUG_DRAW_DISABLED
		if self._debug_draw_toggled:
			debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			
		get_viewport().debug_draw = debug_draw
