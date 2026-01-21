# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_parser.nim - Tests for file walker/parser

import unittest
import os, strutils
import ../src/parser

suite "Parser - walkCodeFiles":
  test "excludes .git directory":
    # Create temp structure
    let tempDir = getTempDir() / "spiderweb_test_git"
    createDir(tempDir)
    createDir(tempDir / ".git")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / ".git" / "config.nim", "# git config")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes node_modules directory":
    let tempDir = getTempDir() / "spiderweb_test_node"
    createDir(tempDir)
    createDir(tempDir / "node_modules")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "node_modules" / "dep.nim", "# dependency")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes parts directory":
    let tempDir = getTempDir() / "spiderweb_test_parts"
    createDir(tempDir)
    createDir(tempDir / "parts")
    createDir(tempDir / "parts" / "build")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "parts" / "duplicate.nim", "# duplicate")
    writeFile(tempDir / "parts" / "build" / "another.nim", "# another duplicate")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes build directory":
    let tempDir = getTempDir() / "spiderweb_test_build"
    createDir(tempDir)
    createDir(tempDir / "build")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "build" / "output.nim", "# build output")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes dist directory":
    let tempDir = getTempDir() / "spiderweb_test_dist"
    createDir(tempDir)
    createDir(tempDir / "dist")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "dist" / "bundled.nim", "# dist bundle")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes target directory (Rust/Cargo)":
    let tempDir = getTempDir() / "spiderweb_test_target"
    createDir(tempDir)
    createDir(tempDir / "target")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "target" / "debug.nim", "# cargo target")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes __pycache__ directory":
    let tempDir = getTempDir() / "spiderweb_test_pycache"
    createDir(tempDir)
    createDir(tempDir / "__pycache__")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "__pycache__" / "cached.nim", "# pycache")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes stage directory (snapcraft)":
    let tempDir = getTempDir() / "spiderweb_test_stage"
    createDir(tempDir)
    createDir(tempDir / "stage")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "stage" / "staged.nim", "# staged")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes prime directory (snapcraft)":
    let tempDir = getTempDir() / "spiderweb_test_prime"
    createDir(tempDir)
    createDir(tempDir / "prime")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "prime" / "primed.nim", "# primed")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes .nori directory":
    let tempDir = getTempDir() / "spiderweb_test_nori"
    createDir(tempDir)
    createDir(tempDir / ".nori")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / ".nori" / "bundled.nim", "# bundled")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "excludes .claude directory":
    let tempDir = getTempDir() / "spiderweb_test_claude"
    createDir(tempDir)
    createDir(tempDir / ".claude")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / ".claude" / "config.nim", "# config")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 1
    check files[0].path.endsWith("main.nim")

  test "does not exclude directories with similar names":
    # 'rebuilder' should NOT be excluded just because it contains 'build'
    let tempDir = getTempDir() / "spiderweb_test_similar"
    createDir(tempDir)
    createDir(tempDir / "rebuilder")
    writeFile(tempDir / "main.nim", "echo \"hello\"")
    writeFile(tempDir / "rebuilder" / "tool.nim", "# rebuilder tool")

    defer:
      removeDir(tempDir)

    let files = walkCodeFiles(tempDir, @[".nim"])

    check files.len == 2 # Both files should be found
