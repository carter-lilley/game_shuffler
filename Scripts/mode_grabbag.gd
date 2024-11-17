extends Control
# Need file type checks
@onready var sound_player = $AudioStreamPlayer2D
@onready var time_label = $HBoxContainer/VBoxContainer/Label
@onready var btn_start = $HBoxContainer/VBoxContainer/HBoxContainer/Start
@onready var btn_pause = $HBoxContainer/VBoxContainer/HBoxContainer/Pause

@onready var icon_play = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
@onready var icon_pause = preload("res://Sprites/ui_icons/1x/pause.png")

var sfk_path = ProjectSettings.globalize_path("res://tools/sfk.exe")
var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")

var active_systems : PackedStringArray
var game_list: Array 
var game_blank : Dictionary = {
	"name": "",
	"plat": "",
	"args": PackedStringArray(),
	"started": false
}

func _ready() -> void:
	randomize()

func get_active_systems(system_list: Dictionary) -> Array:
	var active_systems = []
	for system_name in system_list:
		if system_list[system_name].get("state", false):  # default to false if "state" key is missing
			active_systems.append(system_name)
	return active_systems

func set_entries():
	active_systems = get_active_systems(usersettings.system_dictionary)
	for i in range(usersettings.bag_size):
		var entry = rollGame()
		game_list.append(entry)
	print(game_list)

func rerollGame(i : int):
	print("Rerolling ", game_list[i]["name"],"...new result:")
	if i < 0 or i >= game_list.size():
		print("Reroll index out of bounds.")
		return
	var new_game = rollGame()
	game_list[i] = new_game
	print(game_list[i])

func rollGame() -> Dictionary:
	var newGame: Dictionary = {}
	# Create paths
	var sys: String = globals.rand_string(active_systems)
	var sys_dir: String = usersettings.rom_dir + "\\" + sys
	var games_arr: PackedStringArray = DirAccess.get_files_at(sys_dir)
	var game_name_raw: String = globals.rand_string(games_arr)
	var game_dir: String = usersettings.rom_dir + "\\" + sys + "\\" + game_name_raw
	# Sanitize game name and check for duplicates
	var game_name: String = globals.sanitize_string(game_name_raw)
	for game in game_list:
		if game["name"] == game_name:
			print("Duplicate game found: ", game_name, " Rerolling...")
			return rollGame()  # Recursively re-call rollGame if a duplicate is found
	# Create empty game dictionary and argument reference
	var game_core = match_core(sys)
	newGame["name"] = game_name
	newGame["started"] = false
	newGame["args"] = ["-L" , usersettings.ra_cores_dir + game_core, game_dir]
	newGame["plat"] = sys
	return newGame

var curr_timer: Timer
func _process(_delta: float) -> void:
	if is_instance_valid(curr_timer):
		time_label.text = str(round(curr_timer.time_left))

var pid : int = -1
var curr_id: int = -1
func startGame(id : int):
	# Set curr_id to the selected id right before starting the game
	curr_id = id
	var load_screen = notifman.notif_load()
	load_screen.close()
	sound_player.play()
	print("NEW GAME START!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("Current game: ",game_list[id]["name"]," Current_ID: ", id)
# Safe quit RA via UDP command (Save & quit)
	var ra_safe_quit_args : PackedStringArray = [
	"udpsend", "localhost", "55355", "QUIT"
	]
	var result_0 = OS.execute(sfk_path, ra_safe_quit_args, [], true)
	await get_tree().create_timer(0.5).timeout
	var result_1 = OS.execute(sfk_path, ra_safe_quit_args, [], true)
# Load game
	pid = OS.create_process(usersettings.ra_local, game_list[id]["args"])
	await get_tree().create_timer(0.5).timeout
# If game is new, query game information
	if !game_list[id]["started"]:
		var game_qry = await IGDB.query_game(game_list[id]["name"], game_list[id]["plat"])
		var game_name = game_qry["name"]
		if game_name == "":
			notifman.notif_intro(game_qry["tex"], game_list[id]["name"], str(game_list[id]["plat"]), str(game_qry["release"]))
		else:
			notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game_list[id]["plat"]), str(game_qry["release"]))
	game_list[id]["started"] = true
# End the loading screen and bring the new prc to front
	load_screen.open()
	#bringtofront(pid)
# Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
	var next_id = newId()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),startGame, next_id)

func _toggled(on: bool) -> void:
	if on:
		set_entries()
		btn_start.icon = icon_stop
		startGame(newId())
	else:
		var accept_diag = AcceptDialog.new()
		accept_diag.dialog_text = "Stop and close all processes?"
		accept_diag.connect("confirmed", _diag_confirm.bind(accept_diag))
		accept_diag.connect("canceled", _diag_cancel.bind(accept_diag))
		notifman.notif_start()
		add_child(accept_diag)
		accept_diag.popup_centered()

func _diag_cancel(_box : AcceptDialog):
	btn_start.set_pressed_no_signal(true)
	btn_start.icon = icon_stop
	notifman.notif_compelte(_box)
	
func _diag_confirm(_box : AcceptDialog):
	btn_start.set_pressed_no_signal(false)
	btn_start.icon = icon_play
	shutdown()
	notifman.notif_compelte(_box)

func shutdown():
	OS.kill(pid)
	print("Killed PID: ",pid)
	globals.timers_kill()
	
func _pause(state: bool) -> void:
	if state:
		btn_pause.icon = icon_play
	else:
		btn_pause.icon = icon_pause
	globals.timers_pause(state)

func newId() -> int:
	var new_id = randi() % usersettings.bag_size
	while new_id == curr_id:
		new_id = randi() % usersettings.bag_size
	print("Current id: ", curr_id, "Next id: ", new_id)
	return new_id
	
func _skip() -> void:
	globals.timers_kill()
	startGame(newId())

func _remove() -> void:
	OS.kill(pid)
	globals.timers_kill()
	rerollGame(curr_id)
	startGame(curr_id)

func _on_settings_pressed() -> void:
	var menu = notifman.notif_settings(self)
	
func bringtofront(pid: int):
	var bringgtofront_path = ProjectSettings.globalize_path("res://tools/switchtowindow.ps1")
	#print(bringgtofront_path)
	var args = [
		"-Command",
		"Set-ExecutionPolicy Bypass -Scope Process;",
		". " + bringgtofront_path + "; goto " + str(pid)
	]
	var output = []
	OS.execute("powershell.exe", args, output, true)
	print("Bring to front output:", output)  # Output array contains the entire shell output as a single String element

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
		"gc":
			current_core = usersettings.core_gc
		"gb":
			current_core = usersettings.core_gb
		"gba":
			current_core = usersettings.core_gba
		"gbc":
			current_core = usersettings.core_gbc
		"genesis":
			current_core = usersettings.core_genesis
		"mame":
			current_core = usersettings.core_mame
		"mastersystem":
			current_core = usersettings.core_mastersystem
		"n3ds":
			current_core = usersettings.core_n3ds
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
		"ps2":
			current_core = usersettings.core_ps2
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
		"wii":
			current_core = usersettings.core_wii
		"win3x":
			current_core = usersettings.core_dos
		"c64":
			current_core = usersettings.core_c64
		"msx":
			current_core = usersettings.core_msx
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
