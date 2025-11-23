extends Node3D

var _debug_draw_toggled = false

var test_ball = preload("res://test_ball.tscn")

@export var follow: Node3D
@export var camera: Camera3D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_draw"):
		self._debug_draw_toggled = !self._debug_draw_toggled
		
		var debug_draw = Viewport.DEBUG_DRAW_DISABLED
		if self._debug_draw_toggled:
			debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			
		get_viewport().debug_draw = debug_draw
	
	if Input.is_action_just_pressed("spawn_ball"):
		var follow_position = self.follow.global_position
		var new_position = Vector3(follow_position.x, 6, follow_position.z)
		self._spawn_balls(new_position)
	
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var space_state := get_world_3d().direct_space_state
		var from := self.camera.project_ray_origin(event.position)
		var to := from + self.camera.project_ray_normal(event.position) * 100
		
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result := space_state.intersect_ray(query)
		if result.has('position'):
			var hit_position = result['position']
			var new_position = Vector3(hit_position.x, hit_position.y + 2.0, hit_position.z)
			self._spawn_balls(new_position)

func _spawn_balls(pos: Vector3) -> void:
	var new_ball = self.test_ball.instantiate() as Node3D
	
	new_ball.position = pos
	add_sibling(new_ball)
