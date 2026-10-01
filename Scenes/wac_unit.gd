extends Node3D


@onready var cap: WindowCapture = $Body/Screen/WindowCapture
@onready var mesh: MeshInstance3D = $Body/Screen
@onready var viewp: SubViewport = $SubViewport
@onready var texr: TextureRect = $SubViewport/TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cap.window_title = "Mercury"


var frame_counter = 0
const FRAME_DELAY = 2 

func _process(_delta: float) -> void:
	frame_counter += 1
	if frame_counter < FRAME_DELAY:
		return
	frame_counter = 0
	if cap.capture_frame():
		var curr_cap = cap.get_texture()
		var material = mesh.get_active_material(0)
		material.set_shader_parameter("texture_emission", curr_cap)
		texr.texture = curr_cap
		var temp_cap = viewp.get_texture().get_image()
		var t = 1.0 - exp(-4.0 * _delta)
		print(temp_cap.get_pixelv(Vector2i(0,0)))
		$Light1.light_color = $Light1.light_color.lerp(temp_cap.get_pixelv(Vector2i(0,0)), t)
		$Light2.light_color = $Light2.light_color.lerp(temp_cap.get_pixelv(Vector2i(1,0)), t)
		$Light3.light_color = $Light3.light_color.lerp(temp_cap.get_pixelv(Vector2i(1,1)), t)
		$Light4.light_color = $Light4.light_color.lerp(temp_cap.get_pixelv(Vector2i(0,1)), t)

func _on_card_trigger_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		KeyManager.PressKey(0x0D)


func _on_card_trigger_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		KeyManager.ReleaseKey(0x0D)


func _on_coin_trigger_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		IPCManager.SetCoinButton(true)
	


func _on_coin_trigger_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		IPCManager.SetCoinButton(false)
