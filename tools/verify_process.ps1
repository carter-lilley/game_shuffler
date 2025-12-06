param (
    [Parameter(Mandatory=$true)]
    [int]$TargetPid
)

try {
    $proc = Get-Process -Id $TargetPid -ErrorAction Stop
    Write-Output $true
} catch {
    Write-Output $false
}
