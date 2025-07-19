extends CanvasLayer
signal notif_complete

@onready var tex_rect = $VBoxContainer/TextureRect
@onready var loading_label = $VBoxContainer/TextureRect/Label

var closing: bool = false
func close() -> void:
	closing = true
	tex_rect.material.set_shader_parameter("transition_completeness", 1.0)
	globals.new_tween(tex_rect, "material:shader_parameter/transition_completeness", 0.0,.45, Tween.EASE_OUT, Tween.TRANS_QUART,0.0, false, closed)

func closed() -> void:
	closing = false

func open():
	if closing:
		await get_tree().create_timer(0.5).timeout
		open()
		return
	globals.new_tween(tex_rect, "material:shader_parameter/transition_completeness", 1.0,.8, Tween.EASE_OUT, Tween.TRANS_CUBIC,0.0, false, end)
	
func end():
	emit_signal("notif_complete")
	queue_free()
