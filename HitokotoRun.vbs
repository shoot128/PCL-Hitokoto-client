Option Explicit

' Start Hitokoto.ps1 with a completely hidden window.
' PCL calls: wscript.exe //nologo "HitokotoRun.vbs" -Action ...

Dim fso, shell, baseDir, scriptPath, quoteChar, cmd, i, current, argText

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

baseDir = fso.GetParentFolderName(WScript.ScriptFullName)
shell.CurrentDirectory = baseDir
scriptPath = fso.BuildPath(baseDir, "Hitokoto.ps1")
quoteChar = Chr(34)

argText = ""
For i = 0 To WScript.Arguments.Count - 1
    current = WScript.Arguments(i)
    ' Reject quotes, NUL and line breaks so arguments cannot escape the command line.
    If InStr(current, quoteChar) > 0 Or InStr(current, Chr(0)) > 0 Or InStr(current, vbCr) > 0 Or InStr(current, vbLf) > 0 Then
        WScript.Quit 2
    End If
    If current = "-Action" Or current = "-Query" Or current = "-ApiUrl" Or current = "-LibraryUrl" Then
        argText = argText & " " & current
    Else
        argText = argText & " " & Quote(current)
    End If
Next

cmd = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File " & quoteChar & scriptPath & quoteChar & argText
shell.Run cmd, 0, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
