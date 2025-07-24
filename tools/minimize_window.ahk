; minimize_window.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe minimize_window.ahk <PID>

#NoTrayIcon
DetectHiddenWindows(true)
SetTitleMatchMode(2)

if A_Args.Length < 1 {
	MsgBox("No PID provided.`nUsage: minimize_window.ahk <PID>", "Error", 16)
	ExitApp(2)
}

pid := A_Args[1]

if WinExist("ahk_pid " pid) {
	WinHide()
	;WinMinimize()
	ExitApp(0)
} else {
	ExitApp(2)
}
