# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# parser.nim - Recursive .nim file walker

import os, strutils

type
  CodeFile* = object
    path*: string
    content*: string

  # Alias for backward compatibility
  NimFile* = CodeFile

proc matchesExtensions(path: string, extensions: seq[string]): bool =
  ## Checks if a file path matches any of the given extensions
  for ext in extensions:
    if path.endsWith(ext):
      return true
  return false

proc isNimFile(path: string): bool =
  path.endsWith(".nim")

proc walkCodeFiles*(rootDir: string, extensions: seq[string]): seq[CodeFile] =
  ## Recursively walks directory and collects all files with given extensions
  result = @[]

  if not dirExists(rootDir):
    return result

  for kind, path in walkDir(rootDir):
    case kind
    of pcFile:
      if matchesExtensions(path, extensions):
        try:
          let content = readFile(path)
          result.add(CodeFile(path: path, content: content))
        except IOError:
          discard
    of pcDir:
      if not path.endsWith("/.git") and not path.endsWith("/nimcache") and
         not path.endsWith("/node_modules") and not path.endsWith("/.venv"):
        result.add(walkCodeFiles(path, extensions))
    else:
      discard

proc walkNimFiles*(rootDir: string): seq[NimFile] =
  ## Recursively walks directory and collects all .nim files
  ## Kept for backward compatibility
  return walkCodeFiles(rootDir, @[".nim"])

proc findFile*(files: seq[CodeFile], filename: string): CodeFile =
  ## Finds a file by name (supports relative paths)
  for file in files:
    if file.path.endsWith(filename) or file.path == filename or
       extractFilename(file.path) == filename:
      return file

  raise newException(IOError, "File not found: " & filename)
