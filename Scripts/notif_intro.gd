extends CanvasLayer
signal notif_complete
@onready var boxart = $CenterContainer/TexturePivot/TextureRect
@onready var boxart_pivot = $CenterContainer/TexturePivot
@onready var center_container = $CenterContainer

@onready var title_panel = $VBoxContainer/HBoxContainer/Title_Pivot/Panel
@onready var title_label = $VBoxContainer/HBoxContainer/Title_Pivot/Panel/HBoxContainer/VBoxContainer/Title
@onready var info_label = $VBoxContainer/HBoxContainer/Title_Pivot/Panel/HBoxContainer/VBoxContainer/Info
var art_size
var screen_size
	
func _ready() -> void:
	#anim_thread.start(setup)
	call_deferred("setup")

func setup() -> void:
	#Get screen size of center container
	screen_size = center_container.get_rect().size
	#Scale boxart to screen size
	boxart.custom_minimum_size.y = screen_size.y
	clip_1()

var initial_pos
func clip_1():
	initial_pos = boxart_pivot.position
	boxart_pivot.position.y += screen_size.y/2
	boxart_pivot.position.y += boxart.size.y/2
	#cover art tweens to middle screen
	globals.new_tween(boxart_pivot, "position", initial_pos, 0.7, Tween.EASE_OUT, Tween.TRANS_CIRC, 0.0, false, clip_2)

func clip_2():
	var box_tw = globals.new_tween(boxart_pivot, "position", Vector2(boxart.size.x/2,initial_pos.y), 1.7, Tween.EASE_IN_OUT, Tween.TRANS_CUBIC, 0.2, false)
	title_panel.custom_minimum_size.y = 200
	var panel_tw = globals.new_tween(title_panel, "custom_minimum_size", Vector2(screen_size.x-boxart.size.x,0),2.0, Tween.EASE_OUT, Tween.TRANS_QUINT, 0.8, true, clip_3)
	box_tw.tween_property(boxart, "modulate:a", 0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(1.2)
	#var panel_tw2 = new_tween(title_panel, "modulate:a", 0, 1.5, Tween.EASE_IN, Tween.TRANS_QUAD, 0.0, false)
	panel_tw.tween_property(title_panel, "modulate:a", 0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func clip_3():
	emit_signal("notif_complete")
	queue_free()

func set_info(title : String, system : String, release : String):
	title_label.text = title
	var infostr = system + " • " + release
	info_label.text = infostr
	pass

func set_art(tex = Texture2D):
	boxart.texture = tex
