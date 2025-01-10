function Check-GameProcess
{
    [CmdletBinding()]
    param (
        [int]$process_id = 0,
        [string]$expected_title = "RetroArch"
    )
    
    $result = @{
        IsRunning = $false
        WindowTitle = ""
        HasWindow = $false
        Error = ""
    }
    
    $process = Get-Process -Id $process_id -ErrorAction SilentlyContinue
    if ($process -ne $null) 
    {
        $result.IsRunning = $process.Responding
        
        if ($process.MainWindowHandle -ne 0) 
        {
            $result.HasWindow = $true
            $result.WindowTitle = $process.MainWindowTitle
            
            # Check if window title contains expected string
            if ($result.WindowTitle -like "*$expected_title*") 
            {
                $result.IsRunning = $true
            }
        }
        
        $result | ConvertTo-Json
    } 
    else 
    {
        @{
            IsRunning = $false
            Error = "Process not found or has no window"
        } | ConvertTo-Json
    }
}