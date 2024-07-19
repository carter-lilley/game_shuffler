function goto 
{
[CmdletBinding()]
    param (
        [int]$process_id = 0
    )

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Program {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

    $process = Get-Process -Id $process_id
    if ($process -ne $null -and $process.MainWindowHandle -ne 0) {
        $hwnd = $process.MainWindowHandle
        [Program]::SetForegroundWindow($hwnd)
    } else {
        Write-Host "Process with PID $process_id is not running or does not have a MainWindowHandle."
    }
}