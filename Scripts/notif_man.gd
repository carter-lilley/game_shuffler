extends Node

@onready var notif_intro_asset = preload("res://Scenes/notifs/notif_intro.tscn")  # Load the scene as a PackedScene
func notif_intro(tex : Texture2D, title : String, system : String, release : String):
	var notif_intro = notif_intro_asset.instantiate()
	add_child(notif_intro)
	notif_intro.set_info(title,system,release)
	if tex:
		notif_intro.set_art(tex)

@onready var notif_reumse_asset = preload("res://Scenes/notifs/notif_resume.tscn")
func notif_resume(tex : Texture2D):
	var notif_resume = notif_reumse_asset.instantiate()
	add_child(notif_resume)
	if tex:
		notif_resume.set_art(tex)
