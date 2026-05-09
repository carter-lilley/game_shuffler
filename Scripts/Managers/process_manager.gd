extends Node
class_name ProcessManager

#Open emus in their working dir. 

signal process_failed(game: Dictionary)
signal process_created(game: Dictionary)

signal process_stopped(game: Dictionary)
signal process_stop_failed(game: Dictionary, result: int)

signal process_resumed(game: Dictionary, result: int)

@onready var sound_player = $"../AudioStreamPlayer2D"

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
	#var pid = OS.create_process(emu, args, true)
	var pid = launch_emu(emu, args)
	print("[ProcessManager]","Attempting to create process of ", pid, "...")
	if pid != -1:
		_confirm_create(pid, emu, game)
	call_deferred("create_result",game)

func launch_emu(exe_path: String, args: PackedStringArray) -> int:
	var ps_script = ProjectSettings.globalize_path("res://tools/launch_emulator.ps1")
	var ps_args = [
		"-NoProfile",
		"-File", ps_script,
		"-ExePath", exe_path,
	]
	# Append each emulator argument separately
	for arg in args:
		ps_args.append(arg)
	#print(ps_args)
	var output := []
	var exit_code := OS.execute("powershell", ps_args, output, true)
	if exit_code != OK or output.size() == 0:
		push_error("Failed to launch emulator")
		return -1
	# Parse PID from output
	#print(int(output[0].strip_edges()))
	return int(output[0].strip_edges())
	
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
			if is_process_running(pid):
				var exe_path := get_process_path(pid)
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

func get_process_path(pid: int) -> String:
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
	print("[ProcessManager] Stopping ", game["name"], " via ", method)
	var result: bool = false
	match method:
		"udp":
			udp_send("QUIT")
			OS.delay_msec(500)
			udp_send("QUIT")
			result = _confirm_stop(game["pid"])
		"suspend":
			result = pssuspend(game)
		"tcp":
			var save_name = str(game["name"].hash())
			var save_response = tcp_send("savevm %s" % save_name)
			# Wait for response to contain confirmation or error
			var max_wait = 20  # 20 seconds max for save
			var waited = 0
			while save_response[0] == "" and waited < max_wait:
				OS.delay_msec(500)
				waited += 0.5
			OS.delay_msec(1000)  # Extra buffer
			tcp_send("quit")
			result = _confirm_stop(game["pid"])
		_:
			push_error("Unknown stop method: %s" % method)
			result = false
	call_deferred("stop_result",result,game)

func stop_result(result : bool, game: Dictionary):
	stop_thread.wait_to_finish()
	if result:
		print("[ProcessManager] ", game["name"], " confirmed stopped.")
		emit_signal("process_stopped",game)
	else:
		push_error("[ProcessManager] ERROR: Unabled to stop game.")
		emit_signal("process_stop_failed",game)

func _confirm_stop(pid: int, timeout: float = 5.0, check_interval: float = 0.5) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if not is_process_running(pid):
			print("Process has exited.")
			return true
		else:
			print("Process still running... waiting")
		OS.delay_msec(int(check_interval * 1000))
		elapsed += check_interval
	print("Process did not stop in time.")
	return false

func resume_game_process(game: Dictionary):
	var method = usersettings.sys_default.get(game["sys"], {}).get("method", null)
	if method == null:
		push_error("ERROR: No resume method found.")
	print("[ProcessManager] Resuming ", game["name"], " via ", method)
	match method:
		"udp":
			create_game_process(game)
		"tcp":
			create_game_process(game)
			OS.delay_msec(2000)
			var save_name  = str(game["name"].hash())
			tcp_send("loadvm %s"%save_name)
		"suspend":
			psresume(game)
		_:
			push_error("Unknown stop method: %s" % method)

