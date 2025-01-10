extends Control

# Swap console logos for txt
# Never same game twice
# move IGDB to seperate thread
# controller menu? more options exposed to player

@onready var sound_player = $AudioStreamPlayer2D
@onready var time_label = $HBoxContainer/VBoxContainer/Label
@onready var btn_start = $HBoxContainer/VBoxContainer/Start
@onready var btn_pause = $HBoxContainer/VBoxContainer/Pause

@onready var icon_play = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
@onready var icon_pause = preload("res://Sprites/ui_icons/1x/pause.png")

signal load_open

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
	if games_arr.is_empty():
		push_error("No games found in roms directory.")
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
		#"n3ds":
			#prc = usersettings.lime3ds_dir
			#args = ["-f", "-g", game_dir]
		#"ps2":
			#newGame["emu"] = usersettings.pcsx2_dir
			#newGame["args"] = ["-fullscreen" , game_dir]
		"ps3":
			newGame["emu"] = usersettings.rpcs3_dir
			var link_target = get_lnk_target(game_dir)
			newGame["args"] = ["--fullscreen", "--no-gui", link_target]
		"psvita":
			prc = usersettings.vita3k_dir
			var game_ID = FileAccess.open(game_dir, FileAccess.READ).get_as_text()
			newGame["args"] = ["-r" , game_ID]
		#"steam":
			#prc = game_dir
		#"switch":
			##prc = usersettings.yuzu_dir
			#prc = usersettings.sudachi_dir
			##args = ["-r", "D:\\Emulation\\saves\\ryujinx", game_dir, "--fullscreen"]
			#args = ["-g" , game_dir,"-f"]
		#"wii", "gc":
			#newGame["emu"] = usersettings.dolphin_dir
			#newGame["args"] = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		"wiiu":
			newGame["emu"] = usersettings.cemu_dir
			newGame["args"] = ["-g" , game_dir, "-f"]
		"xbox360":
			newGame["emu"] = usersettings.xenia_dir
			newGame["args"] = ["--fullscreen=true", game_dir]
		"xbox":
			newGame["emu"] = usersettings.xenia_dir
			newGame["args"] = ["--fullscreen=true", game_dir]
		_:
			newGame["emu"] = usersettings.ra_local
			newGame["args"] = ["-L" , usersettings.ra_cores_dir + game_core, game_dir]
	return newGame

var curr_timer: Timer
func _process(_delta: float) -> void:
	if is_instance_valid(curr_timer):
		time_label.text = str(round(curr_timer.time_left))

var game_thread : Thread = Thread.new()
var previous_game: Dictionary = game_blank.duplicate()
func switch_game(next_game:Dictionary):
	print("NEW GAME START!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("Previous game: ",previous_game["name"], "Next game: ",next_game["name"])
## Determine if the next game is brand new
	var fresh_boot: bool = false
	if not next_game["started"]:
		fresh_boot = true
		query_game_info(next_game)
## Close the loading screen and fullscreen the click-through polygon
	var load_screen = notifman.notif_load()
	connect("load_open",Callable(load_screen, "open"))
	load_screen.close() #start loading animation on new thread?
	sound_player.play()
## If the previous game is RA, save and close it, else, suspend it.
	if previous_game["emu"] == usersettings.ra_local:
		udp_send("QUIT")
		await get_tree().create_timer(0.5).timeout
		udp_send("QUIT")
	else:
		await suspend(previous_game)
## If the next game is not of type RA and has already been started, resume it.
	if next_game["emu"] != usersettings.ra_local and fresh_boot:
		resume(next_game)
## If the next game is of type RA or has not been started, create its process.
	elif next_game["emu"] == usersettings.ra_local or not fresh_boot:
		print("Starting game...")
		game_thread.start(start_game.bind(next_game))
		return
	game_started(next_game)

func new_start_response(next_game : Dictionary):
	var response = game_thread.wait_to_finish()
	if not response:
		print("Failed to start game: " + next_game["name"])
		previous_game = next_game
		emit_signal("load_open")
		_remove()
		return 
	else:
		game_started(next_game)
		print("Game started.")

func game_started(next_game : Dictionary):
## End the loading screen and bring the new prc to front
	emit_signal("load_open")
	print(str(bring_to_front(next_game["pid"])))
	await get_tree().create_timer(0.25).timeout
	bring_to_front(OS.get_process_id()) # Bring this game window back on top of the game
## Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
	var nxt_game = pick_game()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),switch_game, nxt_game)
## Update previous game to the currently running game..
	previous_game = next_game

func verify_process(pid: int, expected_title: String = "RetroArch") -> Dictionary:
	var script_path = ProjectSettings.globalize_path("res://tools/verifyprocess.ps1")
	var args = [
		"-Command",
		"Set-ExecutionPolicy Bypass -Scope Process;",
		". " + script_path + "; Check-GameProcess -process_id " + str(pid) + " -expected_title '" + expected_title + "'"
	]
	var output = []
	var exit_code = OS.execute("powershell.exe", args, output, true)
	
	if exit_code != 0 or output.size() == 0:
		return {
			"success": false,
			"error": "Failed to execute verification script"
		}
	
	# Parse JSON output from PowerShell
	var json = JSON.parse_string(output[0])
	if not json:
		return {
			"success": false,
			"error": "Failed to parse script output"
		}
	
	return {
		"success": true,
		"data": json
	}

