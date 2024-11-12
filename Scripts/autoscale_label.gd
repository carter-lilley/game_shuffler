extends Label

@onready var panel_container = $"../../.."
var base_font_size = 64  # Set your desired base font size here

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_font_size() # Replace with function body.
	panel_container.connect("resized", adjust_font_size)

func adjust_font_size():
	var max_width = panel_container.size.x
	var font_size = self.label_settings.get_font_size()
	
	# First, try increasing the font size up to the base font size
	while font_size <= base_font_size:
		self.label_settings.set_font_size(font_size)
		var string_size = self.get_theme_font("font").get_string_size(self.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if string_size.x > max_width:
			font_size -= 1
			self.label_settings.set_font_size(font_size)
			break
		font_size += 1
	
	# If necessary, decrease the font size to fit
	while font_size > 1:
		var string_size = self.get_theme_font("font").get_string_size(self.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if string_size.x <= max_width:
			break
		font_size -= 1
		self.label_settings.set_font_size(font_size)
	
	if font_size <= 1:
		font_size = 1
		self.label_settings.set_font_size(font_size)
