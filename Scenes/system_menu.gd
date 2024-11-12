extends CanvasLayer
signal notif_complete

@onready var system_theme = preload("res://Themes/system_menu_theme.tres")
@onready var grid_container = $CenterContainer/GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_system_menu()

# Function to initialize system states
var system_states := {}
var system_list : PackedStringArray
func initialize_system_states():
	system_list = globals.dir_contents(usersettings.rom_dir)
	for system in system_list:
		match system:
			"ps4", "steam":
				system_states[system] = {"state": false}
			_:
				system_states[system] = {"state": true}
	
func create_system_menu():
	for system in usersettings.system_dictionary:
		# Create button...
		var button = Button.new()
		button.custom_minimum_size = Vector2(225,150)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.theme = system_theme
		button.expand_icon = true
		button.toggle_mode = true
		match system:
			"3do":
				button.connect("toggled", _on_button_toggled.bind("3do"))
				button.icon = preload("res://Sprites/ui_logos/3DO Interactive Multiplayer.png")
			"atari2600":
				button.connect("toggled", _on_button_toggled.bind("atari2600"))
				button.icon = preload("res://Sprites/ui_logos/Atari 2600.png")
			"atarilynx":
				button.connect("toggled", _on_button_toggled.bind("atarilynx"))
				button.icon = preload("res://Sprites/ui_logos/Atari Lynx.png")
			"c64":
				button.connect("toggled", _on_button_toggled.bind("c64"))
				button.icon = preload("res://Sprites/ui_logos/Commodore 64.png")
			"dos":
				button.connect("toggled", _on_button_toggled.bind("dos"))
				button.icon = preload("res://Sprites/ui_logos/MS-DOS.png")
			"dreamcast":
				button.connect("toggled", _on_button_toggled.bind("dreamcast"))
				button.icon = preload("res://Sprites/ui_logos/Sega Dreamcast.png")
			"gamegear":
				button.connect("toggled", _on_button_toggled.bind("gamegear"))
				button.icon = preload("res://Sprites/ui_logos/Sega Game Gear.png")
			"gb":
				button.connect("toggled", _on_button_toggled.bind("gb"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy.png")
			"gba":
				button.connect("toggled", _on_button_toggled.bind("gba"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy Advance.png")
			"gbc":
				button.connect("toggled", _on_button_toggled.bind("gbc"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy Color.png")
			"gc":
				button.connect("toggled", _on_button_toggled.bind("gc"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo GameCube.png")
			"genesis":
				button.connect("toggled", _on_button_toggled.bind("genesis"))
				button.icon = preload("res://Sprites/ui_logos/Sega Genesis.png")
			"mame":
				button.connect("toggled", _on_button_toggled.bind("mame"))
				button.icon = preload("res://Sprites/ui_logos/MAME.png")
			"mastersystem":
				button.connect("toggled", _on_button_toggled.bind("mastersystem"))
				button.icon = preload("res://Sprites/ui_logos/Sega Master System.png")
			"msx":
				button.connect("toggled", _on_button_toggled.bind("msx"))
				#button.set_pressed_no_signal(true)
				button.icon = preload("res://Sprites/ui_logos/Microsoft MSX.png")
			"n3ds":
				button.connect("toggled", _on_button_toggled.bind("n3ds"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo 3DS.png")
			"n64":
				button.connect("toggled", _on_button_toggled.bind("n64"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo 64.png")
			"nds":
				button.connect("toggled", _on_button_toggled.bind("nds"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo DS.png")
			"nes":
				button.connect("toggled", _on_button_toggled.bind("nes"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Entertainment System.png")
			"ngpc":
				button.connect("toggled", _on_button_toggled.bind("ngpc"))
				button.icon = preload("res://Sprites/ui_logos/SNK Neo Geo Pocket Color.png")
			"ps2":
				button.connect("toggled", _on_button_toggled.bind("ps2"))
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 2.png")
			"ps3":
				button.connect("toggled", _on_button_toggled.bind("ps3"))
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 3.png")
			"ps4":
				button.connect("toggled", _on_button_toggled.bind("ps4"))
				button.set_pressed_no_signal(true)
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 4.png")
			"psp":
				button.connect("toggled", _on_button_toggled.bind("psp"))
				button.icon = preload("res://Sprites/ui_logos/Sony PSP.png")
			"psvita":
				button.connect("toggled", _on_button_toggled.bind("psvita"))
				button.icon = preload("res://Sprites/ui_logos/Sony PS Vita.png")
			"psx":
				button.connect("toggled", _on_button_toggled.bind("psx"))
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation.png")
			"saturn":
				button.connect("toggled", _on_button_toggled.bind("saturn"))
				button.icon = preload("res://Sprites/ui_logos/Sega Saturn (Japan).png")
			"sega32x":
				button.connect("toggled", _on_button_toggled.bind("sega32x"))
				button.icon = preload("res://Sprites/ui_logos/Sega 32X.png")
			"segacd":
				button.connect("toggled", _on_button_toggled.bind("segacd"))
				button.icon = preload("res://Sprites/ui_logos/Sega CD.png")
			"sg1000":
				button.connect("toggled", _on_button_toggled.bind("sg1000"))
				button.icon = preload("res://Sprites/ui_logos/Sega SG-1000.png")
			"snes":
				button.connect("toggled", _on_button_toggled.bind("snes"))
				button.icon = preload("res://Sprites/ui_logos/Super Nintendo Entertainment System.png")
			"steam":
				button.connect("toggled", _on_button_toggled.bind("steam"))
				button.set_pressed_no_signal(true)
				button.icon = preload("res://Sprites/ui_logos/Steam.png")
			"switch":
				button.connect("toggled", _on_button_toggled.bind("switch"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Switch.png")
			"tg16":
				button.connect("toggled", _on_button_toggled.bind("tg16"))
				button.icon = preload("res://Sprites/ui_logos/NEC TurboGrafx-16.png")
			"tgcd":
				button.connect("toggled", _on_button_toggled.bind("tgcd"))
				button.icon = preload("res://Sprites/ui_logos/NEC TurboGrafx-CD.png")
			"wii":
				button.connect("toggled", _on_button_toggled.bind("wii"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Wii.png")
			"wiiu":
				button.connect("toggled", _on_button_toggled.bind("wiiu"))
				button.icon = preload("res://Sprites/ui_logos/Nintendo Wii U.png")
			"win3x":
				button.set_pressed_no_signal(true)
				button.connect("toggled", _on_button_toggled.bind("win3x"))
				button.icon = preload("res://Sprites/ui_logos/Windows 3.x.png")
			"xbox":
				button.connect("toggled", _on_button_toggled.bind("xbox"))
				button.icon = preload("res://Sprites/ui_logos/Microsoft Xbox.png")
			"xbox360":
				button.connect("toggled", _on_button_toggled.bind("xbox360"))
				button.icon = preload("res://Sprites/ui_logos/Microsoft Xbox 360.png")
		grid_container.add_child(button)

func _on_button_toggled(toggled: bool, system : String) -> void:
	if toggled:
		print(system, " set to false")
		usersettings.system_dictionary[system]["state"] = false
	else:
		print(system, " set to true")
		usersettings.system_dictionary[system]["state"] = true

func _on_none_pressed() -> void:
	for system in usersettings.system_dictionary:
		usersettings.system_dictionary[system]["state"] = false
	for button in grid_container.get_children():
		button.set_pressed_no_signal(true)

func _on_all_pressed() -> void:
	for system in usersettings.system_dictionary:
		usersettings.system_dictionary[system]["state"] = true
	for button in grid_container.get_children():
		button.set_pressed_no_signal(false)

func _on_close_pressed() -> void:
	print("Updated user settings...")
	print(usersettings.system_dictionary)
	emit_signal("notif_complete", self)
