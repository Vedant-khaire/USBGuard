; ------------------------------------------------------------
; Inno Setup script for USBGuard
; ------------------------------------------------------------
[Setup]
AppName=USBGuard
AppVersion=1.0.0
DefaultDirName={autopf}\USBGuard
DefaultGroupName=USBGuard
OutputBaseFilename=USBGuard_Installer
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
UninstallDisplayIcon={app}\usbguard_app.exe

[Files]
; Copy all build files
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
; Start Menu shortcut
Name: "{group}\USBGuard"; Filename: "{app}\usbguard_app.exe"

; Desktop shortcut
Name: "{commondesktop}\USBGuard"; Filename: "{app}\usbguard_app.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
; Run after install
Filename: "{app}\usbguard_app.exe"; Description: "Launch USBGuard"; Flags: nowait postinstall skipifsilent

[Registry]
; Auto-run at startup
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
    ValueType: string; ValueName: "USBGuard"; ValueData: """{app}\usbguard_app.exe"""; Flags: uninsdeletevalue
