# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# language_analyzer.nim - Language analyzer interface and shared types

type
  FunctionDef* = object
    name*: string
    file*: string
    line*: int

  FunctionCall* = object
    caller*: FunctionDef
    callee*: string
    count*: int

  ExtractFunctionsProc* = proc(content: string, filepath: string): seq[FunctionDef] {.closure.}
  ExtractCallsProc* = proc(content: string, funcName: string): seq[tuple[callee: string, count: int]] {.closure.}

  LanguageAnalyzer* = object
    name*: string
    extensions*: seq[string]
    keywords*: seq[string]
    extractFunctions*: ExtractFunctionsProc
    extractCalls*: ExtractCallsProc
