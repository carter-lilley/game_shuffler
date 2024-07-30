extends Node
var timer_list: Array

func kill_timers():
	for timer in timer_list:
		if timer.is_inside_tree():
			timer.stop()
			timer.queue_free()
			print("Timer stopped and queued for deletion")	

func create_timer(secs: float, function: Callable, arg: Variant):
	var timer = Timer.new()
	timer.wait_time = secs
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)  # Add the timer as a child of the current node (assuming this is a Node or Control)
	# Connect the timeout signal to call the specified function
	timer.timeout.connect(function.bind(arg))
	timer_list.append(timer)
	print(timer_list)
	return timer

func dir_contents(path) -> PackedStringArray:
	var dir = DirAccess.open(path)
	var dir_arr : PackedStringArray
	if dir:
		dir.list_dir_begin()
		var entry = dir.get_next()
		while entry != "":
			if dir.current_is_dir():
				dir_arr.append(entry)
				#print("Found dir: " + entry)
			#else:
				#print("Found file: " + entry)
			entry = dir.get_next()
		return dir_arr
	else:
		print("An error occurred when trying to access the path.")
		return dir_arr

func rand_string(dir_arr: PackedStringArray) -> String:
	var _str: String = dir_arr[randi() % dir_arr.size()]
	return _str

func sanitize_string(input: String) -> String:
	#print(input)
	# Remove text after period
	var sanitized_input = input.split(".")[0]  # Remove the period and everything after it
	sanitized_input = sanitized_input.strip_edges()  # Remove leading and trailing whitespace
	# Use a regular expression to remove text within parentheses
	var regex = RegEx.new()
	regex.compile("\\s*\\([^()]*\\)\\s*")  # Matches text within parentheses and surrounding spaces
	for i in 3:
		sanitized_input = regex.sub(sanitized_input, "")
	# Remove version numbers like "v1", "v2", "v3.0"
	regex.compile("\\bv\\d+(\\.\\d+)?\\b")  # Matches "v1", "v2.0", etc.
	sanitized_input = regex.sub(sanitized_input, "")
	# Escape quotes if necessary
	sanitized_input = sanitized_input.replace('"', '\\"')
	#print(sanitized_input)
	return sanitized_input
