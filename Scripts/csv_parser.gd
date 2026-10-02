extends Node



var data_dict: Dictionary = {
	"keychip_number" : 0,
	"session_date" : 0,
	"game_version" : "default",
	"user_name" : "default",
	"play_time" : 0,
	"gamemode" : 0,
	"playmode" : 0,
	"tutorial" : false,
	"coin_credits" : 0,
	"service_credits" : 0,
	"songs" : []
}

var song_dict: Dictionary = {
	"song_id" : 0,
	"song_title" : "default",
	"difficulty" : 1, #int from 1-4
	"difficulty_simple" : "1+", #Whats shown in the level select
	"clear_status" : false, #int either 0 or 1
	"bg_video" : "default",
	"score" : 0,
	"combo_bonus" : 0,
	"completion_rate_bonus" : 0,
	"total_score" : 0,
	"completion_rate" : 0,
	"clear_rate" : 0,
	"rate_points" : 0,
	"marv_count" : 0,
	"great_count" : 0,
	"good_count" : 0,
	"miss_count" : 0,
	"marv_bonus_count" : 0,
	"great_bonus_count" : 0,
	"good_bonus_count" : 0,
	"miss_bonus_count" : 0,
	"total_bonus_notes" : 0,
	"max_combo" : 0,
	"maximum_possible_combo" : 0,
	"high_speed" : 0,
	"mask" : 0
}

func csv_to_dict(content: String) -> Dictionary:
	var temp_arr = content.split(",")
	var final_dict = data_dict.duplicate()
	var final_keys = data_dict.keys()
	
	var idx = 0
	for i in temp_arr:
		if idx > 9:
			break
		final_dict.set(final_keys[idx], i)
		idx+=1
	#finished processing the beginning, move on to songs
	var song_keys = song_dict.keys()
	var song_arr = []
	
	for song in range(3):
		var song_idx = 0
		var curr_song_dict = song_dict.duplicate()
		for i in range(idx, idx+song_dict.size()): #start at the next position, end at the position PLUS the size of a song
			curr_song_dict.set(song_keys[song_idx], temp_arr[idx])
			song_idx+=1
			idx+=1
		song_arr.append(curr_song_dict)
	final_dict.set("songs", song_arr)

	return final_dict
