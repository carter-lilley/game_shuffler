; launch_emu.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe launch_emu.ahk <PID>
#NoTrayIcon

ExePath := "D:\Emulation\storage\retroarch\retroarch.exe"

Args := [
    "-L",
    "D:\Emulation\storage\retroarch\cores\gambatte_libretro.dll",
    "Z:\roms\gb\Addams Family, The - Pugsley's Scavenger Hunt (USA, Europe).gb"
]

; Build a correctly-quoted argument string
argString := ""
for arg in Args {
    if InStr(arg, " ") || InStr(arg, ",") {
        arg := '"' arg '"'   ; wrap only when needed
    }
    argString .= arg " "
}

Run(ExePath . " " . Trim(argString))
