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
	"emu": "",
	"pid": -1,
	"args": PackedStringArray(),
	"started": false,
	"active": false
}

func _ready() -> void:
	print("Ready...")
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
	var newGame: Dictionary = game_blank.duplicate()
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
	newGame["plat"] = sys
	var prc: String
	match sys:
		#"gc":
			#prc = usersettings.dolphin_dir
			#args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		#"n3ds":
			#prc = usersettings.lime3ds_dir
			#args = ["-f", "-g", game_dir]
		#"ps2":
			#prc = usersettings.pcsx2_dir
			#args = ["-fullscreen" , game_dir]
		#"ps3":
			#prc = usersettings.rpcs3_dir
			#var link_target = get_lnk_target(game_dir)
			#args = ["--fullscreen", "--no-gui", link_target]
		#"psvita":
			#prc = usersettings.vita3k_dir
			#var game_ID = FileAccess.open(game_dir, FileAccess.READ).get_as_text()
			#args = ["-r" , game_ID]
		#"steam":
			#prc = game_dir
		#"switch":
			##prc = usersettings.yuzu_dir
			#prc = usersettings.sudachi_dir
			##args = ["-r", "D:\\Emulation\\saves\\ryujinx", game_dir, "--fullscreen"]
			#args = ["-g" , game_dir,"-f"]
		#"wii":
			#prc = usersettings.dolphin_dir
			#args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		#"wiiu":
			#prc = usersettings.cemu_dir
			#args = ["-g" , game_dir, "-f"]
		#"xbox":
			#prc = usersettings.xemu_dir
			#args = ["-dvd_path", game_dir]
			##args = ["-full-screen","-dvd_path", game_dir]
		#"xbox360":
			#prc = usersettings.xenia_dir
			#args = ["--fullscreen=true", game_dir]
		"xbox":
			newGame["emu"] = usersettings.xenia_dir
			newGame["args"] = ["--fullscreen=true", game_dir]
		#"wii", "gc":
			#newGame["emu"] = usersettings.dolphin_local
			#newGame["args"] = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		_:
			newGame["emu"] = usersettings.ra_local
			newGame["args"] = ["-L" , usersettings.ra_cores_dir + game_core, game_dir]
	return newGame

var curr_timer: Timer
func _process(_delta: float) -> void:
	if is_instance_valid(curr_timer):
		time_label.text = str(round(curr_timer.time_left))

var previous_game: Dictionary = game_blank.duplicate()
func switch_game(next_game:Dictionary):
	var load_screen = notifman.notif_load()
	load_screen.close()
	sound_player.play()
	print("NEW GAME START!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("Previous game: ",previous_game["name"], "Next game: ",next_game["name"])
## If the previous game is RA, save and close it, else, suspend it.
	if previous_game["emu"] == usersettings.ra_local:
		await save_and_close()
	else:
		await suspend(previous_game)
## If the next game is not of type RA and has already been started, resume it.
	if next_game["emu"] != usersettings.ra_local and next_game["started"]:
		resume(next_game)
## If the next game is of type RA or has not been started, create its process.
	elif next_game["emu"] == usersettings.ra_local or not next_game["started"]:
		start_game(next_game)
## If this is the first time the game is being launched, do an information query.
		if not next_game["started"]:
			query_game_info(next_game)
## End the loading screen and bring the new prc to front
	load_screen.open()
	bring_to_front(next_game)
## Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),switch_game, pick_game)
## Update previous game to the currently running game..
	previous_game = next_game

func save_and_close():
	# Safe quit RA via UDP command (Save & quit)
	var ra_safe_quit_args : PackedStringArray = [
		"udpsend", "localhost", "55355", "QUIT"
		]
	var result_0 = OS.execute(sfk_path, ra_safe_quit_args, [], true)
	await get_tree().create_timer(0.5).timeout
	var result_1 = OS.execute(sfk_path, ra_safe_quit_args, [], true)

func suspend(game : Dictionary):
	game["active"] = false
	var suspend = PackedStringArray([game["pid"]])
	var result = OS.execute(pssuspend_path,suspend, [], true)
	if result != OK:
		print("Failed to suspend process: ", game["pid"])
	else:
		print("Suspending Process: ", game["pid"])

func resume(game : Dictionary):
	game["active"] = true
	var resume = PackedStringArray(["-r", game["pid"]])
	var result = OS.execute(pssuspend_path,resume, [], true)
	if result != OK:
		print("Failed to resume process: ", game["pid"])
	else:
		print("Resuming Process: ", game["pid"])

func start_game(game : Dictionary):
	game["pid"] = OS.create_process(game["emu"], game["args"])
	await get_tree().create_timer(0.5).timeout
	game["started"] = true

func query_game_info(game : Dictionary):
	var game_qry = await IGDB.query_game(game["name"], game["plat"])
	var game_name = game_qry["name"]
	if game_name == "":
		notifman.notif_intro(game_qry["tex"], game["name"], str(game["plat"]), str(game_qry["release"]))
	else:
		notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game["plat"]), str(game_qry["release"]))

func bring_to_front(game : Dictionary):
	var script_path = ProjectSettings.globalize_path("res://tools/switchtowindow.ps1")
	var args = [
		"-Command", "Set-ExecutionPolicy Bypass -Scope Process;", ". " + script_path + "; goto " + str(game["pid"])
	]
	var output = []
	OS.execute("powershell.exe", args, output, true)
	print("Bring to front output:", output)  # Output array contains the entire shell output as a single String element

func pick_game() -> Dictionary:
	var new_id = randi() % usersettings.bag_size
	while new_id == game_list.find(previous_game):
		new_id = randi() % usersettings.bag_size
	print("Current id: ", game_list.find(previous_game), "Next id: ", new_id)
	return game_list[new_id]
	
# BUTTON HELPERS-----------------------------------------------------------------------------------------------------------------------------
func _toggled(on: bool) -> void:
	if on:
		set_entries()
		btn_start.icon = icon_stop
		switch_game(pick_game())
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
	for game in game_list:
		if game["pid"] != -1 and OS.is_process_running(game["pid"]):
			OS.kill(game["pid"])
			print("Killed PID: ",game["pid"])
	globals.timers_kill()
	
func _pause(state: bool) -> void:
	if state:
		btn_pause.icon = icon_play
	else:
		btn_pause.icon = icon_pause
	globals.timers_pause(state)
	
func _skip() -> void:
	globals.timers_kill()
	switch_game(pick_game())

func _remove() -> void:
	for i in range(game_list.size()):
		var entry = game_list[i]
		if entry["pid"] == previous_game["pid"]:
			globals.timers_kill()
			OS.kill(previous_game["pid"])
			rerollGame(i)
			switch_game(game_list[i])

func _on_settings_pressed() -> void:
	var menu = notifman.notif_settings(self)

# utils-----------------------------------------------------------------------------------------------------------------------------
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
