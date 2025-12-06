; maximize_process.ahk
; AHK v2.0+
; Usage: AutoHotkey.exe maximize_process.ahk <PID>

#NoTrayIcon
#SingleInstance Force
DetectHiddenWindows(true)
SetTitleMatchMode(2)

pid := A_Args[1]


try
{
    if WinExist("ahk_pid " pid)
    {
        WinShow("ahk_pid " pid)
        WinActivate("ahk_pid " pid)

        if WinActive("ahk_pid " pid)
        {
            ExitApp(0)  ; Success
        }
        else
        {
            ExitApp(1)  ; Failed to activate
        }
    }
    else
    {
        ExitApp(1)  ; Window not found
    }
}
catch
{
    ExitApp(1)  ; Treat any error as failure
}