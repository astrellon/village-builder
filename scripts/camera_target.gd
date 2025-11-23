extends Node3D

@export var move_speed: float = 5.0
@export var movement_enabled: bool = true
@export var camera: PhantomCamera3D
@export var mouse_sensitivity: float = 0.05

@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var min_yaw: float = 0
@export var max_yaw: float = 360

const KEY_STRINGNAME: StringName = "Key"
const ACTION_STRINGNAME: StringName = "Action"

const INPUT_MOVE_UP_STRINGNAME: StringName = "move_up"
const INPUT_MOVE_DOWM_STRINGNAME: StringName = "move_down"
const INPUT_MOVE_LEFT_STRINGNAME: StringName = "move_left"
const INPUT_MOVE_RIGHT_STRINGNAME: StringName = "move_right"

var InputMovementDic: Dictionary = {
	INPUT_MOVE_UP_STRINGNAME: {
		KEY_STRINGNAME: KEY_W,
		ACTION_STRINGNAME: INPUT_MOVE_UP_STRINGNAME
	},
	INPUT_MOVE_DOWM_STRINGNAME: {
		KEY_STRINGNAME: KEY_S,
		ACTION_STRINGNAME: INPUT_MOVE_DOWM_STRINGNAME
	},
	INPUT_MOVE_LEFT_STRINGNAME: {
		KEY_STRINGNAME: KEY_A,
		ACTION_STRINGNAME: INPUT_MOVE_LEFT_STRINGNAME
	},
	INPUT_MOVE_RIGHT_STRINGNAME: {
		KEY_STRINGNAME: KEY_D,
		ACTION_STRINGNAME: INPUT_MOVE_RIGHT_STRINGNAME
	},
}

func _ready() -> void:
	for input in InputMovementDic:
		var key_val = InputMovementDic[input].get(KEY_STRINGNAME)
		var action_val = InputMovementDic[input].get(ACTION_STRINGNAME)

		var movement_input = InputEventKey.new()
		movement_input.physical_keycode = key_val
		InputMap.add_action(action_val)
		InputMap.action_add_event(action_val, movement_input)

func _process(delta: float) -> void:
	if not self.movement_enabled: return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir: Vector2 = Input.get_vector(
		INPUT_MOVE_LEFT_STRINGNAME,
		INPUT_MOVE_RIGHT_STRINGNAME,
		INPUT_MOVE_UP_STRINGNAME,
		INPUT_MOVE_DOWM_STRINGNAME
	)

	var direction: Vector3 = (self.camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		var move_dir: Vector3 = Vector3.ZERO
		move_dir.x = direction.x
		move_dir.z = direction.z

		move_dir = move_dir.rotated(Vector3.UP, self.camera.rotation.y).normalized()
		self.translate(move_dir * self.move_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if self.camera.get_follow_mode() == self.camera.FollowMode.THIRD_PERSON:
		self._set_pcam_rotation(self.camera, event)
	
func _set_pcam_rotation(pcam: PhantomCamera3D, event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MouseButtonMask.MOUSE_BUTTON_MASK_LEFT == 0:
			return
		
		var pcam_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		pcam_rotation_degrees = pcam.get_third_person_rotation_degrees()

		# Change the X rotation
		pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Clamp the rotation in the X axis so it go over or under the target
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)
		
		# Change the SpringArm3D node's rotation and rotate around its target
		pcam.set_third_person_rotation_degrees(pcam_rotation_degrees)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var length = pcam.get_spring_length()
			pcam.set_spring_length(max(1.0, length - 0.1))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var length = pcam.get_spring_length()
			pcam.set_spring_length(min(50.0, length + 0.1))
