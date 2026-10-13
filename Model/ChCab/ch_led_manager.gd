extends Node3D


var mats: Array[StandardMaterial3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.set_led.connect(update_leds)
	for light : MeshInstance3D in get_children():
		var mat = light.get_active_material(0).duplicate()
		mats.append(mat)
		light.material_override = mat


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_leds(data: PackedByteArray):
	#print(data)
	var idx = 0
	var lightidx = 0
	print(get_children().size())
	print(data)
	for i in range (get_children().size()/2):
		var light = get_child(i)
		var mat = light.get_active_material(0)
		var col = Color8(data[idx], data[idx+1], data[idx+2])
		set_led(light, col, lightidx)
		set_led(light, col, get_children().size() - 1 - lightidx)
		idx+=3
		lightidx+=1
		
		
		
			
func set_led(light : MeshInstance3D, col : Color, matidx : int):
	mats[matidx].emission = Color(col, 255)
