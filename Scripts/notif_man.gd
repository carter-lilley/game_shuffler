extends Node

@onready var notif_intro_asset = preload("res://Scenes/notifs/notif_intro.tscn")  # Load the scene as a PackedScene
func notif_intro(tex : Texture2D, title : String, system : String, release : String):
	var notif_intro_inst = notif_intro_asset.instantiate()
	notif_intro_inst.connect("notif_complete",notif_compelte)
	add_child(notif_intro_inst)
	notif_intro_inst.set_info(title,system,release)
	if tex:
		notif_intro_inst.set_art(tex)

func notif_compelte():
	get_window().set_mouse_passthrough_polygon(usersettings.polygon)
	pass
