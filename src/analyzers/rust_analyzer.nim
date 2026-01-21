# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# rust_analyzer.nim - Rust language analyzer

import strutils, tables, re
import ../language_analyzer

proc extractRustFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts all Rust function definitions from content
  result = @[]
  let lines = content.split('\n')

  # Match: fn name, pub fn name, async fn name, pub async fn name
  let funcPattern = re"^\s*(?:pub\s+)?(?:async\s+)?fn\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[<\(]"

  for i, line in lines:
    var matches: array[1, string]
    if line.find(funcPattern, matches) >= 0:
      result.add(FunctionDef(
        name: matches[0],
        file: filepath,
        line: i + 1
      ))

proc extractRustCalls(content: string, funcName: string): seq[tuple[
    callee: string, count: int]] =
  ## Extracts all function calls made within a specific Rust function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  let funcPattern = re("fn\\s+" & funcName & "\\s*[<\\(]")

  var inFunction = false
  var braceDepth = 0

  for line in lines:
    # Check if we're entering the target function
    if line.find(funcPattern) >= 0:
      inFunction = true
      # Count opening braces in the function declaration line
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
      if line.strip().startsWith("//"):
        continue

      # Extract function calls: functionName( or functionName!(  (macros)
      # Note: macros can use both () and [] brackets
      let callPattern = re"([a-zA-Z_][a-zA-Z0-9_]*)\s*[!]?\s*[\(\[]"
      var pos = 0
      var matches: array[1, string]

      while true:
        let found = line[pos..^1].find(callPattern, matches)
        if found < 0:
          break

        let callName = matches[0]
        # Skip Rust keywords and our own function name
        if callName notin ["if", "else", "match", "for", "while", "loop", "break",
                           "continue", "return", "fn", "let", "mut", "const",
                           "static",
                           "struct", "enum", "trait", "impl", "type", "where",
                           "use",
                           "mod", "pub", "crate", "super", "self", "async",
                           "await", "unsafe"] and
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

proc createRustAnalyzer*(): LanguageAnalyzer =
  ## Creates a Rust language analyzer
  result = LanguageAnalyzer(
    name: "Rust",
    extensions: @[".rs"],
    keywords: @["if", "else", "match", "for", "while", "loop", "break",
                "continue", "return", "fn", "let", "mut", "const", "static",
                "struct", "enum", "trait", "impl", "type", "where", "use",
                "mod", "pub", "crate", "super", "self", "async", "await",
                "unsafe"],
    extractFunctions: extractRustFunctions,
    extractCalls: extractRustCalls
  )
