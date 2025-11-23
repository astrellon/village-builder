extends Node3D

var _debug_draw_toggled = false

var test_ball = preload("res://test_ball.tscn")

@export var follow: Node3D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_draw"):
		self._debug_draw_toggled = !self._debug_draw_toggled
		
		var debug_draw = Viewport.DEBUG_DRAW_DISABLED
		if self._debug_draw_toggled:
			debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			
		get_viewport().debug_draw = debug_draw
	
	if Input.is_action_just_pressed("spawn_ball"):
		var new_ball = self.test_ball.instantiate() as Node3D
		
		var follow_position = self.follow.global_position
		var new_position = Vector3(follow_position.x, 6, follow_position.z)
		new_ball.position = new_position
		add_sibling(new_ball)
