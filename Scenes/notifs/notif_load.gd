extends CanvasLayer
signal notif_complete

@onready var tex_rect = $VBoxContainer/TextureRect
@onready var loading_label = $VBoxContainer/TextureRect/Label
var load_time: float = 0.0

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	tex_rect.material.set_shader_parameter("transition_completeness", 1.0)
	globals.new_tween(tex_rect, "material:shader_parameter/transition_completeness", 0.0,.45, Tween.EASE_OUT, Tween.TRANS_QUART)
	globals.create_timer(load_time, clip_1)

func clip_1():
	globals.new_tween(tex_rect, "material:shader_parameter/transition_completeness", 1.0,.8, Tween.EASE_OUT, Tween.TRANS_CUBIC,0.0, false, end)
	
func end():
	emit_signal("notif_complete", self)