# Returns true if the process with `pid` exists, false otherwise
func is_process_running(pid: int) -> bool:
	var ps_script = ProjectSettings.globalize_path("res://tools/verify_process.ps1")
	var ps_args = [
		"-NoProfile",
		"-File", ps_script,
		"-TargetPid", str(pid)
	]
	var output := []
	var exit_code := OS.execute("powershell", ps_args, output, true)
	if exit_code != OK:
		push_error("[ProcessManager] Failed to check process PID %d" % pid)
		return false
	if output.size() == 0:
		push_error("[ProcessManager] No output returned from verify_process.ps1 for PID %d" % pid)
		return false
	# Output should be either 'True' or 'False'
	var result_str = output[0].strip_edges().to_lower()
	return result_str == "true"

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
#fix! maybe related to launching emus in cmd instead of in godot
func udp_send(cmd : String, port: int = 55355) -> Array:
	var udp_args : PackedStringArray = [
		"udpsend", "localhost", str(port), cmd
		]
	var output = []
	var result = OS.execute(sfk_path, udp_args, output, true)
	print(udp_args)
	print(output)
	return output

func tcp_send(cmd: String, port: int = 4444) -> Array:
	# Build the full command string and let cmd.exe parse it
	var full_cmd = '"%s" connect localhost:%d +send -spat "%s\\r\\n" +receive +disconnect' % [sfk_path, port, cmd]
	print("Full command: " + full_cmd)
	var output = []
	var exit_code = OS.execute("cmd.exe", ["/C", full_cmd], output, true)
	print(output)
	if exit_code != OK:
		push_error("TCP command failed: %s" % cmd)
	return output
	
func _get_emu_name(game: Dictionary) -> String:
	var system = usersettings.sys_default.get(game["sys"], {})
	var emu_path = system.get("emu", "")
	if emu_path == "":
		return ""
	return emu_path.get_file().get_basename()

func _suspend_resume_threads(pid: int, action: String) -> int:
	var ps_script = ProjectSettings.globalize_path("res://tools/thread_suspend.ps1")
	var ps_args = [
		"-NoProfile",
		"-ExecutionPolicy", "Bypass",
		"-File", ps_script,
		"-ProcessId", str(pid),
		"-Action", action
	]
	var output := []
	var exit_code := OS.execute("powershell", ps_args, output, true)
	print("[ProcessManager] thread_suspend.ps1 %s PID %d: exit=%d output=%s" % [action, pid, exit_code, output])
	return exit_code

func pssuspend(game : Dictionary) -> bool:
	# Verify the process is still running
	if not is_process_running(game["pid"]):
		push_warning("[ProcessManager] Cannot suspend process %d: not running." % game["pid"])
		return false
	game["active"] = false
	# Hide window FIRST (while it's still valid), then freeze
	var emu_name := _get_emu_name(game)
	print("[ProcessManager] Hiding window for PID: ", game["pid"], " emu: ", emu_name)
	minimize_window(game["pid"], emu_name)
	# Then freeze using thread-level suspension (more reliable than pssuspend.exe)
	var result = _suspend_resume_threads(game["pid"], "suspend")
	if result != OK:
		push_error("[ProcessManager] Failed to suspend process: %d" % game["pid"])
		return false
	print("[ProcessManager] Suspending Process: ", game["pid"])
	return true

func psresume(game : Dictionary):
	# Verify the process is still running
	if not is_process_running(game["pid"]):
		push_warning("Cannot resume process %d: not running." % game["pid"])
		emit_signal("process_resumed", game, ERR_DOES_NOT_EXIST)
		return
	game["active"] = true
	# Step 1: Resume FIRST using pssuspend.exe (proven to work on EDEN)
	var args = PackedStringArray(["-r", game["pid"]])
	var result = OS.execute(pssuspend_path, args, [], true)
	print("[ProcessManager] Resuming Process: ", game["pid"], " result: ", result)
	# Step 2: Then maximize window in a thread (can't hang main loop)
	var emu_name := _get_emu_name(game)
	print("[ProcessManager] Maximizing window for PID: ", game["pid"], " emu: ", emu_name)
	_maximize_window_async(game["pid"], emu_name)
	emit_signal("process_resumed", game, result)

