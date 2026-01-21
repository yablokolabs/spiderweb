# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# analyzer.nim - Language-agnostic analysis functions

import parser, language_analyzer
import os, strutils

proc findCallers*(files: seq[CodeFile], targetFunc: FunctionDef,
                   analyzer: LanguageAnalyzer): seq[FunctionCall] =
  ## Finds all functions that call the target function
  result = @[]

  for file in files:
    let funcs = analyzer.extractFunctions(file.content, file.path)

    for fn in funcs:
      let calls = analyzer.extractCalls(file.content, fn.name)

      for call in calls:
        if call.callee == targetFunc.name:
          result.add(FunctionCall(
            caller: fn,
            callee: targetFunc.name,
            count: call.count
          ))

proc findCallees*(files: seq[CodeFile], targetFunc: FunctionDef,
                   analyzer: LanguageAnalyzer): seq[FunctionCall] =
  ## Finds all functions called by the target function
  result = @[]

  for file in files:
    if file.path == targetFunc.file:
      let calls = analyzer.extractCalls(file.content, targetFunc.name)
      let allFuncs = analyzer.extractFunctions(file.content, file.path)

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
            let otherFuncs = analyzer.extractFunctions(otherFile.content, otherFile.path)
            for fn in otherFuncs:
              if fn.name == call.callee:
                foundFunc = fn
                found = true
                break
            if found:
              break

        # Add the call regardless of whether we found the definition
        result.add(FunctionCall(
          caller: targetFunc,
          callee: call.callee,
          count: call.count
        ))

proc analyzeFunctionCalls*(files: seq[CodeFile], targetFile: string,
                           targetFunc: string, analyzer: LanguageAnalyzer): FunctionDef =
  ## Finds the target function definition
  for file in files:
    let funcs = analyzer.extractFunctions(file.content, file.path)
    for fn in funcs:
      if fn.name == targetFunc and (file.path.endsWith(targetFile) or
                                    extractFilename(file.path) == targetFile):
        return fn

  raise newException(ValueError,
    "Function '" & targetFunc & "' not found in file '" & targetFile & "'")
