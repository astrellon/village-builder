extends Node3D

class_name EditorController

var _debug_draw_toggled = false

var test_ball = preload("res://test_ball.tscn")

enum EditorToolType { Orbit, Types, Heights }

@export var follow: Node3D
@export var camera: Camera3D
@export var phantom_camera: PhantomCamera3D
@export var terrain_manager: TerrainManager
@export var terrain_brush: TerrainBrushShape

@export var orbit_camera: EditorCameraOrbit
@export var brush_types_tool: EditorBrushTypes
@export var brush_heights_tool: EditorBrushHeights

@export var test_material: ShaderMaterial

var _current_tool: EditorTool
var is_shift_down := false
var locked_orbit := false

func _ready() -> void:
	if self.terrain_brush is TerrainBrushShapeCircle:
		var curve_values = self.terrain_brush.create_curve_values()
		self.test_material.set_shader_parameter('curve_values', curve_values)
		self.test_material.set_shader_parameter('radius', self.terrain_brush.radius)

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

func do_mouse_raycast(event: InputEventMouse) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var from := self.camera.project_ray_origin(event.position)
	var to := from + self.camera.project_ray_normal(event.position) * 100
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	
	var result := space_state.intersect_ray(query)
	return result

func change_tool(tool: EditorToolType) -> void:
	if tool == EditorToolType.Orbit:
		self._current_tool = self.orbit_camera
	elif tool == EditorToolType.Types:
		self._current_tool = self.brush_types_tool
	elif tool == EditorToolType.Heights:
		self._current_tool = self.brush_heights_tool

func _input(event: InputEvent):
	if event is InputEventKey and event.keycode == Key.KEY_SHIFT:
		self.is_shift_down = event.is_pressed()
	
	if self.locked_orbit:
		self.orbit_camera.process_input(self, event)
		
		if event is InputEventMouseButton:
			if event.is_released():
				self.locked_orbit = false
	else:
		if !self.orbit_camera.process_input(self, event):
			if self._current_tool != null:
				self._current_tool.process_input(self, event)
		else:
			self.locked_orbit = true
	
	if event is InputEventMouseMotion:
		var result := self.do_mouse_raycast(event)
		if result.has('position'):
			var target_pos: Vector3 = result['position']
			self.test_material.set_shader_parameter('target_pos', target_pos)
	
	#if event is InputEventMouseButton and event.pressed:
		#var height_change := 0.0
		#if event.button_index == 1:
			#height_change = 1.0
		#elif event.button_index == 2:
			#height_change = -1.0
		#
		#if is_zero_approx(height_change):
			#return
		#
		#var result := self.do_mouse_raycast(event)
		#if result.has('position'):
			#var hit_position = result['position']
			##var new_position = Vector3(hit_position.x, hit_position.y + 2.0, hit_position.z)
			##self._spawn_balls(new_position)
			#
			##self.terrain_manager.terrain_data.brush_heights(hit_position, self.terrain_brush, height_change, self._is_shift_down)
			#var type := 1 if self.is_shift_down else 0
			#self.terrain_manager.terrain_data.brush_types(hit_position, self.terrain_brush, type, 0x03)
		
		#if result.has('face_index') and result.has('collider'):
			#var face_index: int = result['face_index']
			#var collider: StaticBody3D = result['collider']
			#
			#var terrain_chunk_render := collider.get_parent() as TerrainChunkRender
			#
			#var face_data := terrain_chunk_render._terrain.get_face_data(face_index)
			#var x := face_data & 0x3F
			#var y := (face_data >> 6) & 0x3F
			#var type := ((face_data >> 12) & 0x7) as TerrainChunkData.FaceType
			#
			#var pos = terrain_chunk_render._terrain.position
			#print('Click on chunk %s,%s,%s, face %s, at %s, %s type: %s' % [pos.x, pos.y, pos.z, face_index, x, y, type])
			
			

func _spawn_balls(pos: Vector3) -> void:
	var new_ball = self.test_ball.instantiate() as Node3D
	
	new_ball.position = pos
	add_sibling(new_ball)
