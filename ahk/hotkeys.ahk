#Requires AutoHotkey v2.0

#w::Send("!{F4}")

^!n::Send "{Media_Next}"
^!p::Send "{Media_Play_Pause}"

#Enter::Run("powershell.exe")