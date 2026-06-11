# Copilot CLI Toast Notifications (Windows)

Pops a Windows toast (with the Copilot logo) whenever Copilot CLI finishes
a turn or asks for your attention. Uses the [BurntToast] PowerShell module.

## Install

1. Extract this zip anywhere.
2. Open PowerShell in the extracted folder and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

3. Restart `copilot` (the CLI).

The installer:
- Copies `notify.ps1` to `%USERPROFILE%\.copilot\hooks\`
- Writes `notification-hooks.json` (backing up any existing one)
- Copies `copilot-logo.png` to `%LOCALAPPDATA%\GitHub\CopilotCLI\`
- Installs the `BurntToast` module for the current user if missing

## Uninstall

Delete `%USERPROFILE%\.copilot\hooks\notification-hooks.json` (or restore the
`.bak-*` file the installer created).

## Caveat

Clicking the toast spawns a fresh PowerShell window — Windows falls back to the
spawning process because the AUMID has no registered activator. Just glance at
the toast and Alt-Tab back to your terminal.

[BurntToast]: https://github.com/Windos/BurntToast
