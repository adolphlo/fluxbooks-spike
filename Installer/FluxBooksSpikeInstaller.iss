; Spike installer - validates two things before building the real FluxBooks installer:
;  1. Does an elevated outer Inno installer trigger a SECOND UAC prompt when it
;     silently invokes Velopack's own Setup.exe as a child process?
;  2. Does a dummy privileged action (a firewall rule) after that succeed
;     without issue, in the same elevated context?

#define MyAppName "FluxBooks Spike"
#define MyAppVersion "1.0.0"
#define MyInstallDir "C:\Program Files\FluxBooksSpike"

[Setup]
AppId={{B3B6B1B0-5B6B-4B1B-9B1B-FLUXBOOKSSPK}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={#MyInstallDir}
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=.\Output
OutputBaseFilename=FluxBooksSpikeInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "..\Releases\FluxBooksSpike-win-Setup.exe"; DestDir: "{tmp}"; Flags: dontcopy

[Code]
function RunAndWait(const Exe, Params: string): Integer;
var
  ResultCode: Integer;
begin
  if not Exec(Exe, Params, '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    ResultCode := -1;
  Result := ResultCode;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  SetupExePath: string;
  ExitCode: Integer;
  FirewallExitCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Extract the embedded Velopack Setup.exe and run it silently, targeting
    // the same install directory this outer installer is running from. This
    // is the step being tested: does invoking it from an already-elevated
    // Inno process avoid a second UAC prompt?
    ExtractTemporaryFile('FluxBooksSpike-win-Setup.exe');
    SetupExePath := ExpandConstant('{tmp}\FluxBooksSpike-win-Setup.exe');

    ExitCode := RunAndWait(SetupExePath, '-s -t "' + ExpandConstant('{app}') + '"');
    if ExitCode <> 0 then
    begin
      MsgBox('Velopack Setup.exe failed with exit code ' + IntToStr(ExitCode), mbError, MB_OK);
      Exit;
    end;

    // Dummy privileged post-step - confirms a real admin-only action still
    // works fine in this same elevated context after the Velopack step.
    FirewallExitCode := RunAndWait('netsh.exe', 'advfirewall firewall add rule name="FluxBooksSpikeTest" dir=in action=allow protocol=TCP localport=59999');
    if FirewallExitCode <> 0 then
      MsgBox('Firewall rule step failed with exit code ' + IntToStr(FirewallExitCode), mbError, MB_OK)
    else
      MsgBox('Spike installer completed successfully: Velopack install + firewall rule both succeeded.', mbInformation, MB_OK);
  end;
end;
