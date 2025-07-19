extends Control
# Swap console logos for txt
# user set-up
# more options exposed to player in settings (pure random mode, weight by # of games, etc...)
# move IGDB to seperate thread
# controller menu combo
# robust error checking - ongoing crash check?
# confirmation on "remove"
# Improve IDGB search parameters

@onready var preloader = $preloader

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
var bag: Array 
var game_blank : Dictionary = {
	"name": "",
	"sys": "",
	"path": "",
	"pid": -1,
	"started": false,
	"active": false
}

func _ready() -> void:
	preloader.connect("preload_completed", Callable(self, "_on_preload_completed"))
	print("Ready...")
	randomize()

func set_entries():
	bag.clear()
	for i in range(usersettings.bag_size):
		var entry = rollGame()
		bag.append(entry)
	print(bag)

func rerollGame(i : int):
	print("Rerolling ", bag[i]["name"],"...new result:")
	if i < 0 or i >= bag.size():
		print("Reroll index out of bounds.")
		return
	var new_game = rollGame()
	bag[i] = new_game
	print(bag[i])

func get_random_active_system() -> String:
	var keys := usersettings.systems.keys().filter(func(k): return usersettings.systems[k])
	return keys.pick_random() if keys.size() > 0 else ""
	
func rollGame() -> Dictionary:
	var newGame: Dictionary = game_blank.duplicate()
# Create paths
	var sys_raw: String = get_random_active_system()
	var sys_dir: String = usersettings.rom_dir + "\\" + sys_raw
	var game_list: PackedStringArray = DirAccess.get_files_at(sys_dir)
	if game_list.is_empty():
		push_error("No games found in active system roms directory.")
	var game_name_raw: String = globals.rand_string(game_list)
	var game_path: String = usersettings.rom_dir + "\\" + sys_raw + "\\" + game_name_raw
# Sanitize game name and check for duplicates
	var game_name: String = globals.sanitize_string(game_name_raw)
	for game in bag:
		if game["name"] == game_name:
			print("Duplicate game found: ", game_name, " Rerolling...")
			return rollGame()  # Recursively re-call rollGame if a duplicate is found
# Create empty game dictionary and argument reference
	newGame["path"] = game_path
	newGame["name"] = game_name
	newGame["sys"] = sys_raw
	return newGame

var curr_timer: Timer
func _process(_delta: float) -> void:
	if is_instance_valid(curr_timer):
		time_label.text = str(round(curr_timer.time_left))

var previous_game: Dictionary = game_blank.duplicate()
func switch_game(next_game:Dictionary):
	## Close the loading screen and fullscreen the click-through polygon
	print("NEW GAME START!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("Previous game: ",previous_game["name"], "Next game: ",next_game["name"])
	var load_screen = notifman.notif_load()
	connect("load_open",Callable(load_screen, "open"))
	load_screen.close() #start loading animation on new thread?
	sound_player.play()
	if previous_game["pid"] != -1:
		var stopped := await stop_game(previous_game)
		if not stopped:
			push_error("Failed to stop previous game: " + previous_game["name"])
			return
	else:
		print("No previous game process to stop.")

	start_game(next_game)

func stop_game(game: Dictionary) -> bool:
	var method = usersettings.sys_default.get(game["sys"], {}).get("method", {})
	if method == null:
		push_error("No suspend method found for system: " + game["sys"])
	print("Stopping ", game["name"], " by ", method)
	match method:
		"udp":
			udp_send("QUIT")
			await get_tree().create_timer(0.5).timeout
			udp_send("QUIT")
			await get_tree().create_timer(1.0).timeout
			if OS.is_process_running(game["pid"]):
				print("Game process still running after UDP QUIT.")
				return false
		"suspend":
			var success := await pssuspend(game)
			if not success:
				print("Failed to suspend process.")
				return false
	return true
			
var game_thread : Thread = Thread.new()
func start_game(game : Dictionary) -> void:
	if not game["started"]:
		# FIRST START LOGIC
		preloader.start_preloading(game)
	else:
		resume(game)
		game_started(game)
		
func _on_preload_completed(original_game: Dictionary, updated_game: Dictionary) -> void:
	if updated_game.has("path"):
		print("Updated path after preload:", updated_game["path"])
		# Update original game dict reference to keep state consistent
		for key in updated_game.keys():
			original_game[key] = updated_game[key]
	else:
		push_warning("Preloading did not update game path!")
			## Run create() on a thread so it doesn't block
	var err = game_thread.start(create.bind(original_game))
	if err != OK:
		push_error("Failed to start game thread")
	## query_game_info(next_game)

func game_started(next_game : Dictionary):
## End the loading screen and bring the new prc to front
	emit_signal("load_open")
	print(str(bring_to_front(next_game["pid"])))
	await get_tree().create_timer(0.25).timeout
	bring_to_front(OS.get_process_id()) # Bring this game window back on top of the game
## Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
## Update previous game to the currently running game..
	previous_game = next_game
	var following_game = pick_game()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),switch_game, following_game)

