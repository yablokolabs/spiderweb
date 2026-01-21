# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# nim_analyzer.nim - Nim language analyzer (refactored to use new interface)

import strutils, tables, re
import ../language_analyzer

proc extractNimFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts all Nim function definitions from content
  result = @[]
  let lines = content.split('\n')

  # Match: proc functionName, func functionName, method functionName, template functionName, macro functionName
  let funcPattern = re"^\s*(?:proc|func|method|template|macro)\s+(\w+)"

  for i, line in lines:
    var matches: array[1, string]
    if line.find(funcPattern, matches) >= 0:
      result.add(FunctionDef(
        name: matches[0],
        file: filepath,
        line: i + 1
      ))

proc extractNimCalls(content: string, funcName: string): seq[tuple[
    callee: string, count: int]] =
  ## Extracts all function calls made within a specific Nim function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  let funcPattern = re("^\\s*(?:proc|func|method|template|macro)\\s+" &
      funcName & "\\b")

  var inFunction = false

  for line in lines:
    # Check if we're entering the target function
    if line.find(funcPattern) >= 0:
      inFunction = true
      continue

    if inFunction:
      # Simple heuristic: if we see a new proc/func definition, we've left the function
      if line.find(re"^\s*(?:proc|func|method|template|macro)\s+\w+") >= 0 and
         line.find(funcPattern) < 0:
        break

      # Extract function calls: functionName(
      let callPattern = re"(\w+)\s*\("
      var pos = 0
      var matches: array[1, string]

      while true:
        let found = line[pos..^1].find(callPattern, matches)
        if found < 0:
          break

        let callName = matches[0]
        # Skip keywords and our own function name
        if callName notin ["if", "while", "for", "case", "when", "proc", "func",
                           "method", "template", "macro", "echo"] and
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

proc createNimAnalyzer*(): LanguageAnalyzer =
  ## Creates a Nim language analyzer
  result = LanguageAnalyzer(
    name: "Nim",
    extensions: @[".nim", ".nims", ".nimble"],
    keywords: @["if", "while", "for", "case", "when", "proc", "func",
                "method", "template", "macro", "echo"],
    extractFunctions: extractNimFunctions,
    extractCalls: extractNimCalls
  )
