extends Area3D
@export var id: int = 0

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		if body.name == "RHandPhys":
			GlobalSignal.touch_hit.emit(0)
		else:
			GlobalSignal.touch_hit.emit(1)
		
		UmiKbManager.press_key(32 + id)


func _on_body_exited(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		
		UmiKbManager.release_key(32 + id)