func resume(game: Dictionary):
	if usersettings.sys_default.get(game["sys"], {}).get("method", {}) == "udp":
		# Run create() on a thread so it doesn't block
		var err = game_thread.start(create.bind(game))
		if err != OK:
			push_error("Failed to start game thread")
	else:
		psresume(game)

func create(game: Dictionary) -> bool:
	var emu: String = usersettings.sys_default.get(game["sys"], {}).get("emu", "")
	var args: PackedStringArray = resolve_args(game)
	var pid := OS.create_process(emu, args, true)
	if pid == -1:
		push_error("Failed to start process for: " + game["name"])
		call_deferred("create_response", game)
		return false
	game["pid"] = pid
	game["started"] = true
	call_deferred("create_response", game)
	return true

func create_response(next_game : Dictionary):
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

func query_game_info(game : Dictionary):
	var game_qry = await IGDB.query_game(game["name"], game["plat"])
	var game_name = game_qry["name"]
	if game_name == "":
		notifman.notif_intro(game_qry["tex"], game["name"], str(game["plat"]), str(game_qry["release"]))
	else:
		notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game["plat"]), str(game_qry["release"]))

func pick_game() -> Dictionary:
	var new_id = randi() % usersettings.bag_size
	while new_id == bag.find(previous_game):
		print("Attempted to pick duplicate game...",previous_game["name"]," ", bag.find(previous_game))
		new_id = randi() % usersettings.bag_size
	#print("Previous game & ID: ",previous_game["name"]," ", bag.find(previous_game), "New game ID: ", new_id)
	return bag[new_id]

# POWERSHELL CMDS------------------------------------------------------------------------------
func udp_send(cmd : String) -> Array:
	var udp_args : PackedStringArray = [
		"udpsend", "localhost", "55355", cmd
		]
	var output = []
	var result = OS.execute(sfk_path, udp_args, output, true)
	return output

func pssuspend(game : Dictionary) -> bool:
	game["active"] = false
	var suspend = PackedStringArray([game["pid"]])
	var result = OS.execute(pssuspend_path,suspend, [], true)
	if result != OK:
		print("Failed to suspend process: ", game["pid"])
		return false
	else:
		print("Suspending Process: ", game["pid"])
		return true

func psresume(game : Dictionary):
	game["active"] = true
	var args = PackedStringArray(["-r", game["pid"]])
	var result = OS.execute(pssuspend_path,args, [], true)
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
	clear_directory("user://temp")
	for game in bag:
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
	for i in range(bag.size()):
		var entry = bag[i]
		if entry["pid"] == previous_game["pid"]:
			globals.timers_kill()
			OS.kill(previous_game["pid"])
			rerollGame(i)
			switch_game(bag[i])

func _restart() -> void:
	if !bag.is_empty():
		switch_game(previous_game)

func _on_settings_pressed() -> void:
	notifman.notif_settings()

# utils-----------------------------------------------------------------------------------------------------------------------------
func clear_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var entry = dir.get_next()
		while entry != "":
			if entry != "." and entry != "..":
				var full_path = path + "/" + entry
				if dir.current_is_dir():
					clear_directory(full_path)  # recursive delete
					# Need a new DirAccess to remove the empty folder:
					var sub_dir = DirAccess.open(path)
					if sub_dir:
						sub_dir.remove(full_path)
				else:
					dir.remove(full_path)
			entry = dir.get_next()
		dir.list_dir_end()

func resolve_args(game: Dictionary) -> Array:
	var system = usersettings.sys_default.get(game["sys"], {})
	var core = usersettings.ra_cores_dir + system.get("core", "")
	var args = system.get("args", [])
	var resolved_args: Array = []
	for arg in args:
		match arg:
			"{PATH}":
				resolved_args.append(str(game.get("path", "")))
			"{CORE}":
				resolved_args.append(str(core))
			_:
				resolved_args.append(arg)
	return resolved_args

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
