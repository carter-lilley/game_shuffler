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
	system_list = exclude_sys(globals.dir_contents(usersettings.rom_dir), ["ps4","ps3","psvita"])
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
	var newGame: Dictionary = {}
	# Create paths
	var sys: String = globals.rand_string(system_list)
	var sys_dir: String = usersettings.rom_dir + "\\" + sys
	var games_arr: PackedStringArray = DirAccess.get_files_at(sys_dir)
	var game: String = globals.rand_string(games_arr)
	var game_dir: String = usersettings.rom_dir + "\\" + sys + "\\" + game
	# Create empty process and argument reference
	var prc: String
	var args: PackedStringArray = []
	match sys:
		"gc":
			prc = usersettings.dolphin_dir
			args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		"n3ds":
			prc = usersettings.citra_dir
			args = ["-f", "-g", game_dir]
		"ps2":
			prc = usersettings.pcsx2_dir
			args = ["-fullscreen" , game_dir]
		"ps3":
			prc = game_dir
			args = ["--fullscreen"]
		"psvita":
			prc = usersettings.vita3k_dir
		"switch":
			prc = usersettings.yuzu_dir
			args = ["-g" , game_dir, "-f"]
		"wii":
			prc = usersettings.dolphin_dir
			args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		"wiiu":
			prc = usersettings.cemu_dir
			args = ["-g" , game_dir, "-f"]
		"xbox":
			prc = usersettings.xemu_dir
			args = ["-full-screen","-dvd_path", game_dir]
		"xbox360":
			prc = usersettings.xenia_dir
			args = ["--fullscreen=true", game_dir]
		_:
			prc = usersettings.ra
			var curr_core = match_core(sys)
			args = ["-L" , usersettings.ra_cores_dir + curr_core , game_dir]
	newGame["name"] = globals.sanitize_string(game)
	newGame["plat"] = sys
	newGame["prc"] = prc
	newGame["args"] = args
	newGame["pid"] = 0
	newGame["active"] = false
	return newGame

var curr_timer: Timer
func _process(_delta: float) -> void:
	if is_instance_valid(curr_timer):
		time_label.text = str(round(curr_timer.time_left))

var last_pid : int = -1
func startGame(id : int):
	sound_player.play()
	print("Current game: ",prc_list[id]["name"]," Current_ID: ", id, " Last_PID: ", last_pid)
	await suspendPrc(last_pid) 
	var curr_prc = prc_list[id]
	if curr_prc["pid"] == 0:
		curr_prc["pid"] = OS.create_process(curr_prc["prc"], curr_prc["args"])
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
		pass
		resumePrc(id)
	last_pid = prc_list[id]["pid"]
	bringtofront(prc_list[id]["pid"])
	if is_instance_valid(curr_timer):
		curr_timer.stop()
	var next_id = newId()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),startGame, next_id)

func resumePrc(id):
	if !prc_list[id]["active"]:
		prc_list[id]["active"] = true
		var resume = PackedStringArray(["-r", prc_list[id]["pid"]])
		var result = OS.execute(pssuspend_path,resume, [], true)
		if result != OK:
			print("Failed to resume process: ", prc_list[id]["pid"])
		else:
			print("Resuming Process: ", prc_list[id]["pid"])

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
		startGame(newId())
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

func newId() -> int:
	var new_id: int
	while true:
		new_id = randi() % usersettings.bag_size
		if prc_list[new_id]["pid"] != last_pid:
			return new_id
	return -1
	
func _skip() -> void:
	startGame(newId())

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
	OS.execute("powershell.exe", args, output, true)
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
		"psx":
			current_core = usersettings.core_psx
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
