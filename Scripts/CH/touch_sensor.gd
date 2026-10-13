extends Area3D

@export_range(0,31) var key_index: int = 0

func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		UmiKbManager.press_key(key_index)


func _on_body_exited(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("Hand"):
		UmiKbManager.release_key(key_index)
