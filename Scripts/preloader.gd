extends Node
class_name Preloader

signal progress_updated(value: float)
signal preload_completed(original_game: Dictionary, updated_game: Dictionary)

@onready var progress_bar = $"../CenterContainer/ProgressBar"

var _thread: Thread
var _is_running := false

func _ready():
	progress_bar.visible = false
	connect("progress_updated", Callable(self, "_on_progress_updated"))

func _process(_delta):
	progress_bar.visible = _is_running

func start_preloading(game: Dictionary) -> void:
	if _is_running:
		push_warning("Preloader already running.")
		return

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://temp")):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://temp"))

	_thread = Thread.new()
	var err = _thread.start(_threaded_preload.bind(game))
	if err != OK:
		push_error("Failed to start preload thread.")
		_thread = null
		return

	_is_running = true

func _on_progress_updated(value: float) -> void:
	progress_bar.value = value * 100.0

func _ensure_temp_folder() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("temp"):
		dir.make_dir("temp")

func _threaded_preload(game: Dictionary) -> void:
	print("Thread started")
	var from_path: String = game.get("path", "")
	if from_path == "":
		push_error("No path provided.")
		call_deferred("emit_signal", "preload_completed", game, game)
		return

	var file_name = from_path.get_file()
	var to_path_virtual = "user://temp/" + file_name
	var to_path = ProjectSettings.globalize_path(to_path_virtual)

	if not _copy_file_with_progress(from_path, to_path):
		push_error("Copy failed.")
		call_deferred("emit_signal", "preload_completed", game, game)
		return

	var updated_game = game.duplicate()
	updated_game["path"] = to_path
	call_deferred("emit_signal", "preload_completed", game, updated_game)
	
	print("Preload completed. Closing thread.")
	_is_running = false
	_thread.call_deferred("wait_to_finish") # Safely clean up after emitting
	
func _copy_file_with_progress(from_path: String, to_path: String, chunk_size := 4 * 1024 * 1024) -> bool:
	var total_size = _get_file_size(from_path)
	if total_size <= 0:
		return false

	var from_file = FileAccess.open(from_path, FileAccess.READ)
	if from_file == null:
		return false

	var to_file = FileAccess.open(to_path, FileAccess.WRITE)
	if to_file == null:
		from_file.close()
		return false

	var copied := 0
	while not from_file.eof_reached():
		var chunk = from_file.get_buffer(chunk_size)
		to_file.store_buffer(chunk)
		copied += chunk.size()
		call_deferred("emit_signal", "progress_updated", clamp(float(copied) / total_size, 0.0, 1.0))
		OS.delay_msec(1)  # Yield a little to avoid stalling the thread

	from_file.close()
	to_file.close()
	call_deferred("emit_signal", "progress_updated", 1.0)
	return true

func _get_file_size(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var size = file.get_length()
		file.close()
		return size
	return 0
