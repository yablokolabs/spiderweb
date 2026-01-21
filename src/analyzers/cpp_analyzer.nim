# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# cpp_analyzer.nim - C/C++ language analyzer

import strutils, tables, re
import ../language_analyzer

proc extractCppFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts C/C++ function definitions from content
  ## Note: This is approximate due to C++ complexity
  result = @[]
  let lines = content.split('\n')

  # Match common function patterns
  # This will have false positives due to C++ syntax complexity
  let funcPattern = re"^\s*(?:static|inline|extern|virtual)?\s*\w+\s+[*&]?\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\("

  for i, line in lines:
    # Skip preprocessor directives
    if line.strip().startsWith("#"):
      continue

    var matches: array[1, string]
    if line.find(funcPattern, matches) >= 0:
      let name = matches[0]
      # Filter out common false positives
      if name notin ["if", "while", "for", "switch", "return"]:
        result.add(FunctionDef(
          name: name,
          file: filepath,
          line: i + 1
        ))

proc extractCppCalls(content: string, funcName: string): seq[tuple[
    callee: string, count: int]] =
  ## Extracts all function calls made within a specific C/C++ function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  # Simple pattern for function definition
  let funcPattern = re("\\w+\\s+" & funcName & "\\s*\\(")

  var inFunction = false
  var braceDepth = 0

  for line in lines:
    # Skip preprocessor directives
    if line.strip().startsWith("#"):
      continue

    # Check if we're entering the target function
    if line.find(funcPattern) >= 0:
      inFunction = true
      # Count opening braces
      for ch in line:
        if ch == '{': braceDepth += 1
        elif ch == '}': braceDepth -= 1
      continue

    if inFunction:
      # Track brace depth
      for ch in line:
        if ch == '{': braceDepth += 1
        elif ch == '}':
          braceDepth -= 1
          if braceDepth == 0:
            inFunction = false
            break

      if not inFunction:
        break

      # Skip comment lines
      if line.strip().startsWith("//") or line.strip().startsWith("/*"):
        continue

      # Extract function calls: functionName(
      let callPattern = re"([a-zA-Z_][a-zA-Z0-9_]*)\s*\("
      var pos = 0
      var matches: array[1, string]

      while true:
        let found = line[pos..^1].find(callPattern, matches)
        if found < 0:
          break

        let callName = matches[0]
        # Skip C/C++ keywords and our own function name
        if callName notin ["if", "else", "for", "while", "do", "switch", "case",
                           "return", "break", "continue", "goto", "sizeof",
                           "typedef",
                           "struct", "union", "enum", "class", "template",
                           "namespace",
                           "using", "public", "private", "protected", "virtual",
                           "static",
                           "const", "volatile", "inline", "extern", "new",
                           "delete", "this"] and
           callName != funcName:
          if callCounts.hasKey(callName):
            callCounts[callName] += 1
          else:
            callCounts[callName] = 1

        pos += found + callName.len + 1
        if pos >= line.len:
          break

  for callee, count in callCounts:
    result.add((callee: callee, count: count))

proc createCppAnalyzer*(): LanguageAnalyzer =
  ## Creates a C/C++ language analyzer
  result = LanguageAnalyzer(
    name: "C/C++",
    extensions: @[".c", ".cpp", ".cc", ".cxx", ".h", ".hpp", ".hxx"],
    keywords: @["if", "else", "for", "while", "do", "switch", "case",
                "return", "break", "continue", "goto", "sizeof", "typedef",
                "struct", "union", "enum", "class", "template", "namespace",
                "using", "public", "private", "protected", "virtual", "static",
                "const", "volatile", "inline", "extern", "new", "delete",
                "this"],
    extractFunctions: extractCppFunctions,
    extractCalls: extractCppCalls
  )
