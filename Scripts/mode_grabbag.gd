extends Control
# Need file type checks
@onready var sound_player = $AudioStreamPlayer2D
@onready var time_label = $HBoxContainer/VBoxContainer/Label
@onready var btn_start = $HBoxContainer/VBoxContainer/HBoxContainer/Start
@onready var btn_pause = $HBoxContainer/VBoxContainer/HBoxContainer/Pause

@onready var icon_play = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
@onready var icon_pause = preload("res://Sprites/ui_icons/1x/pause.png")

var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")

var active_systems : PackedStringArray
var prc_list: Array 
var prc_blank : Dictionary = {
	"name": "",
	"plat": "",
	"args": PackedStringArray(),
	"pid": 0,
	"active": false
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

var _3ds_increment : int = 0
func rollGame() -> Dictionary:
	var newGame: Dictionary = {}
	# Create paths
	var sys: String = globals.rand_string(active_systems)
	var sys_dir: String = usersettings.rom_dir + "\\" + sys
	var games_arr: PackedStringArray = DirAccess.get_files_at(sys_dir)
	var game: String = globals.rand_string(games_arr)
	var game_dir: String = usersettings.rom_dir + "\\" + sys + "\\" + game
	# Sanitize game name and check for duplicates
	var game_name: String = globals.sanitize_string(game)
	# Check for duplicate names in prc_list
	for prc in prc_list:
		# Only 1 Wii instance...
		if prc["plat"] == sys and sys == "wii":
			print("Second ", sys, " instance...", game_name, " Rerolling...")
			return rollGame()
		# Only 1 PS3 instance...
		if prc["plat"] == sys and sys == "ps3":
			print("Second ", sys, " instance...", game_name, " Rerolling...")
			return rollGame()
		# Only 2 3DS instances...
		if prc["plat"] == sys and sys == "n3ds":
			if _3ds_increment >= 2:
				print("Third ", sys, " instance...", game_name, " Rerolling...")
				return rollGame()
			else:
				print("Incrementing ", sys, " instance...", game_name)
				_3ds_increment += 1
		if prc["name"] == game_name:
			print("Duplicate game found: ", game_name, " Rerolling...")
			return rollGame()  # Recursively re-call rollGame if a duplicate is found
	# Create empty process and argument reference
	var prc: String
	var args: PackedStringArray = []
	match sys:
		"gc":
			prc = usersettings.dolphin_dir
			args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		"n3ds":
			prc = usersettings.lime3ds_dir
			args = ["-f", "-g", game_dir]
		"ps2":
			prc = usersettings.pcsx2_dir
			args = ["-fullscreen" , game_dir]
		"ps3":
			prc = usersettings.rpcs3_dir
			var link_target = get_lnk_target(game_dir)
			args = ["--fullscreen", "--no-gui", link_target]
		"psvita":
			prc = usersettings.vita3k_dir
			var game_ID = FileAccess.open(game_dir, FileAccess.READ).get_as_text()
			args = ["-r" , game_ID]
		"steam":
			prc = game_dir
		"switch":
			#prc = usersettings.yuzu_dir
			prc = usersettings.sudachi_dir
			#args = ["-r", "D:\\Emulation\\saves\\ryujinx", game_dir, "--fullscreen"]
			args = ["-g" , game_dir,"-f"]
		"wii":
			prc = usersettings.dolphin_dir
			args = ["-e" , game_dir, "--config" , "Dolphin.Display.Fullscreen=True"]
		"wiiu":
			prc = usersettings.cemu_dir
			args = ["-g" , game_dir, "-f"]
		"xbox":
			prc = usersettings.xemu_dir
			args = ["-dvd_path", game_dir]
			#args = ["-full-screen","-dvd_path", game_dir]
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
	var load_screen = notifman.notif_load()
	load_screen.close()
	sound_player.play()
	print("NEW GAME START!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("Current game: ",prc_list[id]["name"]," Current_ID: ", id, " Last_PID: ", last_pid)
	# Suspend previous process...
	await suspendPrc(last_pid) 
	
	var curr_prc = prc_list[id]
	var retry_count = 0
	var max_retries = 4
	var process_created = false
	
	# Resume process if it is already running
	if OS.is_process_running(curr_prc["pid"]):
		process_created = true
		print(curr_prc["pid"], " already exists. Resuming...")
		resumePrc(id)
		
	#Else, create it...
	while retry_count < max_retries and !process_created:
		# Try to create the process if it's not running
		if !OS.is_process_running(curr_prc["pid"]):
			curr_prc["pid"] = OS.create_process(curr_prc["prc"], curr_prc["args"])
			print("Attempting to create process... ", curr_prc["pid"])
		# Wait for 3 seconds and check if the process is running
		await get_tree().create_timer(3.0).timeout
		if OS.is_process_running(curr_prc["pid"]): # Process is running...
			curr_prc["active"] = true
			process_created = true
			print("Process confirmed to be running after ", (retry_count + 1) * 3, " seconds.")
			# Query game information
			var game_qry = await IGDB.query_game(prc_list[id]["name"], prc_list[id]["plat"])
			var game_name = game_qry["name"]
			if game_name == "":
				notifman.notif_intro(game_qry["tex"], prc_list[id]["name"], str(prc_list[id]["plat"]), str(game_qry["release"]))
			else:
				notifman.notif_intro(game_qry["tex"], game_qry["name"], str(prc_list[id]["plat"]), str(game_qry["release"]))
			break  # Exit the retry loop since the process is running
		else:
			print("Process not running, retrying... (Attempt ", retry_count + 1, ")")
			retry_count += 1

	# If process creation failed after all attempts, reroll a new game
	if !process_created:
		curr_prc["active"] = false
		print("Failed to create process after ", max_retries, " attempts, rerolling...")
		rerollGame(id)
		# Restart the process after reroll
		startGame(id)

	# End the loading screen, update the last PID, and bring the new prc to front
	load_screen.open()
	last_pid = prc_list[id]["pid"]
	bringtofront(prc_list[id]["pid"])
	# Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
	var next_id = newId()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),startGame, next_id)
	#while curr_timer.time_left > 0.0:
		#await get_tree().create_timer(1.0).timeout  # Check every 1 second
		#if !OS.is_process_running(curr_prc["pid"]):
			#print("Process crashed! Rerolling new game...")
			#curr_prc["active"] = false
			#rerollGame(id)
			#startGame(id)

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
	globals.timers_kill()
	startGame(newId())

func _remove() -> void:
	for i in range(prc_list.size()):
		var entry = prc_list[i]
		if entry.has("pid") and entry["pid"] == last_pid:
			globals.timers_kill()
			OS.kill(last_pid)
			rerollGame(i)
			startGame(i)

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
