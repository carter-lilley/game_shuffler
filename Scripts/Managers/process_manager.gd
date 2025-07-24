extends Node
class_name ProcessManager

signal process_failed(game: Dictionary)
signal process_created(game: Dictionary)

signal process_stopped(game: Dictionary)
signal process_stop_failed(game: Dictionary, result: int)

signal process_resumed(game: Dictionary, result: int)

var create_thread := Thread.new()
func create_game_process(game: Dictionary) -> void:
	if create_thread.is_alive():
		push_error("Thread is still running! Can't start a new game process.")
		return
	print("[ProcessManager]","Starting thread for game: ", game["name"])
	var err := create_thread.start(attempt_create.bind(game))
	if err != OK:
		push_error("Failed to start game process thread.")

func attempt_create(game: Dictionary) -> void:
	var system = usersettings.sys_default.get(game["sys"], {})
	var emu = system.get("emu", "")
	var args = []
	for arg in system.get("args", []):
		match arg:
			"{PATH}":
				args.append(game.get("path", ""))
			"{CORE}":
				var core = usersettings.ra_cores_dir + system.get("core", "")
				args.append(core)
			_:
				args.append(arg)
	var pid = OS.create_process(emu, args, true)
	print("[ProcessManager]","Attempting to create process of ", pid, "...")
	if pid != -1:
		_confirm_create(pid, emu, game)
	call_deferred("create_result",game)

func create_result(game: Dictionary):
	create_thread.wait_to_finish()
	if game["started"]:
		emit_signal("process_created", game)
	else:
		push_warning("Process creation failed.")
		emit_signal("process_failed", game)
		
func _confirm_create(pid: int, emu: String, game: Dictionary) -> void:
		const MAX_WAIT := 5.0
		const CHECK_INTERVAL := 0.2
		var elapsed := 0.0
		while elapsed < MAX_WAIT:
			if OS.is_process_running(pid):
				var exe_path := _get_process_path_powershell(pid)
				if exe_path != "" and exe_path.to_lower() == emu.to_lower():
					print("[ProcessManager]","Process ID & Path confirmed.")
					game["pid"] = pid
					game["started"] = true
					break
				else:
					print("[ProcessManager]","Process not confirmed yet... waiting")
			else:
				print("[ProcessManager]","Process not running yet... waiting")
			OS.delay_msec(int(CHECK_INTERVAL * 1000))
			elapsed += CHECK_INTERVAL


func _get_process_path_powershell(pid: int) -> String:
	var output := []
	var command := "try { (Get-Process -Id %d).Path } catch { '' }" % pid
	var exit_code := OS.execute("powershell", ["-NoProfile", "-Command", command], output, true)

	if exit_code != OK or output.is_empty():
		return ""

	for line in output:
		line = line.strip_edges()
		if line.to_lower().ends_with(".exe"):
			return line
	return ""
	
#STOP-------------------------------------------
var stop_thread := Thread.new()
func stop_game_process(game: Dictionary) -> void:
	if stop_thread.is_alive():
		push_error("ProcessManager is already stopping a game.")
		return
	stop_thread.start(_threaded_stop_process.bind(game))

func _threaded_stop_process(game: Dictionary) -> void:
	var method = usersettings.sys_default.get(game["sys"], {}).get("method", null)
	if method == null:
		push_error("ERROR: No stop method found.")
		call_deferred("emit_signal", "process_stop_failed", game)
	print("Stopping ", game["name"], " by ", method)
	var result: bool = false
	match method:
		"udp":
			udp_send("QUIT")
			OS.delay_msec(500)
			udp_send("QUIT")
			result = _confirm_stop(game["pid"])
		"suspend":
			result = pssuspend(game)
		_:
			push_error("Unknown stop method: %s" % method)
			result = false
	call_deferred("stop_result",result,game)

func stop_result(result : bool, game: Dictionary):
	stop_thread.wait_to_finish()
	if result:
		print(game["name"], " confirmed stopped.")
		emit_signal("process_stopped",game)
	else:
		push_error("ERROR: Unabled to stop game.")
		emit_signal("process_stop_failed",game)

func _confirm_stop(pid: int, timeout: float = 5.0, check_interval: float = 0.5) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if not OS.is_process_running(pid):
			print("Process has exited.")
			return true
		else:
			print("Process still running... waiting")
		OS.delay_msec(int(check_interval * 1000))
		elapsed += check_interval
	print("Process did not stop in time.")
	return false

func resume_game_process(game: Dictionary):
	if usersettings.sys_default.get(game["sys"], {}).get("method", {}) == "udp":
		create_game_process(game)
	else:
		psresume(game)

# UTILS-----------------------------------------------------------------------------------------
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

# POWERSHELL CMDS------------------------------------------------------------------------------
var sfk_path = ProjectSettings.globalize_path("res://tools/sfk.exe")
var pssuspend_path = ProjectSettings.globalize_path("res://tools/pssuspend.exe")
func udp_send(cmd : String) -> Array:
	var udp_args : PackedStringArray = [
		"udpsend", "localhost", "55355", cmd
		]
	var output = []
	var result = OS.execute(sfk_path, udp_args, output, true)
	return output

func pssuspend(game : Dictionary) -> bool:
	minimize_window(game["pid"])
	game["active"] = false
	var suspend = PackedStringArray([game["pid"]])
	var result = OS.execute(pssuspend_path,suspend, [], true)
	if result != OK:
		push_error("Failed to suspend process: ", game["pid"])
		return false
	else:
		print("Suspending Process: ", game["pid"])
		return true

func psresume(game : Dictionary):
	game["active"] = true
	var args = PackedStringArray(["-r", game["pid"]])
	var result = OS.execute(pssuspend_path,args, [], true)
	emit_signal("process_resumed", game, result)

func minimize_window(pid: int) -> Array:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/minimize_window.ahk")
	var args = [ahk_script_path, str(pid)]
	var output := []
	var exit_code := OS.execute(ahk_exe_path, args, output, true)
	output.append("Exit code: %d" % exit_code)
	print("[Minimize Window]",output)
	return output

var front_thread := Thread.new()
func maximize_game_process(pid: int) -> void:
	if front_thread.is_alive():
		push_error("[ProcessManager]","Thread is still running! Can't maximize process.")
		return
	var err := front_thread.start(_attempt_bring_to_front.bind(pid))
	if err != OK:
		push_error("[ProcessManager]","Failed to start game process thread.")
		
func _attempt_bring_to_front(pid: int, timeout: float = 5.0, check_interval: float = 0.5) -> void:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/bring_to_front.ahk")
	var args = [ahk_script_path, str(pid)]
	var elapsed := 0.0
	var success := false
	var attempt := 1
	while elapsed < timeout:
		print("[ProcessManager]","Attempt %d to bring PID %d to front..." % [attempt, pid])
		var attempt_output := []
		var exit_code := OS.execute(ahk_exe_path, args, attempt_output, true)
		if exit_code == 0:
			print("[ProcessManager]","Success on attempt %d." % attempt)
			print("[ProcessManager]",attempt_output)
			success = true
			break
		else:
			print("Failed to bring to front. Retrying...")
		OS.delay_msec(int(check_interval * 1000))
		elapsed += check_interval
		attempt += 1
	if not success:
		print("Giving up after %.2f seconds." % elapsed)
	front_thread.call_deferred("wait_to_finish")
