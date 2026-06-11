# Copilot CLI Toast Notifications (Windows)

Pops a native Windows toast — with the Copilot logo — whenever GitHub Copilot
CLI finishes a turn or asks for your attention, so you can switch away from
the terminal without losing track of long-running agent work.

Uses the [BurntToast] PowerShell module under the hood.

---

## TL;DR — point your agent at this repo

If you already use Copilot CLI (or any coding agent), just paste this into a
fresh session and you're done:

> Install the Copilot CLI toast notification hooks from
> https://github.com/isupersid/copilot-toast-hooks by downloading the latest
> release zip, extracting it, and running `install.ps1`. Then restart me.

The agent will fetch the release, unpack it into a temp dir, and run the
installer. No manual steps.

## TL;DR — install it yourself

```powershell
# 1. Download + extract the latest release
$zip = "$env:TEMP\copilot-toast-hooks.zip"
$dir = "$env:TEMP\copilot-toast-hooks"
Invoke-WebRequest `
  https://github.com/isupersid/copilot-toast-hooks/releases/latest/download/copilot-toast-hooks.zip `
  -OutFile $zip
Expand-Archive -Force $zip $dir

# 2. Run the installer
powershell -ExecutionPolicy Bypass -File "$dir\install.ps1"

# 3. Restart `copilot`
```

---

## Requirements

- Windows 10 / 11
- **PowerShell 7.0+** (`pwsh`) — required by Copilot CLI for hooks on Windows.
  Install with `winget install Microsoft.PowerShell` and restart your terminal.
- GitHub Copilot CLI (`copilot`)
- [BurntToast] — the installer will `Install-Module BurntToast -Scope CurrentUser`
  for you if it's missing

## Install location

Per the [official Copilot CLI hooks docs][docs], user-level hooks on Windows
live in `%USERPROFILE%\.copilot\hooks\`, or `%COPILOT_HOME%\hooks\` if the
`COPILOT_HOME` environment variable is set. The installer in this repo
respects `COPILOT_HOME` and writes to the correct location automatically.
Copilot CLI reads hook config at startup, so **restart `copilot` after
installing**.

[docs]: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks#user-level-example-for-windows

## What gets installed

| File | Destination |
| ---- | ----------- |
| `notify.ps1` | `<hooks dir>\notify.ps1` |
| `notification-hooks.json` | `<hooks dir>\notification-hooks.json` (regenerated with your own profile path; any existing file is backed up as `.bak-<timestamp>`) |
| `copilot-logo.png` | `%LOCALAPPDATA%\GitHub\CopilotCLI\copilot-logo.png` (used as the toast app icon) |

Where `<hooks dir>` is `%COPILOT_HOME%\hooks\` if `COPILOT_HOME` is set,
otherwise `%USERPROFILE%\.copilot\hooks\` — matching the [official docs][docs].

The hooks wire two Copilot CLI events to the notifier:

- **`agentStop`** — fires when Copilot finishes a turn and is waiting on you
- **`notification`** — fires when Copilot needs your attention (e.g., a prompt)

`permissionRequest` is intentionally left empty so permission prompts don't
double-notify (the CLI already surfaces those prominently).

## How it works

`notify.ps1` reads a JSON payload on stdin from Copilot CLI:

```json
{ "hook_event_name": "agentStop", "session_id": "...", "message": "..." }
```

It picks a friendly title based on the event, truncates long messages, and
calls `New-BurntToastNotification` with the Copilot logo as the app icon.
Errors are swallowed so a flaky hook never blocks the CLI.

## Known issues

- **Clicking the toast opens a stray PowerShell window.** BurntToast's default
  AUMID has no registered activator, so Windows falls back to launching the
  process that raised the toast — which is `powershell.exe`. There's no
  in-toast action to fix this without registering a custom AUMID/shortcut.
  **Workaround: don't click the toast.** Just glance at it and Alt-Tab back
  to your terminal. You can close the stray window safely.

## Uninstall

```powershell
Remove-Item "$env:USERPROFILE\.copilot\hooks\notification-hooks.json"
Remove-Item "$env:USERPROFILE\.copilot\hooks\notify.ps1"
Remove-Item "$env:LOCALAPPDATA\GitHub\CopilotCLI\copilot-logo.png"
```

Or restore the `notification-hooks.json.bak-*` file the installer created if
you had hooks configured previously. BurntToast can stay or be removed with
`Uninstall-Module BurntToast`.

## Troubleshooting

- **No toast appears.** Run `Import-Module BurntToast; New-BurntToastNotification -Text "test"`
  in a regular PowerShell window. If that fails, BurntToast isn't installed
  correctly — re-run the installer or install manually.
- **"Focus assist" / Do Not Disturb is on.** Windows silently suppresses
  toasts. Toggle it off in *Settings → System → Notifications*.
- **Hooks not firing.** Confirm Copilot CLI sees them with `copilot --help`
  hook docs, or check `%USERPROFILE%\.copilot\hooks\notification-hooks.json`
  exists and points at the right `notify.ps1` path. Restart `copilot` after
  any change.
- **Execution policy blocks `notify.ps1`.** The hook command uses
  `& <path>` which respects your policy. If needed, run
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

## License

MIT. Do whatever.

[BurntToast]: https://github.com/Windos/BurntToast
