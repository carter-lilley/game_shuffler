; minimize_window.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe minimize_window.ahk <PID>
; Hides the main game window using transparency (works on suspended processes).
; Does NOT use WinHide because WinHide cannot be reversed on suspended processes.

#NoTrayIcon
#SingleInstance Force
DetectHiddenWindows(true)
SetTitleMatchMode(2)

if A_Args.Length < 1 {
	MsgBox("No PID provided.`nUsage: minimize_window.ahk <PID>", "Error", 16)
	ExitApp(2)
}

pid := A_Args[1]

; Find the main window: largest visible window with non-empty title
bestHwnd := 0
maxArea := 0

hwndList := WinGetList("ahk_pid " pid)
for hwnd in hwndList {
	if not WinExist(hwnd) {
		continue
	}
	if not DllCall("IsWindowVisible", "Ptr", hwnd) {
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
	ExitApp(2)
}

; Make transparent and move off-screen (works even on suspended processes)
WinSetTransparent(0, bestHwnd)
WinMove(-32000, -32000, , , bestHwnd)
DllCall("SetWindowPos", "Ptr", bestHwnd, "Ptr", 1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
WinSetAlwaysOnTop(0, bestHwnd)

ExitApp(0)
