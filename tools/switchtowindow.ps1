function goto {
    [CmdletBinding()]
    param (
        [int]$process_id = 0
    )

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Program {
        [DllImport("user32.dll")]
        public static extern bool AllowSetForegroundWindow(int dwProcessId);
        
        [DllImport("user32.dll")]
        public static extern void SwitchToThisWindow(IntPtr hWnd, bool fAltTab);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        public const int SW_RESTORE = 9;  // Restores the window if minimized
    }
"@

    try {
        $process = Get-Process -Id $process_id -ErrorAction Stop
        if ($process -ne $null -and $process.MainWindowHandle -ne 0) {
            $hwnd = $process.MainWindowHandle
            
            # Allow the process to take foreground
            [Program]::AllowSetForegroundWindow($process_id) | Out-Null
            
            # Restore window if it's minimized
            [Program]::ShowWindow($hwnd, [Program]::SW_RESTORE)
            
            # Attempt to bring the window to the foreground
            [Program]::SetForegroundWindow($hwnd)

            Write-Host "Successfully switched to process with PID $process_id."
        } else {
            Write-Host "Process with PID $process_id is not running or does not have a MainWindowHandle."
        }
    } catch {
        Write-Host "Error: $_"
    }
}
