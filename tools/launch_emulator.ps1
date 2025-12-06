param (
    [Parameter(Mandatory = $true)]
    [string]$ExePath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Resolve working directory to the folder containing the executable
$WorkingDir = Split-Path -Parent $ExePath

# Escape arguments for Start-Process if they contain spaces or special chars
$ArgumentListEscaped = @()
foreach ($arg in $Args) {
    if ($null -ne $arg -and $arg -ne '') {
        if ($arg -match '[\s&()]') {
            $ArgumentListEscaped += '"' + $arg + '"'
        } else {
            $ArgumentListEscaped += $arg
        }
    }
}

# Debug output: show the full command that will be executed
# Write-Host "Debug: Start-Process command:"
#Write-Host "Start-Process -FilePath `"$ExePath`" -ArgumentList $($ArgumentListEscaped -join ' ') -WorkingDirectory `"$WorkingDir`""

# Start the process and return the PID
try {
    $proc = Start-Process -FilePath $ExePath -ArgumentList $ArgumentListEscaped -WorkingDirectory $WorkingDir -PassThru
    Write-Output $proc.Id
} catch {
    Write-Error "Failed to start process: $_"
    exit 1
}
