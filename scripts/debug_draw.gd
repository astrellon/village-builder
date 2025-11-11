extends Node3D

var _debug_draw_toggle = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_draw"):
		self._debug_draw_toggle = !self._debug_draw_toggle
		var debug_draw = Viewport.DEBUG_DRAW_WIREFRAME if self._debug_draw_toggle else Viewport.DEBUG_DRAW_DISABLED
		print("Toggle debug draw " + str(self._debug_draw_toggle))
		get_viewport().debug_draw = debug_draw
