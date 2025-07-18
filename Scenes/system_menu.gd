extends CanvasLayer
signal menu_close

@onready var system_theme = preload("res://Themes/system_menu_theme.tres")
@onready var grid_container = $CenterContainer/GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_system_menu()

func initialize_systems():
	var system_list = globals.dir_contents(usersettings.rom_dir)
	for system in system_list:
		if usersettings.sys_default.has(system):
			var default_state = usersettings.sys_default[system].get("default_state", true)
			if default_state:
				usersettings.systems[system] = true
		else:
			push_warning("System '%s' found in rom_dir but not defined in sys_default." % system)

func create_system_menu():
	for system in usersettings.systems:
		# Create button...
		var button = Button.new()
		button.custom_minimum_size = Vector2(200,100)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.theme = system_theme
		button.expand_icon = true
		button.toggle_mode = true
		button.connect("toggled", _on_button_toggled.bind(system))
		button.icon = usersettings.sys_default[system]["icon"]
		grid_container.add_child(button)

func _on_button_toggled(toggled: bool, system : String) -> void:
	if toggled:
		print(system, " set to false")
		usersettings.systems[system] = false
	else:
		print(system, " set to true")
		usersettings.systems[system] = true

func _on_none_pressed() -> void:
	for system in usersettings.systems:
		usersettings.systems[system] = false
	for button in grid_container.get_children():
		button.set_pressed_no_signal(true)

func _on_all_pressed() -> void:
	for system in usersettings.systems:
		usersettings.systems[system]= true
	for button in grid_container.get_children():
		button.set_pressed_no_signal(false)

func _on_close_pressed() -> void:
	print("Updated user settings...")
	print(usersettings.systems)
	queue_free()
	emit_signal("menu_close")
