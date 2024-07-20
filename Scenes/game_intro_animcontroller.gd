extends Control

@onready var boxart = $CenterContainer/TexturePivot/TextureRect
@onready var boxart_pivot = $CenterContainer/TexturePivot
@onready var center_container = $CenterContainer

var art_size
var screen_size
func _ready() -> void:
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	
	#set game art if applicable
	screen_size = center_container.get_rect().size
	art_size = boxart.get_rect().size
	call_deferred("_update_boxart_position")

func set_art(tex = Texture2D):
	boxart.texture = tex

var initial_pos
func _update_boxart_position():
	initial_pos = boxart_pivot.position
	boxart_pivot.position.y += screen_size.y/2
	boxart_pivot.position.y += art_size.y/2
	var box_tween = new_tween(boxart_pivot, "position", initial_pos, 0.7, Tween.EASE_OUT, Tween.TRANS_CIRC)
	#box_tween.tween_property(boxart_pivot, "position", Vector2(art_size.x/2,initial_pos.y), 1.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	box_tween.tween_property(boxart, "modulate:a", 0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func new_tween(node: Node, property: String, target: Variant, duration: float,
					_ease: Tween.EaseType = Tween.EASE_IN_OUT,
					_trans: Tween.TransitionType = Tween.TRANS_LINEAR, 
					relative: bool = false, 
					method = null) -> Tween:	
	var tween = node.create_tween()
	if method != null:
		tween.connect("finished", method)
	if relative:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).as_relative()
	else:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease)
	return tween
