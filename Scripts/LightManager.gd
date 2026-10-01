extends Node
class_name LightManager

@export var lights: Array[MeshInstance3D] = []
@export var fade_duration: float = 0.5
@export var use_ipc_lighting: bool = true

const BYTES_PER_PIXEL := 4
const EXPECTED_BYTES := 1920

var is_ipc_idle: bool = true
var materials: Array[StandardMaterial3D] = []
var fade_tweens: Dictionary = {}

var led_timer: float = 0.0
const LED_INTERVAL: float = 1.0 / 60.0

var last_data: PackedByteArray = PackedByteArray()


func _ready() -> void:
	lights.clear()
	materials.clear()
	
	for child in get_children():
		if child is MeshInstance3D:
			lights.append(child)
			var base_mat = child.get_active_material(0)
			var mat: StandardMaterial3D = base_mat.duplicate() if base_mat else StandardMaterial3D.new()
			child.material_override = mat
			materials.append(mat)
			
	print("Lights contains ", lights.size(), " meshes.")


func _process(delta: float) -> void:
	if not use_ipc_lighting:
		is_ipc_idle = true
		return

	led_timer += delta
	if led_timer < LED_INTERVAL:
		return
	led_timer -= LED_INTERVAL

	var data: PackedByteArray = IPCManager.GetLightData()
	if data.size() < EXPECTED_BYTES:
		return

	is_ipc_idle = (data[3] == 0)
	if is_ipc_idle:
		return

	if data == last_data:
		return
	last_data = data

	update_led(data)


func update_led(data: PackedByteArray) -> void:
	var index = 0
	for i in 30:
		for ii in 4:
			_set_led(119 - i - ii * 30, data, index * 2)
			_set_led(210 + i - ii * 30, data, (index + 120) * 2)
			index += 1


func _set_led(material_index: int, data: PackedByteArray, pixel: int) -> void:
	var mat = materials[material_index]
	var o = pixel * BYTES_PER_PIXEL
	mat.emission = Color8(data[o], data[o + 1], data[o + 2], 255)
