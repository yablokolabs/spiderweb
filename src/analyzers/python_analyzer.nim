# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# python_analyzer.nim - Python language analyzer

import strutils, tables, re
import ../language_analyzer

proc extractPythonFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts all Python function definitions from content
  result = @[]
  let lines = content.split('\n')

  # Match: def function_name, async def function_name
  let funcPattern = re"^\s*(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\("

  for i, line in lines:
    # Skip decorator lines
    if line.strip().startsWith("@"):
      continue

    var matches: array[1, string]
    if line.find(funcPattern, matches) >= 0:
      result.add(FunctionDef(
        name: matches[0],
        file: filepath,
        line: i + 1
      ))

proc extractPythonCalls(content: string, funcName: string): seq[tuple[
    callee: string, count: int]] =
  ## Extracts all function calls made within a specific Python function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  let funcPattern = re("^\\s*(?:async\\s+)?def\\s+" & funcName & "\\s*\\(")

  var inFunction = false
  var baseIndent = -1

  for line in lines:
    # Check if we're entering the target function
    if line.find(funcPattern) >= 0:
      inFunction = true
      # Calculate base indentation level (number of leading spaces)
      baseIndent = line.len - line.strip(leading = true).len
      continue

    if inFunction:
      # Check if we've left the function (dedent to same or lower level)
      let currentIndent = line.len - line.strip(leading = true).len
      if line.strip().len > 0 and currentIndent <= baseIndent:
        # We've left the function
        break

      # Skip comment lines
      if line.strip().startsWith("#"):
        continue

      # Skip string literals (basic heuristic - might have false negatives)
      var inString = false
      var i = 0
      var cleanLine = ""
      while i < line.len:
        if line[i] in {'\'', '"'}:
          inString = not inString
        elif not inString:
          cleanLine.add(line[i])
        i += 1

      # Extract function calls: functionName( or obj.method(
      let callPattern = re"([a-zA-Z_][a-zA-Z0-9_]*)\s*\("
      var pos = 0
      var matches: array[1, string]

      while true:
        let found = cleanLine[pos..^1].find(callPattern, matches)
        if found < 0:
          break

        let callName = matches[0]
        # Skip Python keywords and our own function name
        if callName notin ["if", "elif", "else", "for", "while", "with", "try",
                           "except", "finally", "class", "import", "from",
                           "return",
                           "yield", "raise", "assert", "pass", "break",
                           "continue",
                           "lambda", "def", "print"] and callName != funcName:
          if callCounts.hasKey(callName):
            callCounts[callName] += 1
          else:
            callCounts[callName] = 1

        pos += found + callName.len + 1
        if pos >= cleanLine.len:
          break

  for callee, count in callCounts:
    result.add((callee: callee, count: count))

proc createPythonAnalyzer*(): LanguageAnalyzer =
  ## Creates a Python language analyzer
  result = LanguageAnalyzer(
    name: "Python",
    extensions: @[".py", ".pyi"],
    keywords: @["if", "elif", "else", "for", "while", "with", "try",
                "except", "finally", "class", "import", "from", "return",
                "yield", "raise", "assert", "pass", "break", "continue",
                "lambda", "def", "print", "range"],
    extractFunctions: extractPythonFunctions,
    extractCalls: extractPythonCalls
  )
