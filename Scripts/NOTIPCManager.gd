extends Node
# Register this as an Autoload named "IPCManager" (Project Settings > Globals).
# Don't add class_name here: it would clash with the autoload name.

const SharedMemoryScript := preload("res://SharedMemory.cs")

const SHARED_MEMORY_NAME := "Local\\WACVR_SHARED_BUFFER"
const SHARED_MEMORY_SIZE := 2164


# Buffer layout
const TOUCH_OFFSET := 4      # 240 bytes, Godot -> external program
const TOUCH_COUNT := 240
const LIGHT_OFFSET := 244    # 1920 bytes, external program -> Godot
const LIGHT_BYTES := 1920
const LIGHT_FLAG_OFFSET := LIGHT_OFFSET + 3  # alpha of first pixel = "active" flag
var light_buffer := PackedByteArray()

var shared_buffer: RefCounted = null
var is_initialized := false
var touch_data := PackedByteArray()


func _ready() -> void:
	light_buffer.resize(LIGHT_BYTES)
	touch_data.resize(TOUCH_COUNT)  # zero-filled = all false
	_ensure_initialization()


func _exit_tree() -> void:
	print("Disposing IPC")
	_dispose()


func _ensure_initialization() -> void:
	if not is_initialized:
		_initialize_ipc(SHARED_MEMORY_NAME, SHARED_MEMORY_SIZE)


func _initialize_ipc(shared_memory_name: String, shared_memory_size: int) -> void:
	var buffer = SharedMemoryScript.new()
	if buffer.Open(shared_memory_name, shared_memory_size):
		shared_buffer = buffer
		is_initialized = true
	else:
		shared_buffer = null
		is_initialized = false


func _reconnect() -> void:
	_initialize_ipc(SHARED_MEMORY_NAME, SHARED_MEMORY_SIZE)


func _reconnect_wait() -> void:
	await get_tree().create_timer(5.0).timeout
	_reconnect()


func get_light_data() -> PackedByteArray:
	_ensure_initialization()
	if shared_buffer == null:
		return PackedByteArray()
	return shared_buffer.ReadBytes(LIGHT_OFFSET, LIGHT_BYTES)


func _dispose_wait() -> void:
	if shared_buffer == null:
		return
	shared_buffer.WriteByte(LIGHT_FLAG_OFFSET, 0)  # clear the flag
	await get_tree().create_timer(0.1).timeout      # wait in case the IPC is still in use
	if shared_buffer == null:
		return
	var flag: int = shared_buffer.ReadBytes(LIGHT_FLAG_OFFSET, 1)[0]
	if flag == 0:
		_dispose()


func _dispose() -> void:
	if shared_buffer != null:
		shared_buffer.Close()
		shared_buffer = null
		is_initialized = false
	print("IPC Disposed")


func _set_touch_data(data: PackedByteArray) -> void:
	_ensure_initialization()
	if shared_buffer != null:
		shared_buffer.WriteBytes(TOUCH_OFFSET, data)


func set_touch(area: int, state: bool) -> void:
	area -= 1  # 0-239
	var value := 1 if state else 0

	if area < 120:    # right side
		touch_data[area + 120] = value
	else:             # left side
		touch_data[area - 120] = value

	_set_touch_data(touch_data)
