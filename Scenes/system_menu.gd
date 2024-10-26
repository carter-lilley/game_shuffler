extends CanvasLayer
signal update_and_close(caller,system_dict)

@onready var system_theme = preload("res://Themes/system_menu_theme.tres")
@onready var grid_container = $CenterContainer/GridContainer
var system_states := {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var system_list = globals.dir_contents(usersettings.rom_dir)
	for system in system_list:
		# Create button...
		var button = Button.new()
		button.custom_minimum_size = Vector2(225,150)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.theme = system_theme
		button.expand_icon = true
		button.toggle_mode = true
		button.self_modulate = Color(1, 1, 1, 1)  # Make button fully opaque
		match system:
			"3do":
				button.connect("toggled", _on_button_toggled.bind("3do"))
				system_states["3do"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/3DO Interactive Multiplayer.png")
			"atari2600":
				button.connect("toggled", _on_button_toggled.bind("atari2600"))
				system_states["atari2600"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Atari 2600.png")
			"atarilynx":
				button.connect("toggled", _on_button_toggled.bind("atarilynx"))
				system_states["atarilynx"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Atari Lynx.png")
			"dos":
				button.connect("toggled", _on_button_toggled.bind("dos"))
				system_states["dos"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/MS-DOS.png")
			"dreamcast":
				button.connect("toggled", _on_button_toggled.bind("dreamcast"))
				system_states["dreamcast"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega Dreamcast.png")
			"gamegear":
				button.connect("toggled", _on_button_toggled.bind("gamegear"))
				system_states["gamegear"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega Game Gear.png")
			"gb":
				button.connect("toggled", _on_button_toggled.bind("gb"))
				system_states["gb"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy.png")
			"gba":
				button.connect("toggled", _on_button_toggled.bind("gba"))
				system_states["gba"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy Advance.png")
			"gbc":
				button.connect("toggled", _on_button_toggled.bind("gbc"))
				system_states["gbc"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Game Boy Color.png")
			"gc":
				button.connect("toggled", _on_button_toggled.bind("gc"))
				system_states["gc"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo GameCube.png")
			"genesis":
				button.connect("toggled", _on_button_toggled.bind("genesis"))
				system_states["genesis"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega Genesis.png")
			"mame":
				button.connect("toggled", _on_button_toggled.bind("mame"))
				system_states["mame"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/MAME.png")
			"mastersystem":
				button.connect("toggled", _on_button_toggled.bind("mastersystem"))
				system_states["mastersystem"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega Master System.png")
			"n3ds":
				button.connect("toggled", _on_button_toggled.bind("n3ds"))
				system_states["n3ds"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo 3DS.png")
			"n64":
				button.connect("toggled", _on_button_toggled.bind("n64"))
				system_states["n64"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo 64.png")
			"nds":
				button.connect("toggled", _on_button_toggled.bind("nds"))
				system_states["nds"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo DS.png")
			"nes":
				button.connect("toggled", _on_button_toggled.bind("nes"))
				system_states["nes"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Entertainment System.png")
			"ngpc":
				button.connect("toggled", _on_button_toggled.bind("ngpc"))
				system_states["ngpc"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/SNK Neo Geo Pocket Color.png")
			"ps2":
				button.connect("toggled", _on_button_toggled.bind("ps2"))
				system_states["ps2"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 2.png")
			"ps3":
				button.connect("toggled", _on_button_toggled.bind("ps3"))
				system_states["ps3"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 3.png")
			"ps4":
				button.connect("toggled", _on_button_toggled.bind("ps4"))
				system_states["ps4"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation 4.png")
			"psp":
				button.connect("toggled", _on_button_toggled.bind("psp"))
				system_states["psp"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony PSP.png")
			"psvita":
				button.connect("toggled", _on_button_toggled.bind("psvita"))
				system_states["psvita"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony PS Vita.png")
			"psx":
				button.connect("toggled", _on_button_toggled.bind("psx"))
				system_states["psx"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sony Playstation.png")
			"saturn":
				button.connect("toggled", _on_button_toggled.bind("saturn"))
				system_states["saturn"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega Saturn (Japan).png")
			"sega32x":
				button.connect("toggled", _on_button_toggled.bind("sega32x"))
				system_states["sega32x"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega 32X.png")
			"segacd":
				button.connect("toggled", _on_button_toggled.bind("segacd"))
				system_states["segacd"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega CD.png")
			"sg1000":
				button.connect("toggled", _on_button_toggled.bind("sg1000"))
				system_states["sg1000"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Sega SG-1000.png")
			"snes":
				button.connect("toggled", _on_button_toggled.bind("snes"))
				system_states["snes"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Super Nintendo Entertainment System.png")
			"steam":
				button.connect("toggled", _on_button_toggled.bind("steam"))
				system_states["steam"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Steam.png")
			"switch":
				button.connect("toggled", _on_button_toggled.bind("switch"))
				system_states["switch"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Switch.png")
			"tg16":
				button.connect("toggled", _on_button_toggled.bind("tg16"))
				system_states["tg16"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/NEC TurboGrafx-16.png")
			"tgcd":
				button.connect("toggled", _on_button_toggled.bind("tgcd"))
				system_states["tgcd"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/NEC TurboGrafx-CD.png")
			"wii":
				button.connect("toggled", _on_button_toggled.bind("wii"))
				system_states["wii"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Wii.png")
			"wiiu":
				button.connect("toggled", _on_button_toggled.bind("wiiu"))
				system_states["wiiu"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Nintendo Wii U.png")
			"xbox":
				button.connect("toggled", _on_button_toggled.bind("xbox"))
				system_states["xbox"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Microsoft Xbox.png")
			"xbox360":
				button.connect("toggled", _on_button_toggled.bind("xbox360"))
				system_states["xbox360"] = {"state": true}
				button.icon = preload("res://Sprites/ui_logos/Microsoft Xbox 360.png")
		grid_container.add_child(button)

func _on_button_toggled(toggled: bool, system : String) -> void:
	if toggled:
		system_states[system]["state"] = false
		print(system_states)
	else:
		system_states[system]["state"] = false

func _on_none_pressed() -> void:
	for system in system_states:
		system_states[system]["state"] = false
		print(system_states)
	for button in grid_container.get_children():
		button.set_pressed_no_signal(true)

func _on_all_pressed() -> void:
	for system in system_states:
		system_states[system]["state"] = true
		print(system_states)
	for button in grid_container.get_children():
		button.set_pressed_no_signal(false)

func _on_close_pressed() -> void:
	emit_signal("update_and_close", self, system_states)
	self.queue_free()
