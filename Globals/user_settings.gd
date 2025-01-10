extends Node

var system_dictionary : Dictionary

var polygon : PackedVector2Array = []
func _ready() -> void:
	#notifman.set_defaults()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var current_size = DisplayServer.window_get_size() 
	var v_button_bar_width = 60
	polygon = [Vector2(0,0),
				Vector2(v_button_bar_width,0),
				Vector2(v_button_bar_width,current_size.y),
				Vector2(0,current_size.y)]
	get_window().set_mouse_passthrough_polygon(polygon)
	#get_window().size = screen_size

#1600, 900
var screen_size: Vector2 = Vector2(1600,900)
#-------------------------------
var bag_size: int = 10
var round_time_min : float = 45.0
var round_time_max : float = 170.0 #148
#-------------------------------
var rom_dir: String = "Z:\\roms"
#--------- Standalones
var cemu_dir: String = "D:\\Emulation\\storage\\cemu\\Cemu.exe"
var lime3ds_dir: String = "D:\\Emulation\\storage\\lime3ds\\lime3ds.exe"
var dolphin_dir: String = "D:\\Emulation\\storage\\dolphin\\Dolphin.exe"
var pcsx2_dir: String = "D:\\Emulation\\storage\\pcsx2\\pcsx2-qt.exe"
var rpcs3_dir: String = "D:\\Emulation\\storage\\rpcs3\\rpcs3.exe"
var vita3k_dir: String = "D:\\Emulation\\storage\\Vita3k\\Vita3K.exe"
var xemu_dir: String = "D:\\Emulation\\storage\\xemu\\xemu.exe"
var xenia_dir: String = "D:\\Emulation\\storage\\xenia\\xenia_canary.exe"
var sudachi_dir: String = "D:\\Emulation\\storage\\sudachi\\sudachi.exe"
var ryujinx_dir: String = "D:\\Emulation\\storage\\ryujinx\\Ryujinx.exe"
#--------- RA
var ra_local: String = ProjectSettings.globalize_path("res://tools/retroarch/retroarch.exe")
var ra_cores_dir: String = ProjectSettings.globalize_path("res://tools/retroarch/cores")
#--------- CORES
var core_3do: String = "\\opera_libretro.dll"
var core_atari2600: String = "\\stella_libretro.dll"
var core_atarilynx: String = "\\handy_libretro.dll"
var core_atomiswave: String = "\\flycast_libretro.dll"
var core_c64: String = "\\vice_x64_libretro.dll"
var core_dos: String = "\\dosbox_pure_libretro.dll"
var core_dreamcast: String = "\\flycast_libretro.dll"
var core_gamegear: String = "\\genesis_plus_gx_libretro.dll"
var core_gameandwatch: String = "\\gw_libretro.dll"
var core_gc: String = "\\dolphin_libretro.dll"
var core_gb: String = "\\gambatte_libretro.dll"
var core_gba: String = "\\mgba_libretro.dll"
var core_gbc: String = "\\gambatte_libretro.dll"
var core_genesis: String = "\\genesis_plus_gx_libretro.dll"
var core_mame: String = "\\mame_libretro.dll"
var core_mastersystem: String = "\\genesis_plus_gx_libretro.dll"
var core_msx: String = "\\fmsx_libretro.dll"
var core_n3ds: String = "\\citra_libretro.dll"
var core_n64: String = "\\mupen64plus_next_libretro.dll"
var core_naomi: String = "\\flycast_libretro.dll"
var core_naomi2: String = "\\flycast_libretro.dll"
var core_nds: String = "\\melondsds_libretro.dll"
var core_nes: String = "\\mesen_libretro.dll"
var core_ngpc: String = "\\mednafen_ngp_libretro.dll"
var core_psp: String = "\\ppsspp_libretro.dll"
var core_psx: String = "\\swanstation_libretro.dll"
var core_ps2: String = "\\pcsx2_libretro.dll"
var core_saturn: String = "\\mednafen_saturn_libretro.dll"
var core_sega32x: String = "\\picodrive_libretro.dll"
var core_segacd: String = "\\genesis_plus_gx_libretro.dll"
var core_sg1000: String = "\\genesis_plus_gx_libretro.dll" #? special character
var core_snes: String = "\\snes9x_libretro.dll"
var core_tg16: String = "\\mednafen_pce_libretro.dll"
var core_tgcd: String = "\\mednafen_pce_libretro.dll" #? special character
var core_virtualboy: String = "\\mednafen_vb_libretro.dll"
var core_wii: String = "\\dolphin_libretro.dll" 
#---------
