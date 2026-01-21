# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# tree_renderer.nim - ASCII + JSON rendering

import json, os
import language_analyzer

proc renderCallers*(targetFunc: FunctionDef, callers: seq[FunctionCall]): string =
  ## Renders ASCII tree of callers
  result = ""

  let funcLocation = extractFilename(targetFunc.file) & ":" & $targetFunc.line
  result.add(targetFunc.name & " (" & funcLocation & ") [" & $callers.len & " callers]\n")

  if callers.len == 0:
    result.add("  (no callers found)\n")
    return

  for i, call in callers:
    let isLast = i == callers.len - 1
    let prefix = if isLast: "└── " else: "├── "
    let callerFile = extractFilename(call.caller.file)
    let location = callerFile & ":" & call.caller.name
    let countStr = if call.count > 1: " (" & $call.count & " calls)" else: " (1 call)"

    result.add(prefix & location & countStr & "\n")

proc renderCallees*(targetFunc: FunctionDef, callees: seq[FunctionCall]): string =
  ## Renders ASCII tree of callees
  result = ""

  let funcLocation = extractFilename(targetFunc.file) & ":" & $targetFunc.line
  result.add(targetFunc.name & " (" & funcLocation & ") calls:\n")

  if callees.len == 0:
    result.add("  (calls nothing)\n")
    return

  for i, call in callees:
    let isLast = i == callees.len - 1
    let prefix = if isLast: "└── " else: "├── "

    result.add(prefix & call.callee)

    # Try to show location if known
    if call.count > 1:
      result.add(" (" & $call.count & " calls)")

    result.add("\n")

proc renderBoth*(targetFunc: FunctionDef, callers: seq[FunctionCall],
                callees: seq[FunctionCall]): string =
  ## Renders both callers and callees
  result = ""
  result.add("=== CALLERS ===\n")
  result.add(renderCallers(targetFunc, callers))
  result.add("\n")
  result.add("=== CALLEES ===\n")
  result.add(renderCallees(targetFunc, callees))

proc toJsonObject*(targetFunc: FunctionDef, callers: seq[FunctionCall],
                   callees: seq[FunctionCall]): JsonNode =
  ## Converts analysis results to JSON
  result = newJObject()

  result["function"] = %* {
    "name": targetFunc.name,
    "file": targetFunc.file,
    "line": targetFunc.line
  }

  var callersArray = newJArray()
  for call in callers:
    callersArray.add(%* {
      "caller": call.caller.name,
      "file": call.caller.file,
      "line": call.caller.line,
      "count": call.count
    })
  result["callers"] = callersArray

  var calleesArray = newJArray()
  for call in callees:
    var calleeObj = %* {
      "callee": call.callee,
      "count": call.count
    }
    calleesArray.add(calleeObj)
  result["callees"] = calleesArray

proc renderJson*(targetFunc: FunctionDef, callers: seq[FunctionCall],
                callees: seq[FunctionCall]): string =
  ## Renders JSON representation
  let jsonObj = toJsonObject(targetFunc, callers, callees)
  result = $jsonObj
