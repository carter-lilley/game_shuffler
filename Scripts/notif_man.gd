extends Node

@onready var notif_intro_asset = preload("res://Scenes/notifs/notif_intro.tscn")  # Load the scene as a PackedScene
func notif_intro(tex : Texture2D, title : String, system : String, release : String):
	var notif_intro = notif_intro_asset.instantiate()
	add_child(notif_intro)
	notif_intro.set_info(title,system,release)
	if tex:
		notif_intro.set_art(tex)
