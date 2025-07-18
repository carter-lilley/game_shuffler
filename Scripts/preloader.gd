extends Node
class_name Preloader


@onready var progress_bar = $"../CenterContainer/ProgressBar"

var _is_running: bool = false
var _thread := Thread.new()
var _thread_result: Dictionary = {}
var _current_copy_progress: float = 0.0
var current_copy_progress: float:
	get:
		return _current_copy_progress
	set(value):
		_current_copy_progress = value
var _progress_mutex := Mutex.new()

func _ready():
	progress_bar.visible = false

func _process(_delta):
	if _is_running:
		progress_bar.visible = true
		_progress_mutex.lock()
		progress_bar.value = current_copy_progress * 100
		_progress_mutex.unlock()
	else:
		progress_bar.visible = false

func start_preloading(game: Dictionary) -> Dictionary:
	if _is_running:
		push_warning("Preloading is already running.")
		return {}
	_ensure_temp_folder()
	_is_running = true
	_thread_result = {}
	_set_copy_progress(0.0)

	print("Starting preload thread")
	var error := _thread.start(_threaded_preload.bind(game))
	if error != OK:
		push_error("Failed to start thread.")
		_is_running = false
		return {}
	await _wait_for_thread()
	_is_running = false
	print("Preload thread finished")
	return _thread_result

func _wait_for_thread() -> void:
	var tries := 0
	while _thread.is_alive() and tries < 1000:
		await get_tree().process_frame
		tries += 1
	if tries >= 1000:
		push_warning("Thread wait timeout.")
	_thread.wait_to_finish()

func _ensure_temp_folder() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("temp"):
		dir.make_dir("temp")
	
func _threaded_preload(game: Dictionary) -> void:
	print("Thread started")
	# Error handling wrapper
	var error_occurred := false

	# Try-catch style using 'yield' not supported, so use error flag
	var from_path: String = game.get("path", "")
	if from_path == "":
		push_error("No valid input path found.")
		error_occurred = true
		_thread_result = game
		return

	var file_name := from_path.get_file()
	var to_path_virtual = "user://temp/" + file_name
	var to_path = ProjectSettings.globalize_path(to_path_virtual)
	to_path = to_path.replace("/", "\\")  # Normalize for Windows if needed

	var success := _copy_file_with_progress(from_path, to_path)
	if not success:
		push_error("Failed to copy file: %s to %s" % [from_path, to_path])
		error_occurred = true
		_thread_result = game
		return

	if not error_occurred:
		game["path"] = to_path
		_thread_result = game
	print("Thread ending")

func _copy_file_with_progress(from_path: String, to_path: String, chunk_size := 4 * 1024 * 1024) -> bool:
	var total_size = _get_file_size(from_path)
	if total_size == 0:
		return false
	var from_file := FileAccess.open(from_path, FileAccess.READ)
	if from_file == null:
		return false
	var to_file := FileAccess.open(to_path, FileAccess.WRITE)
	if to_file == null:
		from_file.close()
		return false
	var copied: int = 0
	while not from_file.eof_reached():
		var chunk = from_file.get_buffer(chunk_size)
		to_file.store_buffer(chunk)
		copied += chunk.size()
		_set_copy_progress(float(copied) / total_size)
		OS.delay_msec(1)  # Yield to avoid blocking other threads
	from_file.close()
	to_file.close()
	_set_copy_progress(1.0)
	return true

func _get_file_size(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var size = file.get_length()
		file.close()
		return size
	return 0

# Thread-safe setter for progress
func _set_copy_progress(value: float) -> void:
	_progress_mutex.lock()
	current_copy_progress = clamp(value, 0.0, 1.0)
	_progress_mutex.unlock()
