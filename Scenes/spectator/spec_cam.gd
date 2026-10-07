#Thanks to https://www.youtube.com/watch?v=VvTLP3neEbg for the code!!
extends Camera3D

@export var head_cam: XRCamera3D
@export_range(0.01, 1.0, 0.01, "suffix:s") var delay: float = 0.1

var prev_transform: Transform3D = Transform3D()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if head_cam:
		prev_transform = head_cam.transform
	print(XRServer.get_interface(1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var xr_interface = XRServer.find_interface("OpenXR")
	if not head_cam or xr_interface.is_initialized() == false: #if head cam no longer exists, STOP!!
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_dir.length() > 0:
			noclip_forward(input_dir, delta)
		return
	
	var adjusted_transform: Transform3D = head_cam.transform
	
	adjusted_transform.basis = Basis.looking_at(adjusted_transform.basis.z, Vector3.UP, true)
	
	adjusted_transform.basis = prev_transform.basis.slerp(adjusted_transform.basis, delta/delay)
	adjusted_transform.origin = prev_transform.origin.lerp(adjusted_transform.origin, delta/delay)
	
	global_transform = head_cam.get_parent().global_transform * adjusted_transform
	
	prev_transform = adjusted_transform

func noclip_forward(input_dir, delta):
	var forward = -global_transform.basis.z
	var right = -global_transform.basis.x     

	var move_dir = (right * input_dir.x + forward * input_dir.y).normalized()
	position.x += -move_dir.x * 1/5
	position.z += -move_dir.z * 1/5
	position.y += -move_dir.y * 1/5
