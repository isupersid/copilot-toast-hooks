# Installs Copilot CLI toast-notification hooks on Windows.
# Run from the extracted folder:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'

$src       = $PSScriptRoot
$hooksDir  = Join-Path $env:USERPROFILE '.copilot\hooks'
$logoDir   = Join-Path $env:LOCALAPPDATA 'GitHub\CopilotCLI'
$hooksJson = Join-Path $hooksDir 'notification-hooks.json'

Write-Host "Installing Copilot toast hooks..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $hooksDir, $logoDir | Out-Null

# Back up any existing hooks file
if (Test-Path $hooksJson) {
    $backup = "$hooksJson.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $hooksJson $backup
    Write-Host "  Existing notification-hooks.json backed up to $backup" -ForegroundColor Yellow
}

# Rewrite hooks JSON with the current user's profile path baked in
$notifyPath = (Join-Path $hooksDir 'notify.ps1') -replace '\\','\\'
$hooks = [ordered]@{
    version = 1
    hooks = [ordered]@{
        agentStop = @(@{
            type        = 'command'
            powershell  = "& $notifyPath -FallbackMessage 'Copilot finished its turn — your input is needed'"
            timeoutSec  = 10
        })
        permissionRequest = @()
        notification = @(@{
            type        = 'command'
            powershell  = "& $notifyPath -FallbackMessage 'Copilot needs your attention'"
            timeoutSec  = 10
        })
    }
}
$hooks | ConvertTo-Json -Depth 6 | Set-Content -Path $hooksJson -Encoding UTF8

Copy-Item (Join-Path $src 'notify.ps1')         (Join-Path $hooksDir 'notify.ps1')  -Force
Copy-Item (Join-Path $src 'copilot-logo.png')   (Join-Path $logoDir  'copilot-logo.png') -Force

# Ensure BurntToast is available
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    Write-Host "  Installing BurntToast module (CurrentUser)..." -ForegroundColor Cyan
    try {
        Install-Module BurntToast -Scope CurrentUser -Force -AllowClobber
    } catch {
        Write-Warning "Could not auto-install BurntToast. Run: Install-Module BurntToast -Scope CurrentUser"
    }
}

Write-Host "Done. Restart Copilot CLI to pick up the hooks." -ForegroundColor Green
Write-Host "  Hooks:  $hooksDir"
Write-Host "  Logo:   $logoDir\copilot-logo.png"
