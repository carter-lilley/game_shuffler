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

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetActiveWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern void SwitchToThisWindow(IntPtr hWnd, bool fAltTab);
        
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        public const int HWND_TOPMOST = -1;
        public const uint TOPMOST_FLAGS = 0x0002; // SWP_NOSIZE | SWP_NOMOVE
    }
"@

    $process = Get-Process -Id $process_id -ErrorAction SilentlyContinue
    if ($process -ne $null -and $process.MainWindowHandle -ne 0) {
        $hwnd = $process.MainWindowHandle

        # Attempt to bring the window to the foreground
        if ([Program]::SetForegroundWindow($hwnd)) {
            Write-Host "Successfully brought process with PID $process_id to the foreground."
        } elseif ([Program]::SwitchToThisWindow($hwnd, $false)) {
            Write-Host "SetForegroundWindow failed, trying SwitchToThisWindow."
            [Program]::SwitchToThisWindow($hwnd, $false)
        } else {
            Write-Host "Both SetForegroundWindow and SwitchToThisWindow failed, setting window as topmost."
            [Program]::SetWindowPos($hwnd, [Program]::HWND_TOPMOST, 0, 0, 0, 0, [Program]::TOPMOST_FLAGS) | Out-Null
            Write-Host "Set window with PID $process_id as topmost."
        }

        # Always try to set the window as active
        [Program]::SetActiveWindow($hwnd)
        Write-Host "SetActiveWindow called for process with PID $process_id."
    } 
    else 
    {
        Write-Host "Process with PID $process_id is not running or does not have a MainWindowHandle."
    }
}