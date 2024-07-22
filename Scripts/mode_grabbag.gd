extends Button

@onready var sound_player = $"../../../AudioStreamPlayer2D"
@onready var user_settings = $"../../../user_settings"

var system_list: PackedStringArray
var prc_list: Array 
func _ready() -> void:
	fill_prc_list(user_settings.bag_size)

	system_list = exclude_sys(dir_contents(user_settings.rom_dir), ["gc", "n3ds","ps2","ps3","psvita","psx","switch","wii","wiiu", "xbox", "xbox360"])
	for i in range(user_settings.bag_size):
		var curr_sys: String = rand_string(system_list)
		var curr_sys_dir: String = user_settings.rom_dir + "\\" + curr_sys
		
		var curr_core = match_core(curr_sys)
		
		var games_arr: PackedStringArray = DirAccess.get_files_at(curr_sys_dir)
		var curr_game: String = rand_string(games_arr)
		prc_list[i]["name"] = sanitize_string(curr_game)
		prc_list[i]["plat"] = curr_sys
		var args: PackedStringArray = ["-L" , user_settings.ra_cores_dir + curr_core , user_settings.rom_dir + "\\" + curr_sys + "\\" + curr_game]
		prc_list[i]["args"] = args
	#print(prc_list)
	
func _on_pressed() -> void:
	nextGame(-1)
	pass # Replace with function body.

func nextGame(last_pid: int):
	sound_player.play()
	var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")
	var curr_id = randi() % user_settings.bag_size
	print("Current game: ",prc_list[curr_id]["name"]," Current_ID: ", curr_id, " Last_PID: ", last_pid)
	var game_qry = await IGDB.query_game(prc_list[curr_id]["name"],prc_list[curr_id]["plat"])
	notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game_qry["id"]))
	for prc_info in prc_list:
	#suspend all active processes..
		if prc_info["pid"] == last_pid:
			prc_info["active"] = false
			var suspend = PackedStringArray([last_pid])
			var result = OS.execute(pssuspend_path,suspend, [], true)
			if result != OK:
				print("Failed to suspend process: ", prc_info["pid"])
			else:
				print("Suspending Process: ", prc_info["pid"])
	#find the current process. if this process is new, create & assign it - else, resume it
		if prc_info["id"] == curr_id:
			if prc_info["pid"] == 0:
				prc_info["pid"] = OS.create_process(user_settings.ra, prc_info["args"])
				if prc_info["pid"] != 0:
					prc_info["active"] = true
					print("Creating Process: ", prc_info["pid"])
				else:
					print("Failed to create new process.")
			else:
				if !prc_info["active"]:
					prc_info["active"] = true
					var resume = PackedStringArray(["-r", prc_info["pid"]])
					var result = OS.execute(pssuspend_path,resume, [], true)
					if result != OK:
						print("Failed to resume process: ", prc_info["pid"])
					else:
						print("Resuming Process: ", prc_info["pid"])
	#print(prc_list)
	last_pid = prc_list[curr_id]["pid"]
	bringWindowToFront(prc_list[curr_id]["pid"])
	create_timer(randf_range(user_settings.round_time_min, user_settings.round_time_max),nextGame, last_pid)

#------- FUNCTIONS
func fill_prc_list(x: int):
	for i in range(x):
		var prc_info = {
			"id": i,
			"name": "",
			"plat": "",
			"args": PackedStringArray(),
			"pid": 0,
			"active": false  # or false, depending on your initial state
		}
		prc_list.append(prc_info)

func sanitize_string(input: String) -> String:
	#print(input)
	# Remove text after period
	var sanitized_input = input.split(".")[0]  # Remove the period and everything after it
	sanitized_input = sanitized_input.strip_edges()  # Remove leading and trailing whitespace
	# Use a regular expression to remove text within parentheses
	var regex = RegEx.new()
	regex.compile("\\s*\\([^()]*\\)\\s*")  # Matches text within parentheses and surrounding spaces
	for i in 3:
		sanitized_input = regex.sub(sanitized_input, "")
	# Remove version numbers like "v1", "v2", "v3.0"
	regex.compile("\\bv\\d+(\\.\\d+)?\\b")  # Matches "v1", "v2.0", etc.
	sanitized_input = regex.sub(sanitized_input, "")
	# Escape quotes if necessary
	sanitized_input = sanitized_input.replace('"', '\\"')
	#print(sanitized_input)
	return sanitized_input

