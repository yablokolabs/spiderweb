# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# language_registry.nim - Language registry for storing and retrieving analyzers

import tables, options
import language_analyzer

var languageRegistry = initTable[string, LanguageAnalyzer]()
var extensionToLanguage = initTable[string, string]()

proc registerLanguage*(analyzer: LanguageAnalyzer) =
  ## Registers a language analyzer in the global registry
  languageRegistry[analyzer.name] = analyzer

  # Map each extension to this language
  for ext in analyzer.extensions:
    extensionToLanguage[ext] = analyzer.name

proc getLanguageByName*(name: string): Option[LanguageAnalyzer] =
  ## Retrieves a language analyzer by its name
  if languageRegistry.hasKey(name):
    return some(languageRegistry[name])
  else:
    return none(LanguageAnalyzer)

proc getLanguageByExtension*(ext: string): Option[LanguageAnalyzer] =
  ## Retrieves a language analyzer by file extension
  if extensionToLanguage.hasKey(ext):
    let langName = extensionToLanguage[ext]
    return getLanguageByName(langName)
  else:
    return none(LanguageAnalyzer)

proc getSupportedLanguages*(): seq[string] =
  ## Returns a list of all registered language names
  result = @[]
  for name in languageRegistry.keys:
    result.add(name)

proc clearRegistry*() =
  ## Clears the language registry (useful for testing)
  languageRegistry.clear()
  extensionToLanguage.clear()
