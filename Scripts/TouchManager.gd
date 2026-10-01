extends Node3D

var hitboxes: Array[MeshInstance3D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			hitboxes.append(child)
	
	for hitbox in hitboxes:
		pass
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
