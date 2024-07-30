extends Control

@onready var sound_player = $AudioStreamPlayer2D
@onready var btn_start = $HBoxContainer/VBoxContainer/HBoxContainer/Start

var system_list: PackedStringArray
var prc_list: Array 
func _ready() -> void:
	fill_prc_list(usersettings.bag_size)
	system_list = exclude_sys(globals.dir_contents(usersettings.rom_dir), ["gc", "n3ds","ps2","ps3","psvita","psx","switch","wii","wiiu", "xbox", "xbox360"])
	for i in range(usersettings.bag_size):
		var curr_sys: String = globals.rand_string(system_list)
		var curr_sys_dir: String = usersettings.rom_dir + "\\" + curr_sys
		
		var curr_core = match_core(curr_sys)
		
		var games_arr: PackedStringArray = DirAccess.get_files_at(curr_sys_dir)
		var curr_game: String = globals.rand_string(games_arr)
		prc_list[i]["name"] = globals.sanitize_string(curr_game)
		prc_list[i]["plat"] = curr_sys
		var args: PackedStringArray = ["-L" , usersettings.ra_cores_dir + curr_core , usersettings.rom_dir + "\\" + curr_sys + "\\" + curr_game]
		prc_list[i]["args"] = args
	#print(prc_list)

func nextGame(last_pid: int):
	sound_player.play()
	var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")
	var curr_id = randi() % usersettings.bag_size
	print("Current game: ",prc_list[curr_id]["name"]," Current_ID: ", curr_id, " Last_PID: ", last_pid)
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
				prc_info["pid"] = OS.create_process(usersettings.ra, prc_info["args"])
				if prc_info["pid"] != 0:
					prc_info["active"] = true
					print("Creating Process: ", prc_info["pid"])
					var game_qry = await IGDB.query_game(prc_list[curr_id]["name"],prc_list[curr_id]["plat"])
					if game_qry["name"] == "":
						notifman.notif_intro(game_qry["tex"], prc_list[curr_id]["name"], str(prc_list[curr_id]["plat"]), str(game_qry["release"]))
					else:
						notifman.notif_intro(game_qry["tex"], game_qry["name"], str(prc_list[curr_id]["plat"]), str(game_qry["release"]))
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
				else:
					pass
	#print(prc_list)
	last_pid = prc_list[curr_id]["pid"]
	bringWindowToFront(prc_list[curr_id]["pid"])
	globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),nextGame, last_pid)

@onready var icon_start = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
func _toggled(on: bool) -> void:
	if on:
		btn_start.icon = icon_stop
		nextGame(-1)
	else:
		btn_start.icon = icon_start
		shutdown()

func shutdown():
	for prc_info in prc_list:
		if prc_info["pid"] != 0:
			OS.kill(prc_info["pid"])
			print("Killed PID: ",prc_info["pid"])
	globals.kill_timers()
	
#------- UTILITY FUNCTIONS
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
			current_core = usersettings.core_3do
		"atari2600":
			current_core = usersettings.core_atari2600
		"atarilynx":
			current_core = usersettings.core_atarilynx
		"dos":
			current_core = usersettings.core_dos
		"dreamcast":
			current_core = usersettings.core_dreamcast
		"gamegear":
			current_core = usersettings.core_gamegear
		"gb":
			current_core = usersettings.core_gb
		"gba":
			current_core = usersettings.core_gba
		"gbc":
			current_core = usersettings.core_gbc
		"genesis":
			current_core = usersettings.core_genesis
		"mastersystem":
			current_core = usersettings.core_mastersystem
		"n64":
			current_core = usersettings.core_n64
		"nds":
			current_core = usersettings.core_nds
		"neogeo":
			current_core = usersettings.core_neogeo
		"nes":
			current_core = usersettings.core_nes
		"ngpc":
			current_core = usersettings.core_ngpc
		"psp":
			current_core = usersettings.core_psp
		"saturn":
			current_core = usersettings.core_saturn
		"sega32x":
			current_core = usersettings.core_sega32x
		"segacd":
			current_core = usersettings.core_segacd
		"sg1000":
			current_core = usersettings.core_sg1000
		"snes":
			current_core = usersettings.core_snes
		"tg16":
			current_core = usersettings.core_tg16
		"tgcd":
			current_core = usersettings.core_tgcd
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
