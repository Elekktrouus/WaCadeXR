extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var panel = preload("res://Scenes/touch_panel.tscn")
	for i in get_children():
		if i is MeshInstance3D:
			var panel_instance = panel.instantiate()
			panel_instance.zone = int(i.name)
			i.add_child(panel_instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
