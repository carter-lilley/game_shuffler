; restore_activate.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe restore_activate.ahk <PID>

#NoTrayIcon
DetectHiddenWindows(true)
SetTitleMatchMode(2)

if A_Args.Length < 1 {
	MsgBox("No PID provided.`nUsage: restore_activate.ahk <PID>", "Error", 16)
	ExitApp(2)
}

pid := A_Args[1]

if WinExist("ahk_pid " pid) {
	WinShow("ahk_pid " pid)
	WinActivate("ahk_pid " pid)

	; Confirm window is active
	if WinActive("ahk_pid " pid) {
		ExitApp(0)  ; Success
	} else {
		ExitApp(1)  ; Failed to activate
	}
} else {
	ExitApp(1)  ; Window not found
}