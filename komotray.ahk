#SingleInstance Force
#Requires AutoHotkey v2.0.2
Persistent

#Include %A_ScriptDir%\lib\JSON.ahk
#Include %A_ScriptDir%\lib\komorebic.lib.ahk
#Include %A_ScriptDir%\config\komorebi.ahk ; Key bindings

; Set common config options
AutoStartKomorebi := true
global IconPath := A_ScriptDir . "/assets/icons/"
global KomorebiConfig := A_ScriptDir . "/config/komorebi.json"

; ======================================================================
; Initialization
; ======================================================================

; Set up tray menu
Tray := A_TrayMenu ; For convenience.
Tray.Delete() ; Delete the standard items.
Tray.Add("Pause/Unpause", PauseKomorebi)
Tray.Add("Restart", StartKomorebiStar)
Tray.Add() ; separator
Tray.Add("Reload Tray", ReloadTrayStar)
Tray.Add("Exit Tray", ExitTrayStar)

; Set the default function to call on click
Tray.Default := "Pause/Unpause"
Tray.ClickCount := 1

; Initialize internal states
IconState := -1
global Screen := 0

; Start the komorebi server
if (!ProcessExist("komorebi.exe") && AutoStartKomorebi) {
  StartKomorebi(false)
}

; ======================================================================
; Event Handler
; ======================================================================

; Set up pipe
PipeName := "komotray"
PipePath := "\\.\pipe\" . PipeName
OpenMode := 0x01  ; access_inbound
PipeMode := 0x04 | 0x02 | 0x01  ; type_message | readmode_message | nowait
BufferSize := 64 * 1024

; Create named pipe instance
Pipe := DllCall("CreateNamedPipe", "Str", PipePath, "UInt", OpenMode, "UInt", PipeMode
  , "UInt", 1, "UInt", BufferSize, "UInt", BufferSize, "UInt", 0, "Ptr", 0, "Ptr")

; Check for errors after the CreateFile call
if (Pipe = -1) {
  MsgBox("Failed to connect to named pipe, perhaps theres still an existing process?. Error code: " . A_LastError)
  ExitTray()
}

; Wait for Komorebi to connect
Subscribe(PipeName)
DllCall("ConnectNamedPipe", "Ptr", Pipe, "Ptr", 0) ; set PipeMode = nowait to avoid getting stuck when paused

; Subscribe to Komorebi events
Loop {
  ; Continue if buffer is empty
  BytesToRead := 0
  ExitCode := DllCall("PeekNamedPipe", "Ptr", Pipe, "Ptr", 0, "UInt", 1
    , "Ptr", 0, "UintP", &BytesToRead, "Ptr", 0)

  if (!ExitCode || !BytesToRead) {
    Sleep(50)
    Continue
  }

  ; Read the buffer
  BufferObj := Buffer(BufferSize)
  DllCall("ReadFile", "Ptr", Pipe, "Ptr", BufferObj, "UInt", BufferSize
    , "UIntP", &BytesActuallyRead := 0, "Ptr", 0)

  ; Strip new lines
  if (BytesActuallyRead <= 1) {
    Continue
  }

  EventState := JSON.Load(StrGet(BufferObj, BytesActuallyRead, "UTF-8"))["state"]

  Paused := EventState["is_paused"]
  Screen := EventState["monitors"]["focused"]
  ScreenQ := EventState["monitors"]["elements"][Screen + 1]
  Workspace := ScreenQ["workspaces"]["focused"]
  WorkspaceQ := ScreenQ["workspaces"]["elements"][Workspace + 1]

  ; Update tray icon
  if (Paused | Screen << 1 | Workspace << 4 != IconState) {
    UpdateIcon(Paused, Screen, Workspace, ScreenQ["name"], WorkspaceQ["name"])
    IconState := Paused | Screen << 1 | Workspace << 4 ; use 3 bits for monitor (i.e. up to 8 monitors)
  }
}
return

; ======================================================================
; Functions
; ======================================================================

Komorebi(arg) {
  RunWait("komorebic.exe " . arg, , "Hide")
}

StartKomorebiStar(*) {
  StartKomorebi(true)
}

StartKomorebi(reloadTrayParam := true) {
  Stop()
  ; If we don't have whdk installed its safe to simply start komorebi,
  ; it won't default back to whkd
  Komorebi("start -c " . KomorebiConfig)
  if (reloadTrayParam) {
    ReloadTray()
  }
}

PauseKomorebi(*) {
  TogglePause()
}

SwapScreens() {
  ; Swap monitors on a 2 screen setup. ToDo: Add safeguard for 3+ monitors
  Komorebi("swap-workspaces-with-monitor " . 1 - Screen)
}

UpdateIcon(paused, screen, workspace, screenName, workspaceName) {
  A_IconTip := workspaceName . " on " . screenName
  icon := IconPath . workspace + 1 . "-" . screen + 1 . ".ico"
  if (!paused && FileExist(icon)) {
    TraySetIcon(icon)
  } else {
    TraySetIcon(IconPath . "pause.ico") ; also used as fallback
  }
}

ReloadTrayStar(*) {
  ReloadTray()
}

ReloadTray() {
  DllCall("CloseHandle", "Ptr", Pipe)
  Reload
}

ExitTrayStar(*) {
  ExitTray()
}

ExitTray() {
  DllCall("CloseHandle", "Ptr", Pipe)
  Stop()
  ExitApp
}