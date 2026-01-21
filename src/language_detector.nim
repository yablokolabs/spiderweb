# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# language_detector.nim - Language detection by file extension and shebang

import os, strutils, options, re
import language_analyzer, language_registry

proc parseShebang*(line: string): Option[string] =
  ## Parses a shebang line to extract the interpreter name
  ## Examples:
  ##   #!/usr/bin/python3 -> "python"
  ##   #!/usr/bin/env node -> "node"
  ##   #!/bin/bash -> "bash"

  if not line.startsWith("#!"):
    return none(string)

  # Extract the interpreter
  let parts = line.split('/')
  if parts.len > 0:
    let lastPart = parts[^1].strip()

    # Handle "env node" pattern
    if "env" in line:
      let envParts = lastPart.split(' ')
      if envParts.len > 0:
        let interpreter = envParts[^1].strip()
        return some(interpreter)

    # Handle direct paths like /usr/bin/python3
    let interpreter = lastPart.split()[0]  # Remove any arguments

    # Normalize python versions to just "python"
    if interpreter.startsWith("python"):
      return some("python")

    return some(interpreter)

  return none(string)

proc detectLanguageByPath*(filepath: string): Option[LanguageAnalyzer] =
  ## Detects the language of a file by its path (extension)
  let ext = filepath.splitFile().ext
  if ext.len > 0:
    return getLanguageByExtension(ext)
  return none(LanguageAnalyzer)
