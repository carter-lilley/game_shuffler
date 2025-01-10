extends Node

# Counter for active notifications
var active_notifs: int = 0

func _ready() -> void:
	set_defaults()

@onready var notif_intro_asset = preload("res://Scenes/notifs/notif_intro.tscn")  # Load the scene as a PackedScene

func notif_intro(tex : Texture2D, title : String, system : String, release : String):
	var notif_intro_inst = notif_intro_asset.instantiate()
	notif_intro_inst.connect("notif_complete",notif_end)
	add_child(notif_intro_inst)
	notif_start()
	notif_intro_inst.set_info(title,system,release)
	if tex:
		notif_intro_inst.set_art(tex)


@onready var notif_load_asset = preload("res://Scenes/notifs/notif_load.tscn") 
func notif_load():
	var notif_load_inst = notif_load_asset.instantiate()
	notif_load_inst.connect("notif_complete",notif_end)
	add_child(notif_load_inst)
	notif_start()
	return notif_load_inst

@onready var settings_menu_asset = preload("res://Scenes/system_menu.tscn") 
func notif_settings():
	var settings_menu = settings_menu_asset.instantiate()
	settings_menu.connect("menu_close",notif_end)
	notif_start()
	add_child(settings_menu)
	return settings_menu

func set_defaults():
	var settings_menu = settings_menu_asset.instantiate()
	settings_menu.initialize_system_states()
	print("Default settings initialized. ")
	usersettings.system_dictionary = settings_menu.system_states
	settings_menu.queue_free()

func update_list(system_dic: Dictionary):
	print("List updated.")
	print(system_dic)
	usersettings.system_dictionary = system_dic
		
var screen_poly : bool = false
func notif_start():
	active_notifs += 1
	if active_notifs > 0 and !screen_poly:
		print("Notifman: Fullscreen poly enabled. Active notifs: ", active_notifs)
		screen_poly = true
		get_window().set_mouse_passthrough_polygon([])
	
func notif_end():
# Decrement the active notifications counter
	active_notifs -= 1
	if active_notifs == 0:
		print("Notifman: Fullscreen poly disabled. Active notifs: ", active_notifs)
		screen_poly = false
		get_window().set_mouse_passthrough_polygon(usersettings.polygon)
