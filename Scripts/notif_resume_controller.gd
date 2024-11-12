extends Control

@onready var boxart = $CenterContainer/TexturePivot/TextureRect
@onready var boxart_pivot = $CenterContainer/TexturePivot
@onready var screen_container = $CenterContainer

var screen_size
func _ready() -> void:
	call_deferred("setup")

var effective_width
var effective_height
func setup() -> void:
	#Get screen size of center container
	screen_size = get_viewport().size
	#Scale boxart to 10% screen size
	var desired_height = screen_size.y * 0.25
	var texture_size = boxart.texture.get_size()
	# Calculate the effective width and height
	var aspect_ratio = texture_size.x / texture_size.y
	effective_width = desired_height * aspect_ratio
	effective_height = desired_height
	# Set the custom minimum size
	boxart.custom_minimum_size = Vector2(effective_width, effective_height)
	boxart_pivot.position.x = effective_width / 2
	boxart_pivot.position.y = screen_size.y + (effective_height / 2)
	clip_1()

func clip_1():
	new_tween(boxart_pivot, "position", Vector2(0,-effective_height), 0.7, Tween.EASE_OUT, Tween.TRANS_CIRC, 0.0, true)

func set_art(tex = Texture2D):
	boxart.texture = tex

#add ability to use existing tween?
func new_tween(node: Node, property: String, target: Variant, duration: float,
					_ease: Tween.EaseType = Tween.EASE_IN_OUT, _trans: Tween.TransitionType = Tween.TRANS_LINEAR, 
					delay: float = 0.0,
					relative: bool = false,
					method = null) -> Tween:	
	var tween = node.create_tween()
	if method != null:
		tween.connect("finished", method)
	if relative:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).as_relative().set_delay(delay)
	else:
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).set_delay(delay)
	return tween
