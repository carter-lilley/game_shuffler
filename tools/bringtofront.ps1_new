function Show-Window([System.Diagnostics.Process] $process) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

    $process = Get-Process -Id $process_id
    if ($process -ne $null -and $process.MainWindowHandle -ne 0) {
        $hwnd = $process.MainWindowHandle
        [User32]::SetForegroundWindow($hwnd)
} 
else {
        Write-Host "Process with PID $process_id is not running or does not have a MainWindowHandle."
}
