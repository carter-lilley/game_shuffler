; test_winshow.ahk
; Diagnostic: Test WinShow on a hidden notepad window

#NoTrayIcon
#SingleInstance Force

; Launch notepad
Run("notepad.exe", , , &pid)
Sleep(2000)

; Find the window
if not WinExist("ahk_pid " pid) {
	MsgBox("Could not find notepad window")
	ExitApp(1)
}

hwnd := WinExist("ahk_pid " pid)

; Hide it
WinHide(hwnd)
Sleep(500)

; Check if hidden
visible := DllCall("IsWindowVisible", "Ptr", hwnd)
if visible {
	MsgBox("Window is still visible after WinHide!")
	ExitApp(1)
}

; Show it
WinShow(hwnd)
Sleep(500)

; Check if visible again
visible2 := DllCall("IsWindowVisible", "Ptr", hwnd)
if not visible2 {
	MsgBox("Window is still hidden after WinShow!")
	ExitApp(1)
}

; Try to activate
try WinActivate(hwnd)
Sleep(500)

if WinActive(hwnd) {
	MsgBox("SUCCESS: Window is visible and active!")
} else {
	MsgBox("PARTIAL: Window is visible but NOT active")
}

; Cleanup
WinClose(hwnd)
ExitApp(0)
