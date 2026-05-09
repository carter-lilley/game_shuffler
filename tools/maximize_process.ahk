; maximize_process.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe maximize_process.ahk <PID>
; Shows the main game window using transparency.
; Does NOT use WinShow because it can hang on suspended processes.

#NoTrayIcon
#SingleInstance Force
DetectHiddenWindows(true)
SetTitleMatchMode(2)

pid := A_Args[1]

; Find the main window: largest window with non-empty title (including hidden)
bestHwnd := 0
maxArea := 0

hwndList := WinGetList("ahk_pid " pid)
for hwnd in hwndList {
	if not WinExist(hwnd) {
		continue
	}
	
	title := WinGetTitle(hwnd)
	WinGetPos(&X, &Y, &W, &H, hwnd)
	area := W * H
	
	; Skip blank/helper windows (no title or tiny)
	if title = "" or area < 10000 {
		continue
	}
	
	if area > maxArea {
		maxArea := area
		bestHwnd := hwnd
	}
}

if bestHwnd = 0 {
	ExitApp(1)
}

; Restore opacity and position
WinSetTransparent(255, bestHwnd)
WinMove(0, 0, , , bestHwnd)
DllCall("SetWindowPos", "Ptr", bestHwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)

; Try to activate (non-blocking)
try WinActivate(bestHwnd)

ExitApp(0)
