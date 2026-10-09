extends Node3D


@onready var cap: WindowCapture = $Body/Screen/WindowCapture
@onready var mesh: MeshInstance3D = $Body/Screen
@onready var viewp: SubViewport = $SubViewport
@onready var texr: TextureRect = $SubViewport/TextureRect
@onready var space_start: Node3D = $Body/Screen/PlayStart
@onready var depth_text = $Depth
@onready var rad_text = $Radius

@export var l_hand: RigidBody3D
@export var r_hand: RigidBody3D

var space_start_r = 0.28
var space_end_r = 0.42
var space_depth = 0.251

var hand_radii = 0.05 # make sure u update this if u ever change hand size


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.request_movement.connect(_on_request_movement)
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
		$Light1.light_color = $Light1.light_color.lerp(temp_cap.get_pixelv(Vector2i(0,0)), t)
		$Light2.light_color = $Light2.light_color.lerp(temp_cap.get_pixelv(Vector2i(1,0)), t)
		$Light3.light_color = $Light3.light_color.lerp(temp_cap.get_pixelv(Vector2i(1,1)), t)
		$Light4.light_color = $Light4.light_color.lerp(temp_cap.get_pixelv(Vector2i(0,1)), t)
		
		
func correct_pos(pos: Vector3) -> Vector3:
	var new_pos = space_start.to_local(pos)
	var depth_norm = clampf(new_pos.z/ 0.251, 0.0, 1.0)
	var dist_from_center = new_pos.distance_to(Vector3(0, 0, new_pos.z))+hand_radii
	var max_radius = snapped(lerp(space_start_r, space_end_r, depth_norm), 0.01)
	depth_text.text = "Z: " + str(snapped(depth_norm, 0.01))
	rad_text.text = "Radius: " + str(max_radius)
	var test_vec = Vector2(new_pos.x, new_pos.y)
	if dist_from_center > max_radius and depth_norm < 1.0 and dist_from_center < max_radius+1: #Ensure if you're far enough away, your hand gets freed
		var new_vec = test_vec * (max_radius / dist_from_center)
		var new_vec3 = space_start.to_global(Vector3(new_vec.x, new_vec.y, new_pos.z))
		
		return new_vec3 
	return pos #if we dont need to snap, return the input pos
	
	
func _on_request_movement(node: Node3D, pos: Vector3):
	# pos is where the node WANTS to move
	node.global_position = correct_pos(pos)
	

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
