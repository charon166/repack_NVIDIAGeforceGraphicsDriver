﻿; 
;   NVIDIA Graphic Driver Installation Utility 1.5 (14-11-2019)
;   Author: alanfox2000
;
#NoTrayIcon
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
Title = NVIDIA Graphic Driver Installation Utility
AhkPath = %A_WorkingDir%\AutoHotkey.exe
NVIDIAInstall = C:\NVIDIAInstall.bat
schtasks = %A_WinDir%\system32\schtasks.exe
bcdedit = %A_WinDir%\system32\bcdedit.exe
takeown = %A_WinDir%\system32\takeown.exe
cacls = %A_WinDir%\system32\cacls.exe
XML = C:\NVIDIAInstall.xml
Drs = %A_AppDataCommon%\NVIDIA Corporation\Drs

full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        Loop % A_Args.Length()
        {
            FullArgs := % FullArgs " "A_Args[A_Index]
        }
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart %FullArgs%
        else
            Run *RunAs "%AhkPath%" /restart "%A_ScriptFullPath%" %FullArgs%
    }
    ExitApp
}

if A_Args[1] = "install"
{
    Loop % A_Args.Length() - 1
    {
        I_Index := % A_Index + 1
        FullArgs := % FullArgs " "A_Args[I_Index]
    }
goto InstallType1
}

Gui Font,, Arial
Gui Add, Text, x8 y8 w230 h23, NVIDIA Install Application Switches:
Gui Add, CheckBox, vChkSilent x8 y32 w14 h23 +Checked
Gui Add, CheckBox, vChkClean x376 y56 w134 h23 +Checked, Clean Install[-clean]
Gui Add, CheckBox, vChkTelemetry x8 y80 w14 h23 +Checked
Gui Add, DropDownList, x24 y80 w153 vTelemetryOptions, -enableTelemetry:true|-enableTelemetry:false||
Gui Add, CheckBox, vChkReboot x192 y32 w14 h23 +Checked
Gui Add, CheckBox, vChkEula x208 y56 w163 h23 +Checked, Skip EULA Dialog [-noeula]
Gui Add, DropDownList, x24 y56 w180 vGFEOptions, -gfexperienceinitiated:true|-gfexperienceinitiated:false||
Gui Add, CheckBox, vChkGFE x8 y56 w14 h23 +Checked
Gui Add, CheckBox, vChkFinish x352 y32 w173 h23 +Checked, Skip Finish Dialog [-nofinish]
Gui Add, CheckBox, vChkPNP x184 y80 w189 h23, Ignore PNP Flag [-ignorepnp]
Gui Add, DropDownList, x208 y32 w139 vRebootOptions, Reboot Required [-k]|Ignore Reboot [-n]||
Gui Add, DropDownList, x24 y32 w160 vSilentOptions, Silent [-s]|Progress Only [-passive]||
Gui Add, CheckBox, x376 y80 w198 h23 vChkSplash +Checked, No Splash Screen [-nosplash]
Gui Add, Text, x8 y128 w37 h23 +0x200, Install:
Gui Add, Button, x48 y128 w100 h23 gAutoInstall, Automatically
Gui Add, Button, x152 y128 w80 h23 gDirectInstall, Directly
Gui Add, Button, x265 y128 w80 h23 gXtremeG, Xtreme-G
Gui Add, Button, x352 y128 w80 h23 gINFUtility, Add HWID
Gui Add, Button, x440 y128 w160 h23 gSupportCards, Supported Graphics Cards
Gui Font
Gui Show, w604 h156, %Title% 1.5
GUIDDL := ["TelemetryOptions", "GFEOptions", "RebootOptions", "SilentOptions"]
Loop % GUIDDL.Length()
{
    GuiControl, +AltSubmit, % GUIDDL[A_Index]
}
Return

XtremeG:
Run, %AhkPath% %A_WorkingDir%\XtremeG.ahk
Return

AutoInstall:
Gui, Submit, NoHide
InstallType = 1
MsgBox, 0x2024, %Title%, %Title% will follow the below installation procedure:`r`n`r`nEnable Test Signing → Reboot → Install Driver → Disable Test Signing → Reboot`r`n`r`nWould you like to execute this procedure now?
IfMsgBox, No
    Return
