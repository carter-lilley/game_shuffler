extends Control

@onready var sound_player = $AudioStreamPlayer2D
@onready var time_label = $HBoxContainer/VBoxContainer/Label
@onready var btn_start = $HBoxContainer/VBoxContainer/HBoxContainer/Start
@onready var btn_pause = $HBoxContainer/VBoxContainer/HBoxContainer/Pause

@onready var icon_play = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
@onready var icon_pause = preload("res://Sprites/ui_icons/1x/pause.png")

var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")

var system_list: PackedStringArray
var prc_list: Array 
var prc_blank : Dictionary = {
	"name": "",
	"plat": "",
	"args": PackedStringArray(),
	"pid": 0,
	"active": false
}

func _ready() -> void:
	system_list = exclude_sys(globals.dir_contents(usersettings.rom_dir), ["gc", "n3ds","ps2","ps3","psvita","switch","wii","wiiu", "xbox", "xbox360"])
	for i in range(usersettings.bag_size):
		var entry = rollGame()
		prc_list.append(entry)
	print(prc_list)

func rerollGame(i : int):
	print("Rerolling ", prc_list[i]["name"],"...new result:")
	if i < 0 or i >= prc_list.size():
		print("Reroll index out of bounds.")
		return
	var new_game = rollGame()
	prc_list[i] = new_game
	print(prc_list[i])

func rollGame() -> Dictionary:
	var curr_sys: String = globals.rand_string(system_list)
	var curr_sys_dir: String = usersettings.rom_dir + "\\" + curr_sys
	var curr_core = match_core(curr_sys)
	var games_arr: PackedStringArray = DirAccess.get_files_at(curr_sys_dir)
	var curr_game: String = globals.rand_string(games_arr)
	var args: PackedStringArray = ["-L" , usersettings.ra_cores_dir + curr_core , usersettings.rom_dir + "\\" + curr_sys + "\\" + curr_game]
#	Create new dictionary (Process entry)
	var newGame: Dictionary = {}
	newGame["name"] = globals.sanitize_string(curr_game)
	newGame["plat"] = curr_sys
	newGame["args"] = args
	newGame["pid"] = 0
	newGame["active"] = false
	return newGame

var curr_timer: Timer
func _process(delta: float) -> void:
	if curr_timer:
		time_label.text = str(round(curr_timer.time_left))

var last_pid : int = -1
func startGame(id : int):
	sound_player.play()
	print("Current game: ",prc_list[id]["name"]," Current_ID: ", id, " Last_PID: ", last_pid)
	suspendPrc(last_pid) 
	#loop through and suspend matching PRCs (Update active status, etc)
	#Find the current process. if this process is new, create & assign it - else, resume it
	var curr_prc = prc_list[id]
	if curr_prc["pid"] == 0:
		curr_prc["pid"] = OS.create_process(usersettings.ra, curr_prc["args"])
		if curr_prc["pid"] != 0:
			curr_prc["active"] = true
			print("Creating Process: ", curr_prc["pid"])
			var game_qry = await IGDB.query_game(prc_list[id]["name"],prc_list[id]["plat"])
			if game_qry["name"] == "":
				notifman.notif_intro(game_qry["tex"], prc_list[id]["name"], str(prc_list[id]["plat"]), str(game_qry["release"]))
			else:
				notifman.notif_intro(game_qry["tex"], game_qry["name"], str(prc_list[id]["plat"]), str(game_qry["release"]))
		else:
			print("Failed to create new process.")
	else:
		resumePrc(id)
	last_pid = prc_list[id]["pid"]
	bringtofront(prc_list[id]["pid"])
	var new_id = randi() % usersettings.bag_size
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),startGame, new_id)

func resumePrc(pid):
	if !prc_list[pid]["active"]:
		prc_list[pid]["active"] = true
		var resume = PackedStringArray(["-r", prc_list[pid]["pid"]])
		var result = OS.execute(pssuspend_path,resume, [], true)
		if result != OK:
			print("Failed to resume process: ", prc_list[pid]["pid"])
		else:
			print("Resuming Process: ", prc_list[pid]["pid"])

func suspendPrc(pid):
	for prc_info in prc_list:
		if prc_info["pid"] == pid:
			prc_info["active"] = false
			var suspend = PackedStringArray([pid])
			var result = OS.execute(pssuspend_path,suspend, [], true)
			if result != OK:
				print("Failed to suspend process: ", prc_info["pid"])
			else:
				print("Suspending Process: ", prc_info["pid"])

func _toggled(on: bool) -> void:
	if on:
		btn_start.icon = icon_stop
		var new_id = randi() % usersettings.bag_size
		startGame(new_id)
	else:
		btn_start.icon = icon_play
		shutdown()

func shutdown():
	for prc_info in prc_list:
		if prc_info["pid"] != 0:
			OS.kill(prc_info["pid"])
			print("Killed PID: ",prc_info["pid"])
	globals.timers_kill()
	
func _pause(state: bool) -> void:
	if state:
		btn_pause.icon = icon_play
	else:
		btn_pause.icon = icon_pause
	globals.timers_pause(state)

func _skip() -> void:
		var new_id: int
		# Loop until a valid new_id is found
		while true:
			new_id = randi() % usersettings.bag_size
			if prc_list[new_id]["pid"] != last_pid:
				break
		# Proceed with the new valid ID
		startGame(new_id)

func _remove() -> void:
	for i in range(prc_list.size()):
		var entry = prc_list[i]
		if entry.has("pid") and entry["pid"] == last_pid:
			OS.kill(last_pid)
			rerollGame(i)
			startGame(i)

func bringtofront(pid: int):
	var bringgtofront_path = ProjectSettings.globalize_path("res://tools/bringtofront.ps1")
	#print(bringgtofront_path)
	var args = [
		"-Command",
		"Set-ExecutionPolicy Bypass -Scope Process;",
		". " + bringgtofront_path + "; goto " + str(pid)
	]
	var output = []
	var exit_code = OS.execute("powershell.exe", args, output, true)
	print("Output:", output)  # Output array contains the entire shell output as a single String element

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
