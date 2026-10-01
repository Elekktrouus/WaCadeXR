#Thanks to https://www.youtube.com/watch?v=VvTLP3neEbg for the code!!
extends Camera3D

@export var head_cam: XRCamera3D
@export_range(0.01, 1.0, 0.01, "suffix:s") var delay: float = 0.1

var prev_transform: Transform3D = Transform3D()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if head_cam:
		prev_transform = head_cam.transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not head_cam: #if head cam no longer exists, STOP!!
		return
	
	var adjusted_transform: Transform3D = head_cam.transform
	
	adjusted_transform.basis = Basis.looking_at(adjusted_transform.basis.z, Vector3.UP, true)
	
	adjusted_transform.basis = prev_transform.basis.slerp(adjusted_transform.basis, delta/delay)
	adjusted_transform.origin = prev_transform.origin.lerp(adjusted_transform.origin, delta/delay)
	
	global_transform = head_cam.get_parent().global_transform * adjusted_transform
	
	prev_transform = adjusted_transform