IfMsgBox, Yes
{
    gosub ArgBuild
    RunWait, %ComSpec% /c %bcdedit% /set testsigning on,, Hide
    RunWait, %ComSpec% /c %schtasks% /Create /TN "NVIDIAInstall" /TR ""%ComSpec%" /c" /RL HIGHEST /SC ONLOGON /F,, Hide
    FileDelete, %XML%
    RunWait, %ComSpec% /c %schtasks% /Query /XML /TN "\NVIDIAInstall" > "%XML%",, Hide
    FileRead, XMLContents, %XML%
    N_XMLContents := RegExReplace(XMLContents, "<Command>(.*)</Command>","<Command>" AhkPath "</Command>")
    N_XMLContents2 := RegExReplace(N_XMLContents, "<Arguments>(.*)</Arguments>","<Arguments>" """" A_ScriptFullPath """" " install " SavedPara " -n -disableGAT</Arguments>")
    FileDelete, %XML%
    FileAppend, %N_XMLContents2%, %XML%, UTF-16
    RunWait, %ComSpec% /c %schtasks% /Create /XML "%XML%" /TN "NVIDIAInstall" /F,, Hide
    FileDelete, %XML%
    Shutdown, 2
    ExitApp
}


DirectInstall:
Gui, Submit, NoHide
InstallType = 2
MsgBox, 0x2024, %Title%, Installing unsigned drivers required enable test mode or disable driver signature enforcement.`r`n`r`nWould you like to install driver now?
IfMsgBox, No
    Return
IfMsgBox, Yes
{
    gosub ArgBuild
    Gui, Hide
    goto InstallType2
}


ArgBuild:
Para_Array := []
If ChkSilent = 1
{
    If SilentOptions = 1
    {
        Para_Array.Push("-s")
    }
    If SilentOptions = 2
    {
        Para_Array.Push("-passive")
    }
}
If ChkClean = 1
{
    Para_Array.Push("-clean")
}
If ChkTelemetry = 1
{
    If TelemetryOptions = 1
    {
        Para_Array.Push("-enableTelemetry:true")
    }
    If TelemetryOptions = 2
    {        
        Para_Array.Push("-enableTelemetry:false")
    }
}
If ChkPNP = 1
{
    Para_Array.Push("-ignorepnp")
}
If ChkFinish = 1
{
    Para_Array.Push("-nofinish")
}
If ChkGFE = 1
{
    Para_Array.Push("-gfexperienceinitiated:false")
}
If (ChkReboot = "1") and (InstallType = "2")
{
    If RebootOptions = 1
    {
        Para_Array.Push("-k")
    }
    If RebootOptions = 2
    {        
        Para_Array.Push("-n")
    }
}
If ChkSplash = 1
{
    Para_Array.Push("-nosplash")
}
Loop % Para_Array.Length()
{
    if A_Index = 1
    {
        SavedPara := % Para_Array[1]
    }
    else
    {
        SavedPara := % SavedPara " " Para_Array[A_Index]
    }
}
Return

Abort:
MsgBox, 0x24, %Title%, Do you comfirm to abort the installation process?
IfMsgBox, No
    Return
IfMsgBox, Yes
{
    RunWait, %ComSpec% /c %schtasks% /Delete /TN "NVIDIAInstall" /F,, Hide
    Process, Close, %AUTOCLICK_PID%
    FileDelete, %NVIDIAInstall%
    ExitApp
}


InstallType1:
Gui Font,, Arial
Gui INSTALL_CONTROL:New, -Caption +AlwaysOnTop +ToolWindow
Gui INSTALL_CONTROL:Add, Button, x0 y0 w100 h23 gAbort, Abort Installation
Gui Font
SplashTextOn, 500,, %Title%: Waiting for NVIDIA Install Application
WinGet, SplashID, ID, %Title%: Waiting for NVIDIA Install Application
WinMove, ahk_id %SplashID%,,, A_ScreenHeight-80
Gui INSTALL_CONTROL:Show, % "w100 h23" "y" (A_ScreenHeight - 120)
Run, "%A_WorkingDir%\setup.exe" %FullArgs%,,, SETUPEXE_PID
Run, "%AhkPath%" "%A_WorkingDir%\AutoClick.ahk",,, AUTOCLICK_PID
Process, WaitClose, %SETUPEXE_PID%
WinSetTitle, ahk_id %SplashID%,, %Title%: Turning Off Test Mode...
RunWait, %ComSpec% /c %bcdedit% /set testsigning off,, Hide
if FileExist(A_WorkingDir "\Display.Driver\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj.Appx")
{
    WinSetTitle, ahk_id %SplashID%,, %Title%: Installing NVIDIA Control Panel [UWP]...
    RegRead, AllowAllTrustedApps, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps
    if AllowAllTrustedApps = 0
    {
        RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps, 1   
    }
    RunWait, %ComSpec% /c ""PowerShell" -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass Add-AppxProvisionedPackage -Online -PackagePath "Display.Driver\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj.Appx" -SkipLicense", %A_WorkingDir%, Hide
    RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps, %AllowAllTrustedApps%
    RegDelete, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{0bbca823-e77d-419e-9a44-5adec2c8eeb0}
}
RunWait, %ComSpec% /c %schtasks% /Delete /TN "NVIDIAInstall" /F,, Hide
Process, Close, %AUTOCLICK_PID%
FileDelete, %NVIDIAInstall%
FileCreateDir, %Drs%
RunWait, %ComSpec% /c %takeown% /f "%Drs%" /r /d n,, Hide
RunWait, %ComSpec% /c %cacls% "%Drs%" /t /e /p administrators:f,, Hide
RunWait, %ComSpec% /c %cacls% "%Drs%" /t /e /p users:f,, Hide
Shutdown, 2
ExitApp

InstallType2:
Gui Font,, Arial
Gui INSTALL_CONTROL:New, -Caption +AlwaysOnTop +ToolWindow
Gui INSTALL_CONTROL:Add, Button, x0 y0 w100 h23 gAbort, Abort Installation
Gui Font
SplashTextOn, 500,, %Title%: Waiting for NVIDIA Install Application
WinGet, SplashID, ID, %Title%: Waiting for NVIDIA Install Application
WinMove, ahk_id %SplashID%,,, A_ScreenHeight-80
Gui INSTALL_CONTROL:Show, % "w100 h23" "y" (A_ScreenHeight - 120)
Run, "%A_WorkingDir%\setup.exe" %SavedPara%,,, SETUPEXE_PID
Run, "%AhkPath%" "%A_WorkingDir%\AutoClick.ahk",,, AUTOCLICK_PID
Process, WaitClose, %SETUPEXE_PID%
if FileExist(A_WorkingDir "\Display.Driver\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj.Appx")
{
    WinSetTitle, ahk_id %SplashID%,, %Title%: Installing NVIDIA Control Panel [UWP]...
    RegRead, AllowAllTrustedApps, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps
    if AllowAllTrustedApps = 0
    {
        RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps, 1   
    }
    RunWait, %ComSpec% /c ""PowerShell" -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass Add-AppxProvisionedPackage -Online -PackagePath "Display.Driver\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj.Appx" -SkipLicense", %A_WorkingDir%, Hide
    RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock, AllowAllTrustedApps, %AllowAllTrustedApps%
    RegDelete, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{0bbca823-e77d-419e-9a44-5adec2c8eeb0}
}
RunWait, %ComSpec% /c %schtasks% /Delete /TN "NVIDIAInstall" /F,, Hide
Process, Close, %AUTOCLICK_PID%
FileCreateDir, %A_AppDataCommon%\NVIDIA Corporation\Drs
RunWait, %ComSpec% /c %takeown% /f "%Drs%" /r /d n,, Hide
RunWait, %ComSpec% /c %cacls% "%Drs%" /t /e /p administrators:f,, Hide
RunWait, %ComSpec% /c %cacls% "%Drs%" /t /e /p users:f,, Hide
ExitApp

SupportCards:
Run, %A_WorkingDir%\ListDevices.txt
Return

INFUtility:
Run, %AhkPath% %A_WorkingDir%\Utility_INF.ahk
Return

GuiEscape:
GuiClose:
    ExitApp
