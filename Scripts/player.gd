extends XROrigin3D

@onready var rhandphys: StaticBody3D = get_parent().get_node("RHandPhys")
@onready var lhandphys: StaticBody3D = get_parent().get_node("LHandPhys")
@onready var rhand = $RightHand
@onready var lhand = $LeftHand
const MAX_DESYNC_DISTANCE: float = 0.5

var rhandprev: Vector3
var lhandprev: Vector3

func _ready() -> void:
	get_viewport().use_xr = true
	GlobalSignal.touch_hit.connect(_on_touch_hit)


func _on_touch_hit(side):
	if side == 0:
		rhand.trigger_haptic_pulse("haptic", 0, 1.0, -1, 0.0)
	else:
		lhand.trigger_haptic_pulse("haptic", 0, 1.0, -1, 0.0)

func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	GlobalSignal.request_movement.emit(rhandphys, rhand.global_position)
	GlobalSignal.request_movement.emit(lhandphys, lhand.global_position)
	lhandprev = lhandphys.global_position
	rhandprev = rhandphys.global_position
	
func follow(body: RigidBody3D, target: Node3D, delta: float) -> void:
	var pos_diff: Vector3 = target.global_position - body.global_position
	
	if pos_diff.length() > MAX_DESYNC_DISTANCE:
		body.global_transform = target.global_transform
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		return
	
	body.linear_velocity = pos_diff / delta
	
	var q_current: Quaternion = body.global_basis.get_rotation_quaternion()
	var q_target: Quaternion = target.global_basis.get_rotation_quaternion()
	var q_diff: Quaternion = q_target * q_current.inverse()
	
	var angle: float = q_diff.get_angle()
	if angle > PI:
		angle -= TAU
	
	if not is_zero_approx(angle):
		body.angular_velocity = q_diff.get_axis().normalized() * (angle / delta)
	else:
		body.angular_velocity = Vector3.ZERO



func _on_right_hand_input_vector_2_changed(action_name: String, value: Vector2) -> void:
	print(action_name)
	if action_name == "primary":
		global_position.x += value.x/32
		global_position.z += -value.y/32


func _on_left_hand_input_vector_2_changed(action_name: String, value: Vector2) -> void:
	if action_name == "primary":
		rotation.y += -value.x/32
