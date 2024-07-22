extends Node

var bag_size: int = 12
var round_time_min : float = 45.0
var round_time_max : float = 180.0
#-------------------------------
var rom_dir: String = "Z:\\roms"
#--------- RA
var ra_dir: String = "D:\\Emulation\\storage\\retroarch"
var ra: String = ra_dir + "\\retroarch.exe"
var ra_cores_dir: String = ra_dir + "\\cores"
#--------- CORES
var core_3do: String = "\\opera_libretro.dll"
var core_atari2600: String = "\\stella_libretro.dll"
var core_atarilynx: String = "\\handy_libretro.dll"
var core_dos: String = "\\dosbox_pure_libretro.dll"
var core_dreamcast: String = "\\flycast_libretro.dll"
var core_gamegear: String = "\\genesis_plus_gx_libretro.dll"
var core_gb: String = "\\gambatte_libretro.dll"
var core_gba: String = "\\mgba_libretro.dll"
var core_gbc: String = "\\gambatte_libretro.dll"
#var core_gc: String = "\\mesen_libretro"
var core_genesis: String = "\\genesis_plus_gx_libretro.dll"
var core_mastersystem: String = "\\genesis_plus_gx_libretro.dll"
#var core_n3ds: String = "\\mesen_libretro"
var core_n64: String = "\\mupen64plus_next_libretro.dll"
var core_nds: String = "\\melonds_libretro.dll"
var core_neogeo: String = "\\fbalpha2012_neogeo_libretro.dll"
var core_nes: String = "\\mesen_libretro.dll"
var core_ngpc: String = "\\mednafen_ngp_libretro.dll"
#var core_ps2: String = "\\mesen_libretro"
#var core_ps3: String = "\\mesen_libretro"
var core_psp: String = "\\ppsspp_libretro.dll"
#var core_psvita
#var core_psx: String = "\\mesen_libretro"
var core_saturn: String = "\\mednafen_saturn_libretro.dll"
var core_sega32x: String = "\\picodrive_libretro.dll"
var core_segacd: String = "\\genesis_plus_gx_libretro.dll"
var core_sg1000: String = "\\genesis_plus_gx_libretro.dll" #? special character
var core_snes: String = "\\snes9x_libretro.dll"
#var core_switch: String = "\\mesen_libretro"
var core_tg16: String = "\\mednafen_pce_libretro.dll"
var core_tgcd: String = "\\mednafen_pce_libretro.dll" #? special character
#var core_wii: String = "\\mesen_libretro"
#var core_wiiu
#var core_xbox
#var core_xbox360
#---------