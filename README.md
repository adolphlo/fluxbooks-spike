# fluxbooks-spike

**Throwaway repo — safe to delete once the real FluxBooks installer is built and this is no longer needed as a reference.** Validates the Inno Setup + Velopack installer/auto-update architecture before building it for real. See `SpikeApp/` (the minimal test app) and `Installer/FluxBooksSpikeInstaller.iss` (the wrapping installer script).

## Findings (2026-07-08)

Both real unknowns the docs alone couldn't answer were validated live:

1. **Elevation chaining works.** An outer, elevated (`PrivilegesRequired=admin`) Inno Setup installer can silently invoke Velopack's own `Setup.exe -s -t "<dir>"` as a child process, and a further privileged action (a firewall rule, in `[Code]`) right after it — both succeed in the same elevated context with no second UAC prompt. (Note: no UAC dialog appeared at all when this was tested, because the test machine has "elevate without prompting for admins" configured — the underlying mechanism, elevated-parent-token inherited by child processes, is the same either way, but this specific test didn't exercise a visible UAC dialog.)

2. **Update-check-and-apply works from a non-default install location.** Installed to `C:\Program Files\FluxBooksSpike` (not Velopack's default `%LocalAppData%`), published v1.0.0 then v1.0.1 to this repo's GitHub Releases, and ran the installed app's `CheckForUpdatesAsync` → `DownloadUpdatesAsync` → `ApplyUpdatesAndRestart` as a normal **non-elevated** process. It found, downloaded, and applied the update **in place** in `Program Files`, confirmed by rerunning the app and seeing the new build's marker text. There's a red-herring warning worth knowing about: a preliminary writability check logs `Access is denied` / `Root directory ... writable: false` / `Using fallback directory: %LocalAppData%\FluxBooksSpike` — but the actual apply still lands correctly in the real `Program Files` install. Don't be misled by that log line into thinking updates silently fork off into a separate copy — they don't, at least not in this test.

**Not yet tested:** all of the above validates the *interactive process* update flow (matches the Connector). FluxBooks' Api runs as a genuine Windows Service, and Velopack's `ApplyUpdatesAndRestart` assumes relaunching a normal foreground process — that mismatch still needs its own validation before building the real Api update path. See the main `dev-fluxbooks` repo's `CLAUDE.md` for the full plan and current status.

## Repo/artifact cleanup checklist (once no longer needed)

- [ ] Delete this GitHub repo (`gh repo delete adolphlo/fluxbooks-spike`)
- [ ] Uninstall the test app: `C:\Program Files\FluxBooksSpike` (no uninstaller was built for the spike — just delete the folder and its Start Menu/Desktop shortcuts)
