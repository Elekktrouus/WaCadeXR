extends Area3D

@export var zone: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		if body.name == "RHandPhys":
			GlobalSignal.touch_hit.emit(0)
		else:
			GlobalSignal.touch_hit.emit(1)
		
		IPCManager.SetTouch(zone, true)


func _on_body_exited(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		IPCManager.SetTouch(zone, false)
