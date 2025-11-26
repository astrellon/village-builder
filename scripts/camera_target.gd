extends Node3D

@export var move_speed: float = 5.0
@export var movement_enabled: bool = true
@export var camera: PhantomCamera3D

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
