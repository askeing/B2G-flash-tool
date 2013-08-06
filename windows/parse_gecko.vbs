Dim inp, strings
Do While Not WScript.StdIn.AtEndOfStream
  inp = WScript.StdIn.ReadLine()
  strings = Split(inp,"""")
  WScript.Echo strings(1)
Loop

