# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_language_registry.nim - Tests for language registry

import unittest, options
import ../src/language_analyzer
import ../src/language_registry

suite "Language Registry":
  test "can register and retrieve language by name":
    # Create a mock analyzer
    let mockAnalyzer = LanguageAnalyzer(
      name: "TestLang",
      extensions: @[".test"],
      keywords: @["if", "else"]
    )

    # Register it
    registerLanguage(mockAnalyzer)

    # Retrieve it by name
    let retrieved = getLanguageByName("TestLang")

    check retrieved.isSome()
    check retrieved.get().name == "TestLang"
    check retrieved.get().extensions == @[".test"]

  test "returns None for unknown language":
    let result = getLanguageByName("UnknownLanguage")
    check result.isNone()

  test "can retrieve language by extension":
    let mockAnalyzer = LanguageAnalyzer(
      name: "TestLang2",
      extensions: @[".tst", ".test2"],
      keywords: @[]
    )

    registerLanguage(mockAnalyzer)

    # Should find by any of its extensions
    let byTst = getLanguageByExtension(".tst")
    let byTest2 = getLanguageByExtension(".test2")

    check byTst.isSome
    check byTest2.isSome
    check byTst.get().name == "TestLang2"
    check byTest2.get().name == "TestLang2"

  test "returns None for unknown extension":
    let result = getLanguageByExtension(".unknown")
    check result.isNone

  test "lists all supported languages":
    # Clear registry first to get clean state
    clearRegistry()

    let lang1 = LanguageAnalyzer(name: "Lang1", extensions: @[".l1"],
        keywords: @[])
    let lang2 = LanguageAnalyzer(name: "Lang2", extensions: @[".l2"],
        keywords: @[])

    registerLanguage(lang1)
    registerLanguage(lang2)

    let languages = getSupportedLanguages()
    check languages.len == 2
    check "Lang1" in languages
    check "Lang2" in languages
