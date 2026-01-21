# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd

version       = "0.1.0"
author        = "Yabloko Labs Ltd"
description   = "Universal Code Debugger CLI - Multi-language static analysis tool that visualizes function call relationships (Python, JavaScript, TypeScript, Nim, Rust, C/C++)"
license       = "MIT"
srcDir        = "src"
bin           = @["spiderweb"]

requires "nim >= 1.6.0"
requires "cligen >= 1.5.0"
