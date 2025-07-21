extends Node
var timer_list: Array

#add ability to use existing tween?
func new_tween(node: Node, property: String, target: Variant, duration: float,
					_ease: Tween.EaseType = Tween.EASE_IN_OUT, _trans: Tween.TransitionType = Tween.TRANS_LINEAR, 
					delay: float = 0.0,
					relative: bool = false,
					method = null) -> Tween:	
	var tween = node.create_tween()
	if method != null:
		tween.connect("finished", method)
	if relative:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).as_relative().set_delay(delay)
	else:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).set_delay(delay)
	return tween

func timers_pause(state : bool):
	for timer in timer_list:
		if timer.is_inside_tree():
			timer.set_paused(state)
			print(timer, " set to ",state)	

func timers_kill():
	# Collect timers to remove
	var timers_to_remove = []
	for timer in timer_list:
		if timer.is_inside_tree():
			timer.stop()
			timer.queue_free()
			timers_to_remove.append(timer)
			print(timer, " stopped and queued for deletion")
	# Remove timers from the list
	for timer in timers_to_remove:
		timer_list.erase(timer)

func create_timer(secs: float, function: Callable, arg: Variant = null):
	var timer = Timer.new()
	timer.wait_time = secs
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)  
	timer_list.append(timer)
	timer.timeout.connect(func():
		if arg != null:
			function.call(arg)
		else:
			function.call()
		timer_list.erase(timer)
		timer.queue_free()
	)
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
	var _str: String
	if dir_arr.size() > 0:
		_str = dir_arr[randi_range(0, dir_arr.size()-1)]
	else: 
		push_error("No items found in: ",dir_arr)
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
