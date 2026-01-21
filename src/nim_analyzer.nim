# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# nim_analyzer.nim - Regex-based function detection and call analysis

import strutils, tables, re, os, parser

type
  FunctionDef* = object
    name*: string
    file*: string
    line*: int

  FunctionCall* = object
    caller*: FunctionDef
    callee*: string
    count*: int

  CallRelation* = object
    function*: FunctionDef
    callers*: seq[FunctionCall]
    callees*: seq[FunctionCall]

proc extractFunctions(content: string, filepath: string): seq[FunctionDef] =
  ## Extracts all function definitions from content
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

proc extractCalls(content: string, funcName: string): seq[tuple[callee: string, count: int]] =
  ## Extracts all function calls made within a specific function
  result = @[]
  var callCounts = initTable[string, int]()

  let lines = content.split('\n')
  let funcPattern = re("^\\s*(?:proc|func|method|template|macro)\\s+" & funcName & "\\b")

  var inFunction = false
  var braceDepth = 0

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
                           "method", "template", "macro", "echo"] and callName != funcName:
          if callCounts.hasKey(callName):
            callCounts[callName] += 1
          else:
            callCounts[callName] = 1

        pos += found + callName.len + 1
        if pos >= line.len:
          break

  for callee, count in callCounts:
    result.add((callee: callee, count: count))

proc findCallers*(files: seq[NimFile], targetFunc: FunctionDef): seq[FunctionCall] =
  ## Finds all functions that call the target function
  result = @[]

  for file in files:
    let funcs = extractFunctions(file.content, file.path)

    for fn in funcs:
      let calls = extractCalls(file.content, fn.name)

      for call in calls:
        if call.callee == targetFunc.name:
          result.add(FunctionCall(
            caller: fn,
            callee: targetFunc.name,
            count: call.count
          ))

proc findCallees*(files: seq[NimFile], targetFunc: FunctionDef): seq[FunctionCall] =
  ## Finds all functions called by the target function
  result = @[]

  for file in files:
    if file.path == targetFunc.file:
      let calls = extractCalls(file.content, targetFunc.name)
      let allFuncs = extractFunctions(file.content, file.path)

      for call in calls:
        # Try to find the called function's definition
        var foundFunc: FunctionDef
        var found = false

        # First check in same file
        for fn in allFuncs:
          if fn.name == call.callee:
            foundFunc = fn
            found = true
            break

        # If not found, check other files
        if not found:
          for otherFile in files:
            let otherFuncs = extractFunctions(otherFile.content, otherFile.path)
            for fn in otherFuncs:
              if fn.name == call.callee:
                foundFunc = fn
                found = true
                break
            if found:
              break

        if found:
          result.add(FunctionCall(
            caller: targetFunc,
            callee: call.callee,
            count: call.count
          ))
        else:
          # Assume it's a stdlib or external function
          result.add(FunctionCall(
            caller: targetFunc,
            callee: call.callee,
            count: call.count
          ))

proc analyzeFunctionCalls*(files: seq[NimFile], targetFile: string,
                          targetFunc: string): FunctionDef =
  ## Finds the target function definition
  for file in files:
    let funcs = extractFunctions(file.content, file.path)
    for fn in funcs:
      if fn.name == targetFunc and (file.path.endsWith(targetFile) or
                                    extractFilename(file.path) == targetFile):
        return fn

  raise newException(ValueError,
    "Function '" & targetFunc & "' not found in file '" & targetFile & "'")
