extends Control

var data_folder = ""
var data_file: FileAccess


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var data_file = get_latest_play(data_folder)
	if data_file != null:
		var data = CsvParser.csv_to_dict(data_file.get_as_text())
		$VBoxContainer/Panel/VBoxContainer/Title.text = data.get("songs")[2].get("song_title")
		$VBoxContainer/Panel/VBoxContainer/TotalScore.text = "Score: " + data.get("songs")[2].get("total_score")
		$VBoxContainer/Panel/VBoxContainer/MaxCombo.text = "Combo: " + data.get("songs")[2].get("max_combo") + "/" + data.get("songs")[0].get("maximum_possible_combo")
		$VBoxContainer/Panel/VBoxContainer/Accuracy.text = "Accuracy: " + data.get("songs")[2].get("completion_rate")
		$VBoxContainer/Panel/VBoxContainer/Rank.text = "non"
		
		$UserBox/Username.text = "User: " + data.get("user_name")
		$UserBox/SessionTime.text = "Time: " + data.get("play_time")

func get_latest_play(path: String) -> FileAccess:
	var dir: DirAccess = DirAccess.open(data_folder)
	var times: Dictionary
	if path != "":
		for file in dir.get_files():
			if file.contains("Header") or not file.contains("_"): #if this file is the header OR contains no underscore, skip it
				continue
			var dt = file.split("_")[1].split(".")[0]
			var dt_arr = dt.split("")
			
			var dt_str = ""
			
			var idx = 0
			for i in range(4):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			dt_str = dt_str + "-"
			for x in range(2):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			dt_str = dt_str + "-"
			for x in range(2):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			dt_str = dt_str + "T"
			for x in range(2):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			dt_str = dt_str + ":"
			for x in range(2):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			dt_str = dt_str + ":"
			for x in range(2):
				dt_str = dt_str + dt_arr[idx]
				idx+=1
			times.set(Time.get_unix_time_from_datetime_string(dt_str), file)
		
		times.sort()
		
		var keys = times.keys()
		data_file = FileAccess.open(data_folder + "/" + times.get(keys[keys.size()-1]), FileAccess.READ)
		return data_file
	else:
		printerr("ERR: No data directory or invalid access. Disable the ranking board or add your game data directory.")
		return null
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
