param(
    [Parameter(Mandatory=$true)]
    [int]$ProcessId,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("suspend", "resume")]
    [string]$Action
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;

public class ThreadManager {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenThread(uint dwDesiredAccess, bool bInheritHandle, int dwThreadId);
    
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
    
    [DllImport("kernel32.dll")]
    public static extern int SuspendThread(IntPtr hThread);
    
    [DllImport("kernel32.dll")]
    public static extern int ResumeThread(IntPtr hThread);
    
    [DllImport("kernel32.dll")]
    public static extern bool GetLastError();
    
    public const uint THREAD_SUSPEND_RESUME = 0x0002;
}
"@

try {
    $proc = Get-Process -Id $ProcessId -ErrorAction Stop
    $successCount = 0
    $failCount = 0
    
    foreach ($thread in $proc.Threads) {
        $handle = [ThreadManager]::OpenThread([ThreadManager]::THREAD_SUSPEND_RESUME, $false, $thread.Id)
        
        if ($handle -eq [IntPtr]::Zero) {
            $failCount++
            continue
        }
        
        try {
            if ($Action -eq "suspend") {
                $result = [ThreadManager]::SuspendThread($handle)
                if ($result -ge 0) { $successCount++ } else { $failCount++ }
            } else {
                $result = [ThreadManager]::ResumeThread($handle)
                if ($result -ge 0) { $successCount++ } else { $failCount++ }
            }
        } finally {
            [ThreadManager]::CloseHandle($handle) | Out-Null
        }
    }
    
    Write-Output "OK:$Action $successCount threads, failed $failCount"
    exit 0
} catch {
    Write-Error "Failed to $Action process ${ProcessId}: $_"
    exit 1
}
