extends Node

# Counter for active notifications
var active_notifications: int = 0

@onready var notif_intro_asset = preload("res://Scenes/notifs/notif_intro.tscn")  # Load the scene as a PackedScene
func notif_intro(tex : Texture2D, title : String, system : String, release : String):
	notif_start()
	var notif_intro_inst = notif_intro_asset.instantiate()
	notif_intro_inst.connect("notif_complete",notif_compelte)
	add_child(notif_intro_inst)
	notif_intro_inst.set_info(title,system,release)
	if tex:
		notif_intro_inst.set_art(tex)

@onready var notif_load_asset = preload("res://Scenes/notifs/notif_load.tscn") 
func notif_load(passed_time : float):
	notif_start()
	var notif_load_asset = notif_load_asset.instantiate()
	notif_load_asset.load_time = passed_time
	notif_load_asset.connect("notif_complete",notif_compelte)
	add_child(notif_load_asset)
	return notif_load_asset

func notif_start():
# Increment the active notifications counter
	active_notifications += 1
	get_window().set_mouse_passthrough_polygon([])
	
func notif_compelte(caller : Node):
# Decrement the active notifications counter
	active_notifications -= 1
	caller.queue_free()
	globals.create_timer(0.5, set_polygon, active_notifications)

func set_polygon(notif_num : int):
	if notif_num <= 0:
		get_window().set_mouse_passthrough_polygon(usersettings.polygon)