func minimize_window(pid: int, emu_name: String = "") -> Array:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/minimize_window.ahk")
	var args = [ahk_script_path, str(pid), emu_name]
	var output := []
	var exit_code := OS.execute(ahk_exe_path, args, output, true)
	output.append("Exit code: %d" % exit_code)
	print("[ProcessManager] Minimize output...",output)
	return output

func maximize_window(pid: int, emu_name: String = "") -> Array:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/maximize_process.ahk")
	var args = [ahk_script_path, str(pid), emu_name]
	var output := []
	var exit_code := OS.execute(ahk_exe_path, args, output, true)
	output.append("Exit code: %d" % exit_code)
	print("[ProcessManager] Maximize output...",output)
	return output

# Async maximize with timeout - runs in background so it can't hang the main thread
var _maximize_thread := Thread.new()
func _maximize_window_async(pid: int, emu_name: String = "") -> void:
	if _maximize_thread.is_alive():
		_maximize_thread.wait_to_finish()
	_maximize_thread.start(_maximize_window_threaded.bind(pid, emu_name))

func _maximize_window_threaded(pid: int, emu_name: String) -> void:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/maximize_process.ahk")
	var args = [ahk_script_path, str(pid), emu_name]
	var output := []
	var exit_code := OS.execute(ahk_exe_path, args, output, true)
	print("[ProcessManager] Async maximize exit code: %d" % exit_code)

var maximize_exit_flag := false
var maximize_thread := Thread.new()
func maximize_game_process(pid: int) -> void:
	# Abort any previous bring-to-front attempt
	print("[ProcessManager] checking if maximize thread is alive...", maximize_thread.is_alive())
	if maximize_thread.is_alive():
		print("[ProcessManager] Cancelling previous bring-to-front...")
		maximize_exit_flag = true
		maximize_thread.wait_to_finish()
	maximize_exit_flag = false
	var err = maximize_thread.start(attempt_maximize.bind(pid))
	if err != OK:
		push_error("[ProcessManager] Failed to start bring-to-front thread")

func attempt_maximize(pid: int, timeout: float = 5.0, check_interval: float = 0.5) -> void:
	var ahk_exe_path = ProjectSettings.globalize_path("res://tools/ahk/AutoHotkey64.exe")
	var ahk_script_path = ProjectSettings.globalize_path("res://tools/maximize_process.ahk")
	var args = [ahk_script_path, str(pid)]
	var elapsed := 0.0
	var success := false
	var attempt := 1
	# Pre-check
	if not is_process_running(pid):
		print("[ProcessManager] Cannot bring to front: PID %d not running" % pid)
		call_deferred("maximize_result", false, pid)
		return
	while elapsed < timeout:
		# Early exit flag
		if maximize_exit_flag:
			print("[ProcessManager] Bring-to-front aborted.")
			break
		if not is_process_running(pid):
			print("[ProcessManager] PID vanished during bring-to-front")
			break
		print("[ProcessManager] Attempt %d to bring PID %d to front..." % [attempt, pid])
		var attempt_output := []
		var exit_code := OS.execute(ahk_exe_path, args, attempt_output, true)
		print("[ProcessManager] AHK exit code: %d, output: %s" % [exit_code, attempt_output])
		if exit_code == 0:
			print("[ProcessManager] Success on attempt %d." % attempt)
			success = true
			break
		OS.delay_msec(int(check_interval * 1000))
		elapsed += check_interval
		attempt += 1
	print("[ProcessManager] Bring-to-front finished. Success=%s" % success)
	# ALWAYS report results back to main thread
	call_deferred("maximize_result", success, pid)

@onready var sucess: AudioStreamWAV = preload("res://Sounds/FrontSuccess.wav")
@onready var fail: AudioStreamWAV = preload("res://Sounds/FrontFail.wav")
func maximize_result(success: bool, pid: int) -> void:
	maximize_thread.wait_to_finish()
	maximize_exit_flag = false
	print("[ProcessManager] Bring-to-front result: %s for PID %d" % [success, pid])
	# Play your chime
	if success:
		sound_player.stream = sucess
		sound_player.play()
	else:
		sound_player.stream = fail
		sound_player.play()
