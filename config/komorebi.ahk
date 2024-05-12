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
!1:: FocusWorkspace(0)
!2:: FocusWorkspace(1)
!3:: FocusWorkspace(2)
!4:: FocusWorkspace(3)
!5:: FocusWorkspace(4)
!6:: FocusWorkspace(5)
!7:: FocusWorkspace(6)
!8:: FocusWorkspace(7)
!9:: FocusWorkspace(8)

; Move windows across workspaces
!+1:: MoveToWorkspace(0)
!+2:: MoveToWorkspace(1)
!+3:: MoveToWorkspace(2)
!+4:: MoveToWorkspace(3)
!+5:: MoveToWorkspace(4)
!+6:: MoveToWorkspace(5)
!+7:: MoveToWorkspace(6)
!+8:: MoveToWorkspace(7)
!+9:: MoveToWorkspace(8)

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