class_name EditorCameraOrbit
extends EditorTool

@export var speed: float = 1.0
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var min_yaw: float = 0
@export var max_yaw: float = 360

func process_input(controller: EditorController, event: InputEvent) -> bool:
	var x_rotate := 0.0
	var y_rotate := 0.0
	var zoom := 0.0
	var has_input := false
	
	if event is InputEventMouseMotion:
		if event.button_mask & MouseButtonMask.MOUSE_BUTTON_MASK_LEFT != 0:
			x_rotate = event.relative.y * speed
			y_rotate = event.relative.x * speed
			has_input = true
			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = -0.1
			has_input = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = 0.1
			has_input = true
	
	if has_input:
		self.orbit_camera(controller.phantom_camera, x_rotate, y_rotate, zoom)
	return has_input

func orbit_camera(camera: PhantomCamera3D, x_rotate: float, y_rotate: float, zoom: float) -> void:
	if camera.get_follow_mode() != camera.FollowMode.THIRD_PERSON:
		return
	
	if !is_zero_approx(x_rotate) || !is_zero_approx(y_rotate):
		var pcam_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		pcam_rotation_degrees = camera.get_third_person_rotation_degrees()

		# Change the X rotation
		pcam_rotation_degrees.x -= x_rotate

		# Clamp the rotation in the X axis so it go over or under the target
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		pcam_rotation_degrees.y -= y_rotate

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)
		
		# Change the SpringArm3D node's rotation and rotate around its target
		camera.set_third_person_rotation_degrees(pcam_rotation_degrees)

	if !is_zero_approx(zoom):
		var length = camera.get_spring_length()
		camera.set_spring_length(max(1.0, length + zoom))
