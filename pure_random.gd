extends Button

@onready var user_settings = $"../../../user_settings"
var round_time : float = 180.0

var system_list: PackedStringArray
func _ready() -> void:
	system_list = exclude_sys(dir_contents(user_settings.rom_dir), ["gc", "n3ds","ps2","ps3","psvita","psx","switch","wii","wiiu", "xbox", "xbox360"])
	
func _on_pressed() -> void:
	nextGame(null)
	pass # Replace with function body.

func nextGame(pid):
	if pid:
		OS.kill(pid)
		
	var curr_sys: String = rand_string(system_list)
	var curr_sys_dir: String = user_settings.rom_dir + "\\" + curr_sys
	print (curr_sys)
	
	var curr_core = match_core(curr_sys)
	print (curr_core)
	
	var games_arr: PackedStringArray = DirAccess.get_files_at(curr_sys_dir)
	var curr_game: String = rand_string(games_arr)
	print (curr_game)
	
	var args: PackedStringArray = ["-L" , user_settings.ra_cores_dir + curr_core , user_settings.rom_dir + "\\" + curr_sys + "\\" + curr_game]
	print (args)
	pid = OS.create_process(user_settings.ra, args)
	create_timer(randf_range(user_settings.round_time_min, user_settings.round_time_max),nextGame, pid)

#------- FUNCTIONS

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
		else:
			print("Excluded: " + dir_arr[i-1])
	return trimmed_arr

func rand_string(dir_arr: PackedStringArray) -> String:
	var rand_string: String = dir_arr[randi() % dir_arr.size()]
	return rand_string

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
				print("Found dir: " + entry)
			else:
				print("Found file: " + entry)
			entry = dir.get_next()
		return dir_arr
	else:
		print("An error occurred when trying to access the path.")
		return dir_arr
