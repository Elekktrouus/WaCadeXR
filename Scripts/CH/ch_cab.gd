extends Node3D

@onready var cap: WindowCapture = $CabDisplay/WindowCapture
@onready var mesh: MeshInstance3D = $CabDisplay
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cap.window_title = "UMIGURI"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cap.capture_frame():
		var curr_cap = cap.get_texture()
		var material = mesh.get_active_material(0)
		material.set_shader_parameter("texture_emission", curr_cap)
