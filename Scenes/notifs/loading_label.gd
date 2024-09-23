extends Label

# Define the sequence of dots
var dot_states = [".", "..", "...", "..", "."]
var current_state_index = 0
var interval_seconds = 0.5  # Time between each state change

func _ready():
	# Start the loop
	animate_loading_dots()

func animate_loading_dots():
	while true:
		# Update the label text with the current dots
		text = "LOADING" + dot_states[current_state_index]
		# Move to the next state in the sequence
		current_state_index = (current_state_index + 1) % dot_states.size()
		# Wait for the specified interval before continuing the loop
		await get_tree().create_timer(interval_seconds).timeout
