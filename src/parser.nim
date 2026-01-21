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


const
  # Directories to exclude from code scanning
  excludedDirs = [
    ".git",         # Git repository data
    "nimcache",     # Nim compilation cache
    "node_modules", # Node.js dependencies
    ".venv",        # Python virtual environments
    "venv",         # Python virtual environments (alternate)
    "parts",        # Snapcraft build staging
    "build",        # Common build output directory
    "dist",         # Distribution/bundle output
    "target",       # Rust/Cargo build output
    "stage",        # Snapcraft staging directory
    "prime",        # Snapcraft prime directory
    "__pycache__",  # Python bytecode cache
    ".cache",       # Various cache directories
    ".nori",        # Nori AI configuration/bundled scripts
    ".claude",      # Claude configuration/bundled scripts
  ]

proc isExcludedDir(path: string): bool =
  ## Checks if a directory should be excluded from scanning
  let dirName = extractFilename(path)
  return dirName in excludedDirs

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
      if not isExcludedDir(path):
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