func start_game(game: Dictionary) -> bool:
	# Start timing from process creation
	var start_time = Time.get_ticks_msec()
	# Start the process and store PID
	game["pid"] = OS.create_process(game["emu"], game["args"])
	# Configuration for checks
	var max_wait_time: float = 15.0
	var elapsed_time: float = 0.0
	var check_interval: float = 0.5
	# Wait and verify process is properly running
	while elapsed_time < max_wait_time:
		# Verify process status
		var result = verify_process(game["pid"], game.get("window_title", "RetroArch"))
		if not result.success:
			push_error("Process verification failed: " + result.error)
			call_deferred("new_start_response", game)
			return false
		var process_info = result.data
		# Check if process is properly running
		if process_info.IsRunning and process_info.HasWindow:
			# Calculate actual elapsed time in seconds
			var actual_elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			print("Process verified running: ", game["pid"], " in ", actual_elapsed, " seconds")
			print("Window Title: ", process_info.WindowTitle)
			game["started"] = true
			call_deferred("new_start_response", game)
			return true
		# Wait before next check
		await get_tree().create_timer(check_interval).timeout
		elapsed_time += check_interval
	# If we got here, the process exists but failed to properly start
	push_error("Process created but failed to verify running state: " + game["name"])
	OS.kill(game["pid"])
	game["started"] = false
	call_deferred("new_start_response", game)
	return false

func query_game_info(game : Dictionary):
	var game_qry = await IGDB.query_game(game["name"], game["plat"])
	var game_name = game_qry["name"]
	if game_name == "":
		notifman.notif_intro(game_qry["tex"], game["name"], str(game["plat"]), str(game_qry["release"]))
	else:
		notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game["plat"]), str(game_qry["release"]))

func udp_send(cmd : String) -> Array:
	# Safe quit RA via UDP command (Save & quit)
	var udp_args : PackedStringArray = [
		"udpsend", "localhost", "55355", cmd
		]
	var output = []
	var result = OS.execute(sfk_path, udp_args, output, true)
	return output

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
		
func bring_to_front(pid : int):
	var script_path = ProjectSettings.globalize_path("res://tools/switchtowindow.ps1")
	var args = [
		"-Command", "Set-ExecutionPolicy Bypass -Scope Process;", ". " + script_path + "; goto " + str(pid)
	]
	var output = []
	OS.execute("powershell.exe", args, output, true)
	return output

func pick_game() -> Dictionary:
	var new_id = randi() % usersettings.bag_size
	while new_id == game_list.find(previous_game):
		new_id = randi() % usersettings.bag_size
	print("Current id: ", game_list.find(previous_game), " Next id: ", new_id)
	return game_list[new_id]
	
# BUTTON SIGNALS-----------------------------------------------------------------------------------------------------------------------------
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
	_box.queue_free()
	notifman.notif_end()
	
func _diag_confirm(_box : AcceptDialog):
	btn_start.set_pressed_no_signal(false)
	btn_start.icon = icon_play
	shutdown()
	_box.queue_free()
	notifman.notif_end()

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

func _restart() -> void:
	if !game_list.is_empty():
		switch_game(previous_game)

func _on_settings_pressed() -> void:
	notifman.notif_settings()

# utils-----------------------------------------------------------------------------------------------------------------------------
func get_lnk_target(lnk_path: String) -> String:
	print("PS3 Lnk Path...",lnk_path)
	var powershell_cmd = "powershell"
	var arguments = [
		"-Command",
		"$WshShell = New-Object -ComObject WScript.Shell; " +
		"$Shortcut = $WshShell.CreateShortcut('" + lnk_path + "'); " +
		"$Shortcut.Arguments"
		]
	var output = []
	var exit_code = OS.execute(powershell_cmd, arguments, output, true)
	if exit_code == 0:
		var args_string = String("\n").join(output).strip_edges()
		print("Constructing PS3 arg string...", args_string)
		#return args_string
		## Use regex to find the part inside the escaped quotes
		var regex = RegEx.new()
		regex.compile(r'"(.*?)"')  # Matches text between double quotes
		var reg_match = regex.search(args_string)
		# If a match is found, return the content inside the quotes, otherwise return an empty string
		if reg_match:
			return reg_match.get_string(1)
		else:
			return "No match found"
	else:
		return "Error reading .lnk file"

func match_core(sys : String) -> String:
	var current_core: String
	match sys:
		"3do":
			current_core = usersettings.core_3do
		"atari2600":
			current_core = usersettings.core_atari2600
		"atomiswave":
			current_core = usersettings.core_dreamcast
		"atarilynx":
			current_core = usersettings.core_atarilynx
		"dos":
			current_core = usersettings.core_dos
		"dreamcast":
			current_core = usersettings.core_dreamcast
		"fds":
			current_core = usersettings.core_nes
		"gameandwatch":
			current_core = usersettings.core_gameandwatch
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
		"neogeo":
			current_core = usersettings.core_neogeo
		"n3ds":
			current_core = usersettings.core_n3ds
		"n64":
			current_core = usersettings.core_n64
		"nds":
			current_core = usersettings.core_nds
		"naomi":
			current_core = usersettings.core_dreamcast
		"naomi2":
			current_core = usersettings.core_dreamcast
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
		"virtualboy":
			current_core = usersettings.core_virtualboy
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
