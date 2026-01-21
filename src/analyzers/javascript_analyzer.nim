# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# javascript_analyzer.nim - JavaScript/TypeScript language analyzer

import strutils, tables, re
import ../language_analyzer

proc extractJavaScriptFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts all JavaScript/TypeScript function definitions from content
  result = @[]
  let lines = content.split('\n')

  # Match multiple patterns:
  # function name(, async function name(, const name = (, const name = function(
  let funcPattern = re"^\s*(?:export\s+)?(?:async\s+)?(?:function\s+([a-zA-Z_$][a-zA-Z0-9_$]*)|const\s+([a-zA-Z_$][a-zA-Z0-9_$]*)\s*=)"

  for i, line in lines:
    var matches: array[2, string]
    if line.find(funcPattern, matches) >= 0:
      let funcName = if matches[0].len > 0: matches[0] else: matches[1]
      if funcName.len > 0:
        result.add(FunctionDef(
          name: funcName,
          file: filepath,
          line: i + 1
        ))

const
  # Maximum lines to process within a single function to prevent hangs
  maxFunctionLines = 1000

proc extractJavaScriptCalls(content: string, funcName: string): seq[tuple[
    callee: string, count: int]] =
  ## Extracts all function calls made within a specific JavaScript function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  # Match: function name(, const name =, async function name(
  let funcPattern = re("(?:function\\s+" & funcName & "\\s*\\(|const\\s+" &
      funcName & "\\s*=)")
  # Pattern to detect start of another function (fallback exit condition)
  let otherFuncPattern = re"^\s*(?:export\s+)?(?:async\s+)?(?:function\s+[a-zA-Z_$]|const\s+[a-zA-Z_$][a-zA-Z0-9_$]*\s*=\s*(?:\(|function))"

  var inFunction = false
  var braceDepth = 0
  var linesInFunction = 0

  for line in lines:
    # Check if we're entering the target function
    if line.find(funcPattern) >= 0:
      inFunction = true
      linesInFunction = 0
      # Count opening braces in the function declaration line
      for ch in line:
        if ch == '{': braceDepth += 1
        elif ch == '}': braceDepth -= 1
      continue

    if inFunction:
      linesInFunction += 1

      # Safety limit: if we've processed too many lines, assume function ended
      if linesInFunction > maxFunctionLines:
        break

      # Fallback: if we see another function definition, we've left our function
      if line.find(otherFuncPattern) >= 0 and line.find(funcPattern) < 0:
        break

      # Track brace depth
      for ch in line:
        if ch == '{': braceDepth += 1
        elif ch == '}':
          braceDepth -= 1
          if braceDepth == 0:
            # We've left the function
            inFunction = false
            break

      if not inFunction:
        break

      # Skip comment lines
      if line.strip().startsWith("//"):
        continue

      # Extract function calls: functionName( or obj.method(
      let callPattern = re"([a-zA-Z_$][a-zA-Z0-9_$]*)\s*\("
      var pos = 0
      var matches: array[1, string]

      while true:
        let found = line[pos..^1].find(callPattern, matches)
        if found < 0:
          break

        let callName = matches[0]
        # Skip JavaScript keywords and our own function name
        if callName notin ["if", "else", "for", "while", "switch", "case", "try",
                           "catch", "finally", "return", "throw", "break",
                           "continue",
                           "function", "var", "let", "const", "class", "import",
                           "export",
                           "await", "async", "typeof", "instanceof", "new",
                           "delete"] and
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

proc createJavaScriptAnalyzer*(): LanguageAnalyzer =
  ## Creates a JavaScript/TypeScript language analyzer
  result = LanguageAnalyzer(
    name: "JavaScript",
    extensions: @[".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs"],
    keywords: @["if", "else", "for", "while", "switch", "case", "try",
                "catch", "finally", "return", "throw", "break", "continue",
                "function", "var", "let", "const", "class", "import", "export",
                "await", "async", "typeof", "instanceof", "new", "delete",
                "void"],
    extractFunctions: extractJavaScriptFunctions,
    extractCalls: extractJavaScriptCalls
  )
