extends XROrigin3D

@onready var rhandphys: RigidBody3D = get_parent().get_node("RHandPhys")
@onready var lhandphys: RigidBody3D = get_parent().get_node("LHandPhys")
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
	follow(rhandphys, rhand, delta)
	follow(lhandphys, lhand, delta)
	
	#fix_collision(rhandphys, rhandprev)
	#fix_collision(lhandphys, lhandprev)
	
	lhandprev = lhandphys.global_position
	rhandprev = rhandphys.global_position
	
	
	
func fix_collision(node: Node3D, prevpos: Vector3) -> bool:
	var testray = RayCast3D.new()
	get_tree().current_scene.add_child(testray)
	testray.global_position = node.global_position
	testray.target_position = testray.to_local(prevpos)
	testray.force_raycast_update()
	var collider = testray.get_collider()
	if collider != null and collider is StaticBody3D:
		print("illegal collision detected, snapping pos")
		node.global_position = prevpos
		testray.queue_free()
		return false
	if collider != null: print(collider)
	testray.queue_free()
	return true
	
	

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
