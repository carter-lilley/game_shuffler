extends Button

@onready var user_settings = $"../../../user_settings"

func _on_pressed() -> void:
	#Load game
	var curr_core = user_settings.core_nes
	var curr_sys = "nes"
	var curr_game = "Castlevania (USA) (Rev 1).nes"
	var args: PackedStringArray = ["-L" , user_settings.ra_cores_dir + curr_core , user_settings.rom_dir + "\\" + curr_sys + "\\" + curr_game]
	OS.create_process(user_settings.ra_local, args)
	#Load State (STAGE 15 - MEDUSA HALLWAY)
	OS.delay_msec(3000)
	var sfk = ProjectSettings.globalize_path("res://tools/sfk.exe")
	var sfk_args : PackedStringArray = ["udpsend", "localhost","55355","LOAD_STATE"]
	var result  = OS.execute(sfk, sfk_args)
	#Read Memory Address (DAMGE = FAIL, BOSS LOAD = SUCCESS)
	pass # Replace with function body.
