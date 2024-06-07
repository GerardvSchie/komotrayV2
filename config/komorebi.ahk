; Adapted from https://github.com/LGUG2Z/komorebi/blob/master/komorebi.sample.ahk
#SingleInstance Force
#Include "%A_ScriptDir%\lib\komorebic.lib.ahk"

; Open/Close windows
!+q:: Close()
!Enter:: {
  if (PID := ProcessExist("wezterm-gui.exe")) {
  } else {
    Run("wezterm-gui")
  }
  ; Jump to the process
  FocusMonitorWorkspace(0, 0)
}

; Focus windows
!h:: Focus("left")
!j:: Focus("down")
!k:: Focus("up")
!l:: Focus("right")
!f:: ToggleMaximize()

; Move windows
!+h:: Move("left")
!+j:: Move("down")
!+k:: Move("up")
!+l:: Move("right")

; Resize
!=:: ResizeAxis("horizontal", "increase")
!-:: ResizeAxis("horizontal", "decrease")
!+=:: ResizeAxis("vertical", "increase")
!+-:: ResizeAxis("vertical", "decrease")

; Workspaces
!1:: FocusMonitorWorkspace(0, 0)
!2:: FocusMonitorWorkspace(0, 1)
!3:: FocusMonitorWorkspace(0, 2)
!4:: FocusMonitorWorkspace(0, 3)
!5:: FocusMonitorWorkspace(0, 4)
!6:: FocusMonitorWorkspace(0, 5)
!7:: FocusMonitorWorkspace(0, 6)
!8:: FocusMonitorWorkspace(0, 7)
!9:: FocusMonitorWorkspace(0, 8)

<^>!1:: FocusMonitorWorkspace(1, 0)
<^>!2:: FocusMonitorWorkspace(1, 1)
<^>!3:: FocusMonitorWorkspace(1, 2)
<^>!4:: FocusMonitorWorkspace(1, 3)
<^>!5:: FocusMonitorWorkspace(1, 4)
<^>!6:: FocusMonitorWorkspace(1, 5)
<^>!7:: FocusMonitorWorkspace(1, 6)
<^>!8:: FocusMonitorWorkspace(1, 7)
<^>!9:: FocusMonitorWorkspace(1, 8)

; Move windows across workspaces
!+1:: SendToMonitorWorkspace(0, 0)
!+2:: SendToMonitorWorkspace(0, 1)
!+3:: SendToMonitorWorkspace(0, 2)
!+4:: SendToMonitorWorkspace(0, 3)
!+5:: SendToMonitorWorkspace(0, 4)
!+6:: SendToMonitorWorkspace(0, 5)
!+7:: SendToMonitorWorkspace(0, 6)
!+8:: SendToMonitorWorkspace(0, 7)
!+9:: SendToMonitorWorkspace(0, 8)

<^>!+1:: SendToMonitorWorkspace(1, 0)
<^>!+2:: SendToMonitorWorkspace(1, 1)
<^>!+3:: SendToMonitorWorkspace(1, 2)
<^>!+4:: SendToMonitorWorkspace(1, 3)
<^>!+5:: SendToMonitorWorkspace(1, 4)
<^>!+6:: SendToMonitorWorkspace(1, 5)
<^>!+7:: SendToMonitorWorkspace(1, 6)
<^>!+8:: SendToMonitorWorkspace(1, 7)
<^>!+9:: SendToMonitorWorkspace(1, 8)

; Scroll taskbar to cycle workspaces (disabled since I don't want to use it)
; #Hotif MouseIsOver("ahk_class Shell_TrayWnd") || MouseIsOver("ahk_class Shell_SecondaryTrayWnd")
; WheelUp:: ScrollWorkspace("next")
; WheelDown:: ScrollWorkspace("previous")
; #Hotif

; Alt + scroll to cycle workspaces
!WheelUp:: ScrollWorkspace("next")
!WheelDown:: ScrollWorkspace("previous")

LastTaskbarScroll := 0
ScrollWorkspace(dir) {
  global LastTaskbarScroll
  ; This adds a state-dependent debounce timer to adress an issue where a single wheel
  ; click spawns multiple clicks when a web browser is in focus.
  _isBrowser := WinActive("ahk_class Chrome_WidgetWin_1") || WinActive("ahk_class MozillaWindowClass")
  _t := _isBrowser ? 800 : 100
  ; Total debounce time = _t[this_call] + _t[last_call] to address interim focus changes
  if (A_PriorKey != A_ThisHotkey) || (A_TickCount - LastTaskbarScroll > _t) {
    LastTaskbarScroll := A_TickCount + _t
    MouseFollowsFocus(false)
    CycleWorkspace(dir)
    ; ToDo: only re-enable if it was enabled before
    MouseFollowsFocus(true)
  }
}

; ======================================================================
; Auxiliary Functions
; ======================================================================

MouseIsOver(WinTitle) {
  MouseGetPos(, , &Win)
  return WinExist(WinTitle . " ahk_id " . Win)
}