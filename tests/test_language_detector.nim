# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_language_detector.nim - Tests for language detection

import unittest, options
import ../src/language_analyzer
import ../src/language_registry
import ../src/language_detector

suite "Language Detector":
  setup:
    clearRegistry()

    # Register some test languages
    let pythonAnalyzer = LanguageAnalyzer(
      name: "Python",
      extensions: @[".py", ".pyi"],
      keywords: @["if", "else"]
    )

    let jsAnalyzer = LanguageAnalyzer(
      name: "JavaScript",
      extensions: @[".js", ".mjs"],
      keywords: @["if", "else"]
    )

    registerLanguage(pythonAnalyzer)
    registerLanguage(jsAnalyzer)

  test "detects language by file extension":
    let pyLang = detectLanguageByPath("test.py")
    check pyLang.isSome
    check pyLang.get().name == "Python"

    let jsLang = detectLanguageByPath("src/main.js")
    check jsLang.isSome
    check jsLang.get().name == "JavaScript"

  test "returns None for unknown extension":
    let result = detectLanguageByPath("test.unknown")
    check result.isNone

  test "parses Python shebang":
    let result = parseShebang("#!/usr/bin/python3")
    check result.isSome
    check result.get() == "python"

  test "parses Node.js shebang":
    let result = parseShebang("#!/usr/bin/env node")
    check result.isSome
    check result.get() == "node"

  test "parses Bash shebang":
    let result = parseShebang("#!/bin/bash")
    check result.isSome
    check result.get() == "bash"

  test "returns None for non-shebang line":
    let result = parseShebang("# This is just a comment")
    check result.isNone

  test "handles paths with multiple dots":
    let result = detectLanguageByPath("my.file.name.py")
    check result.isSome
    check result.get().name == "Python"
