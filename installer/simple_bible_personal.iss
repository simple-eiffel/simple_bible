; ============================================================================
;  simple_bible - PERSONAL installer (Inno Setup 6)
;
;  For the project lead's own machines only: it carries the PERSONAL EDITION of
;  the concordance pack (conc.db), which is never published. The setup file is
;  written to installer\output\, which git ignores; never upload it anywhere.
;
;  Ships everything needed, nothing else to install:
;    bible_gui.exe    the window (release build), with cairo.dll (simple_cairo), the
;                     emoji art simple_shaping draws and its licence (LICENSE-ASSETS.md)
;    bible.exe        the command line (release build, no contracts: FR-160)
;    bible_build.exe  rebuilds content.db from a bible.db
;    data\content.db  content.db v2 (research/18: books, 21 versions, every verse), from the build machine
;    data\conc.db     the personal concordance pack (pack v1, research/17)
;  The programs link SQLite and the C runtime in; besides Windows' own DLLs only the
;  window needs cairo.dll, shipped beside it. Each program finds data\ beside itself,
;  so no environment variable is needed.
;
;  Build: installer\build_installer.cmd (builds both programs, then this script).
;  Inputs found on the build machine, never written into this file:
;    conc.db    : the SIMPLE_BIBLE_CONC environment variable
;    content.db : %LOCALAPPDATA%\simple_bible\content.db (bible_build writes it there)
; ============================================================================

#define AppName        "simple_bible"
#define AppVersion     "0.5.2"
#define AppPublisher   "Larry Rix"
#define GuiExe         "..\EIFGENs\bible_gui\F_code\bible_gui_lean.exe"
#define CairoDll       GetEnv("SIMPLE_EIFFEL") + "\simple_cairo\cairo.dll"
#define ShapingDir     GetEnv("SIMPLE_EIFFEL") + "\simple_shaping"
#define BibleExe       "..\EIFGENs\bible\F_code\bible_lean.exe"
#define BuildExe       "..\EIFGENs\bible_build\F_code\bible_build_lean.exe"
#define ConcDb         GetEnv("SIMPLE_BIBLE_CONC")
#define ContentDb      GetEnv("LOCALAPPDATA") + "\simple_bible\content.db"

#if ConcDb == ""
  #error SIMPLE_BIBLE_CONC is not set: point it at the personal conc.db before building.
#endif
#if !FileExists(ConcDb)
  #error SIMPLE_BIBLE_CONC does not name a file.
#endif
#if !FileExists(ContentDb)
  #error content.db is missing from %LOCALAPPDATA%\simple_bible: run bible_build first.
#endif
#if !FileExists(GuiExe)
  #error bible_gui_lean.exe is missing: run ec.sh release for simple_bible_app.ecf, target bible_gui.
#endif
#if !FileExists(CairoDll)
  #error cairo.dll is missing from simple_cairo (SIMPLE_EIFFEL).
#endif
#if !FileExists(BibleExe)
  #error bible_lean.exe is missing: run ec.sh release for simple_bible_app.ecf, target bible.
#endif
#if !FileExists(BuildExe)
  #error bible_build_lean.exe is missing: run ec.sh release for bible_build.ecf, target bible_build.
#endif

[Setup]
AppId={{9D3C2A71-6E48-4F0B-B2D5-7A1E64C08F93}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} (personal edition)
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=.\output
OutputBaseFilename=simple_bible-personal-{#AppVersion}-Setup
; conc.db is about 1.2 GB: fast compression keeps the build to minutes.
Compression=lzma2/fast
SolidCompression=no
WizardStyle=modern
DisableProgramGroupPage=yes
; Per-user install: no administrator prompt; the program writes nothing outside its folder.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesEnvironment=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut for the window"; GroupDescription: "Shortcuts:"; Flags: unchecked
Name: "addtopath"; Description: "Add bible to my PATH, so it runs from any console"; GroupDescription: "Command line:"

[Files]
Source: "{#GuiExe}"; DestDir: "{app}"; DestName: "bible_gui.exe"; Flags: ignoreversion
Source: "{#CairoDll}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ShapingDir}\LICENSE-ASSETS.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ShapingDir}\assets\noto-emoji\png\128\*"; DestDir: "{app}\assets\noto-emoji\png\128"; Flags: ignoreversion recursesubdirs
Source: "{#BibleExe}"; DestDir: "{app}"; DestName: "bible.exe"; Flags: ignoreversion
Source: "{#BuildExe}"; DestDir: "{app}"; DestName: "bible_build.exe"; Flags: ignoreversion
Source: "{#ContentDb}"; DestDir: "{app}\data"; DestName: "content.db"; Flags: ignoreversion
Source: "{#ConcDb}"; DestDir: "{app}\data"; DestName: "conc.db"; Flags: ignoreversion
Source: "README.txt"; DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
Name: "{group}\simple_bible"; Filename: "{app}\bible_gui.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\simple_bible"; Filename: "{app}\bible_gui.exe"; WorkingDir: "{app}"; Tasks: desktopicon
; A console set to UTF-8 (code page 65001), so Hebrew and Greek print correctly.
Name: "{group}\simple_bible prompt"; Filename: "{cmd}"; Parameters: "/k chcp 65001 >nul && bible"; WorkingDir: "{app}"
Name: "{group}\Read me";             Filename: "{app}\README.txt"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\bible_gui.exe"; WorkingDir: "{app}"; Description: "Start simple_bible"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\exception_trace.log"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Tasks: addtopath; Check: NeedsAddPath(ExpandConstant('{app}'))

[Code]
function NeedsAddPath(Folder: string): Boolean;
var
  Paths: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
  begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Uppercase(Folder) + ';', ';' + Uppercase(Paths) + ';') = 0;
end;

procedure RemoveFromPath(Folder: string);
var
  Paths: string;
  P: Integer;
begin
  if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
  begin
    P := Pos(';' + Uppercase(Folder) + ';', ';' + Uppercase(Paths) + ';');
    if P > 0 then
    begin
      Delete(Paths, P - 1, Length(Folder) + 1);
      if (Length(Paths) > 0) and (Paths[1] = ';') then
        Delete(Paths, 1, 1);
      RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths);
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveFromPath(ExpandConstant('{app}'));
end;
