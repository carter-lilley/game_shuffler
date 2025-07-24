extends Node
class_name GameManager
# Swap console logos for txt
# user set-up
# more options exposed to player in settings (pure random mode, weight by # of games, etc...)
# move IGDB to seperate thread
# controller menu combo
# robust error checking - ongoing crash check?
# confirmation on "remove"
# Improve IDGB search parameters

@onready var preloader = $"../preloader"
@onready var process_manager = $"../process_manager"
@onready var HTTP_manager = $"../HTTP_manager"
@onready var sound_player = $"../AudioStreamPlayer2D"
@onready var time_label = $"../HBoxContainer/VBoxContainer/Label"
@onready var btn_start = $"../HBoxContainer/VBoxContainer/Start"
@onready var btn_pause = $"../HBoxContainer/VBoxContainer/Pause"

@onready var icon_play = preload("res://Sprites/ui_icons/1x/forward.png")
@onready var icon_stop = preload("res://Sprites/ui_icons/1x/stop.png")
@onready var icon_pause = preload("res://Sprites/ui_icons/1x/pause.png")

signal load_open

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
	preloader.connect("preload_completed", _on_preload_completed)
	process_manager.connect("process_created",_on_process_created)
	process_manager.connect("process_failed",_on_process_failed)
	process_manager.connect("process_resumed",_on_process_resumed)
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

var current_game: Dictionary = game_blank.duplicate()
func switch_game(next_game:Dictionary):
	## Close the loading screen and fullscreen the click-through polygon
	print("-----------------------------------------------------------------------")
	print("----------------------------NEW GAME START!----------------------------")
	print("-----------------------------------------------------------------------")
	print("[GameManager]","Previous game: ",current_game["name"], " Next game: ",next_game["name"])
	var load_screen = notifman.notif_load()
	connect("load_open",Callable(load_screen, "open"))
	load_screen.close() #start loading animation on new thread?
	sound_player.play()
	if current_game["pid"] != -1:
		process_manager.stop_game_process(current_game)
	else:
		print("No previous game process to stop.")
	queue_game(next_game)
			
func queue_game(game : Dictionary) -> void:
	if not game["started"]:
		# FIRST START LOGIC
		preloader.start_preloading(game)
		query_game_info(game)
		#if preloader.get_file_size_gbs(game["path"]) > 0.5:
			#preloader.start_preloading(game)
		#else:
			#if !process_manager.create_thread.is_alive():
				#process_manager.create_game_process(game)
	else: 
		process_manager.resume_game_process(game)

func start_game(next_game : Dictionary):
## End the loading screen and bring the new prc to front
	process_manager.maximize_game_process(next_game["pid"])
	emit_signal("load_open")
## Stop the current timer and start a new one for the next round
	if is_instance_valid(curr_timer):
		curr_timer.stop()
## Update previous game to the currently running game..
	current_game = next_game
	var following_game = pick_game()
	curr_timer = globals.create_timer(randf_range(usersettings.round_time_min, usersettings.round_time_max),switch_game, following_game)

func _on_process_resumed(game : Dictionary, result : int):
	if result != OK:
		push_error("Failed to resume process: ", game["pid"])
	else:
		print("Resuming Process: ", game["pid"])
		start_game(game)

func _on_process_created(game : Dictionary):
	#query_game_info(game)
	print("[GameManager]",game["name"], " successfully started.")
	start_game(game)

func _on_process_failed(game : Dictionary):
	print("[GameManager]","Failed to start game: " + game["name"] + ". Replacing...")
	current_game = game
	_remove() 
	
func _on_preload_completed(original_game: Dictionary, updated_game: Dictionary) -> void:
	if updated_game.has("path"):
		print("Updated path after preload:", updated_game["path"])
		for key in updated_game.keys():
			original_game[key] = updated_game[key]
	else:
		push_warning("Preloading did not update game path!")
	if !process_manager.create_thread.is_alive():
		process_manager.create_game_process(original_game)

func query_game_info(game : Dictionary):
	var game_qry = await HTTP_manager.query_game(game["name"], game["sys"])
	var game_name = game_qry["name"]
	if game_name == "":
		notifman.notif_intro(game_qry["tex"], game["name"], str(game["sys"]), str(game_qry["release"]))
	else:
		notifman.notif_intro(game_qry["tex"], game_qry["name"], str(game["sys"]), str(game_qry["release"]))

func pick_game() -> Dictionary:
	var new_id = randi() % usersettings.bag_size
	while new_id == bag.find(current_game):
		print("Attempted to pick duplicate next game...",current_game["name"]," ", bag.find(current_game))
		new_id = randi() % usersettings.bag_size
	#print("Previous game & ID: ",current_game["name"]," ", bag.find(current_game), "New game ID: ", new_id)
	return bag[new_id]
	
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
	if current_game == null:
		return  # Safety check if no current game
	globals.timers_kill()
	if current_game["pid"] != -1:
		OS.kill(current_game["pid"])
	var index = bag.find(current_game)
	if index != -1:
		rerollGame(index)
		switch_game(bag[index])
	else:
		push_error("Previous game not found in bag!")

func _restart() -> void:
	if !bag.is_empty():
		switch_game(current_game)

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
