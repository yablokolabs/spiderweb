# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# spiderweb.nim - CLI entrypoint for spiderweb analyzer

import os, strutils, options
import parser, analyzer, tree_renderer, language_analyzer, language_registry, language_detector
import analyzers/nim_analyzer, analyzers/python_analyzer,
    analyzers/javascript_analyzer
import analyzers/rust_analyzer, analyzers/cpp_analyzer

type
  ShowMode = enum
    Callers = "callers"
    Callees = "callees"
    Both = "both"

proc initializeLanguages() =
  ## Register all supported language analyzers
  registerLanguage(createNimAnalyzer())
  registerLanguage(createPythonAnalyzer())
  registerLanguage(createJavaScriptAnalyzer())
  registerLanguage(createRustAnalyzer())
  registerLanguage(createCppAnalyzer())

proc parseInput(input: string): tuple[file: string, function: string] =
  ## Parses "file:function" input format
  let parts = input.split(':')
  if parts.len != 2:
    raise newException(ValueError,
      "Invalid input format. Expected 'file:function', got: " & input)

  result.file = parts[0]
  result.function = parts[1]

proc spiderweb(target: string, show: string = "both",
    language: string = "auto") =
  ## Universal Code Debugger CLI - Shows function call relationships
  ##
  ## Usage:
  ##   spiderweb file:function --show=callers|callees|both --language=auto|python|javascript|nim|rust|cpp
  ##
  ## Examples:
  ##   spiderweb test.py:greet --show=callers
  ##   spiderweb src/main.js:processData --show=callees
  ##   spiderweb app.nim:init --show=both
  ##   spiderweb main.rs:main --language=rust

  try:
    # Initialize language registry
    initializeLanguages()

    # Parse input
    let (targetFile, targetFunc) = parseInput(target)

    # Parse show mode
    let mode = case show.toLowerAscii()
      of "callers": Callers
      of "callees": Callees
      of "both": Both
      else:
        raise newException(ValueError,
          "Invalid show mode. Expected 'callers', 'callees', or 'both', got: " & show)

    # Detect or get language analyzer
    var langAnalyzer: LanguageAnalyzer
    if language.toLowerAscii() == "auto":
      # Auto-detect from target file
      let detectedLang = detectLanguageByPath(targetFile)
      if detectedLang.isNone:
        echo "Error: Could not detect language for file: " & targetFile
        echo "Please specify language explicitly with --language"
        echo "Supported languages: " & getSupportedLanguages().join(", ")
        quit(1)
      langAnalyzer = detectedLang.get()
    else:
      # Use specified language
      let langOpt = getLanguageByName(language)
      if langOpt.isNone:
        echo "Error: Unknown language: " & language
        echo "Supported languages: " & getSupportedLanguages().join(", ")
        quit(1)
      langAnalyzer = langOpt.get()

    echo "Analyzing " & langAnalyzer.name & " code..."

    # Walk and collect all files with appropriate extensions
    let currentDir = getCurrentDir()
    let allFiles = walkCodeFiles(currentDir, langAnalyzer.extensions)

    if allFiles.len == 0:
      echo "No " & langAnalyzer.name & " files found in current directory"
      echo "Looking for extensions: " & langAnalyzer.extensions.join(", ")
      quit(1)

    echo "Found " & $allFiles.len & " " & langAnalyzer.name & " file(s)"

    # Find target function
    let funcDef = analyzeFunctionCalls(allFiles, targetFile, targetFunc, langAnalyzer)

    # Analyze relationships
    let callers = if mode in {Callers, Both}: findCallers(allFiles, funcDef,
        langAnalyzer) else: @[]
    let callees = if mode in {Callees, Both}: findCallees(allFiles, funcDef,
        langAnalyzer) else: @[]

    # Render output
    case mode
    of Callers:
      echo renderCallers(funcDef, callers)
    of Callees:
      echo renderCallees(funcDef, callees)
    of Both:
      echo renderBoth(funcDef, callers, callees)

    # Always output JSON
    echo ""
    echo renderJson(funcDef, callers, callees)

  except ValueError as e:
    echo "Error: " & e.msg
    quit(1)
  except IOError as e:
    echo "Error: " & e.msg
    quit(1)
  except Exception as e:
    echo "Unexpected error: " & e.msg
    quit(1)

proc spiderwebCli(args: seq[string], show: string = "both",
    language: string = "auto") =
  ## CLI wrapper that accepts positional arguments
  if args.len == 0:
    echo "Error: Missing target argument"
    echo "Usage: spiderweb file:function --show=callers|callees|both --language=auto|python|javascript|nim|rust|cpp"
    echo ""
    echo "Supported languages:"
    initializeLanguages()
    for lang in getSupportedLanguages():
      echo "  - " & lang
    quit(1)

  spiderweb(args[0], show, language)

when isMainModule:
  import cligen
  dispatch(spiderwebCli,
           cmdName = "spiderweb",
           help = {
             "args": "Target in format 'file:function'",
             "show": "What to show: callers, callees, or both (default: both)",
             "language": "Language to analyze (default: auto-detect from file extension)"
    },
    short = {"show": 's', "language": 'l'})
