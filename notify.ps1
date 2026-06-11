# Copilot CLI notification hook — shows a Windows toast via BurntToast.
#
# Reads a JSON payload on stdin:
#   { "hook_event_name": "...", "session_id": "...", "message": "..." }
# Caveat: clicking the toast spawns a new powershell window (Windows falls
# back to the spawning process when our AUMID has no registered activator).
# Don't click; just glance and switch to your terminal.

param(
    [string]$FallbackMessage = "Copilot is waiting for your response"
)

$ErrorActionPreference = 'SilentlyContinue'

$title   = "GitHub Copilot CLI"
$message = $FallbackMessage
$event   = $null

try {
    $raw = [Console]::In.ReadToEnd()
    if ($raw -and $raw.Trim().StartsWith("{")) {
        $payload = $raw | ConvertFrom-Json
        if ($payload.message)         { $message = [string]$payload.message }
        if ($payload.hook_event_name) { $event   = [string]$payload.hook_event_name }
        elseif ($payload.hookEventName) { $event = [string]$payload.hookEventName }
    }
} catch { }

$EventTitles = @{
    'agentStop'           = 'Copilot — Turn complete'
    'notification'        = 'Copilot — Needs your attention'
    'permissionRequest'   = 'Copilot — Permission needed'
    'errorOccurred'       = 'Copilot — Error'
    'postToolUseFailure'  = 'Copilot — Tool failed'
    'sessionStart'        = 'Copilot — Session started'
    'sessionEnd'          = 'Copilot — Session ended'
}
if ($event -and $EventTitles.ContainsKey($event)) {
    $title = $EventTitles[$event]
}

if ($message.Length -gt 250) { $message = $message.Substring(0, 247) + "..." }

try {
    Import-Module BurntToast -ErrorAction Stop
    $logoPath = Join-Path $env:LOCALAPPDATA 'GitHub\CopilotCLI\copilot-logo.png'
    $params = @{ Text = $title, $message }
    if (Test-Path $logoPath) { $params['AppLogo'] = $logoPath }
    New-BurntToastNotification @params
} catch { }