func bringWindowToFront(pid: int):
	var bringgtofront_path = ProjectSettings.globalize_path("res://tools/bringtofront.ps1")
	#print(bringgtofront_path)
	var args = [
		"-Command",
		"Set-ExecutionPolicy Bypass -Scope Process;",
		". " + bringgtofront_path + "; goto " + str(pid)
	]
	var output = []
	var exit_code = OS.execute("powershell.exe", args, output, true)
	if exit_code == 0:
		print("PowerShell script executed successfully.")
		print("Output:")
		print(output)  # Output array contains the entire shell output as a single String element
	else:
		print("Error executing PowerShell script.")
		print("Error Output:")
		print(output)  # Output array contains the error message if execution fails

func match_core(sys : String) -> String:
	var current_core: String
	match sys:
		"3do":
			current_core = user_settings.core_3do
		"atari2600":
			current_core = user_settings.core_atari2600
		"atarilynx":
			current_core = user_settings.core_atarilynx
		"dos":
			current_core = user_settings.core_dos
		"dreamcast":
			current_core = user_settings.core_dreamcast
		"gamegear":
			current_core = user_settings.core_gamegear
		"gb":
			current_core = user_settings.core_gb
		"gba":
			current_core = user_settings.core_gba
		"gbc":
			current_core = user_settings.core_gbc
		"genesis":
			current_core = user_settings.core_genesis
		"mastersystem":
			current_core = user_settings.core_mastersystem
		"n64":
			current_core = user_settings.core_n64
		"nds":
			current_core = user_settings.core_nds
		"neogeo":
			current_core = user_settings.core_neogeo
		"nes":
			current_core = user_settings.core_nes
		"ngpc":
			current_core = user_settings.core_ngpc
		"psp":
			current_core = user_settings.core_psp
		"saturn":
			current_core = user_settings.core_saturn
		"sega32x":
			current_core = user_settings.core_sega32x
		"segacd":
			current_core = user_settings.core_segacd
		"sg1000":
			current_core = user_settings.core_sg1000
		"snes":
			current_core = user_settings.core_snes
		"tg16":
			current_core = user_settings.core_tg16
		"tgcd":
			current_core = user_settings.core_tgcd
	return current_core

func exclude_sys(dir_arr: PackedStringArray, exclusion_arr: Array) -> PackedStringArray:
	print("Searching for exclusions..")
	var trimmed_arr: PackedStringArray = []
	for i in range(dir_arr.size()):
		var dir_name = dir_arr[i]
		if !exclusion_arr.has(dir_name):
			trimmed_arr.push_back(dir_name)
		#else:
			#print("Excluded: ", dir_name)
	return trimmed_arr

func rand_string(dir_arr: PackedStringArray) -> String:
	var _str: String = dir_arr[randi() % dir_arr.size()]
	return _str

func create_timer(secs: float, function: Callable, arg: Variant):
	var timer = Timer.new()
	timer.wait_time = secs
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)  # Add the timer as a child of the current node (assuming this is a Node or Control)
	# Connect the timeout signal to call the specified function
	timer.timeout.connect(function.bind(arg))
	return timer

func dir_contents(path) -> PackedStringArray:
	var dir = DirAccess.open(path)
	var dir_arr : PackedStringArray
	if dir:
		dir.list_dir_begin()
		var entry = dir.get_next()
		while entry != "":
			if dir.current_is_dir():
				dir_arr.append(entry)
				#print("Found dir: " + entry)
			#else:
				#print("Found file: " + entry)
			entry = dir.get_next()
		return dir_arr
	else:
		print("An error occurred when trying to access the path.")
		return dir_arr
