extends SubViewport

@export var fps_cap: float = 60.0
@onready var FPS_LIMIT = 1.0 / fps_cap
var accumulated: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if accumulated>=FPS_LIMIT:
		render_target_update_mode = SubViewport.UPDATE_ONCE
		accumulated = 0.0
	else:
		accumulated += delta
