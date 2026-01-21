# 🕸️ Spiderweb v0.1

Universal Code Debugger CLI - Multi-language static analysis tool that visualizes function call relationships.

**Developer:** Yabloko Labs Ltd (London, UK)
**License:** MIT

## 🎯 Overview

Spiderweb is a lightweight, regex-based static analysis tool that instantly shows:
- **Callers**: Which functions call a target function
- **Callees**: Which functions are called by a target function
- **Both**: Complete call relationship tree

**Supported Languages:**
- 🐍 Python (.py, .pyi)
- 📜 JavaScript/TypeScript (.js, .jsx, .ts, .tsx, .mjs, .cjs)
- 👑 Nim (.nim, .nims, .nimble)
- 🦀 Rust (.rs)
- ⚙️ C/C++ (.c, .cpp, .cc, .cxx, .h, .hpp, .hxx)

Output formats:
- Human-readable ASCII tree
- Machine-readable JSON

## 📦 Installation

### Via Snap (Recommended)

```bash
sudo snap install spiderweb
```

### From Source

```bash
# Clone repository
git clone https://github.com/yablokolabs/spiderweb.git
cd spiderweb

# Install dependencies
nimble install

# Build release binary
nim c -d:release --opt:speed src/spiderweb.nim

# Run
./spiderweb --help
```

### Build Snap Package

```bash
snapcraft
sudo snap install spiderweb_0.1_amd64.snap --dangerous
```

## 🚀 Usage

### Basic Syntax

```bash
spiderweb file:function --show=MODE --language=LANG
```

**Parameters:**
- `--show` or `-s`: Display mode (`callers`, `callees`, or `both` - default: `both`)
- `--language` or `-l`: Language to analyze (default: `auto` - auto-detects from file extension)

**Supported Languages:** `Python`, `JavaScript`, `Nim`, `Rust`, `C/C++`

### Examples

#### Python - Show Callers

```bash
spiderweb test.py:greet --show=callers
```

Output:
```
Analyzing Python code...
Found 1 Python file(s)
greet (test.py:6) [1 callers]
└── test.py:main (2 calls)

{"function":{"name":"greet","file":"/path/to/test.py","line":6},"callers":[...]}
```

#### JavaScript - Show Callees

```bash
spiderweb src/app.js:processData --show=callees
```

Output:
```
Analyzing JavaScript code...
Found 12 JavaScript file(s)
processData (app.js:15) calls:
├── validateInput (2 calls)
├── transformData (1 call)
└── saveToFile (1 call)

{"function":{"name":"processData","file":"src/app.js","line":15},"callees":[...]}
```

#### Rust - Show Both

```bash
spiderweb main.rs:main --show=both
```

Output:
```
Analyzing Rust code...
Found 5 Rust file(s)
=== CALLERS ===
main (main.rs:10) [0 callers]
  (no callers found)

=== CALLEES ===
main (main.rs:10) calls:
├── greet (2 calls)
└── process_data (1 call)

{"function":{"name":"main","file":"main.rs","line":10},"callers":[],"callees":[...]}
```

#### Nim - Original Use Case

```bash
spiderweb test.nim:greet --show=callers
```

Output:
```
Analyzing Nim code...
Found 2 Nim file(s)
greet (test.nim:6) [1 callers]
└── test.nim:main (2 calls)

{"function":{"name":"greet","file":"test.nim","line":6},"callers":[...]}
```

## 🧪 Testing

Create a test file:

```nim
# test.nim
proc greet(name: string) =
  echo "Hi ", name

proc main() =
  greet("world")
  greet("nim")
```

Run analysis:

```bash
spiderweb test.nim:greet --show=callers
```

Expected output:
```
greet (test.nim:2) [1 callers]
└── test.nim:main (2 calls)
```

## 🏗️ Architecture

**Pure Nim implementation using only:**
- Standard library (`os`, `strutils`, `regex`, `tables`, `sequtils`, `json`)
- `cligen` for CLI argument parsing

**Components:**
- `parser.nim` - Recursive .nim file walker
- `nim_analyzer.nim` - Regex-based function detection and call analysis
- `tree_renderer.nim` - ASCII tree and JSON output formatting
- `spiderweb.nim` - CLI entrypoint

**Static Analysis Approach:**
- No AST parsing
- No runtime execution
- Pure regex pattern matching
- Fast and lightweight (binary < 5MB)

## 🎨 Output Format

### ASCII Tree

Uses box-drawing characters for visual hierarchy:
- `├──` for middle items
- `└──` for last item
- Indentation for nested relationships

### JSON Schema

```json
{
  "function": {
    "name": "functionName",
    "file": "/path/to/file.nim",
    "line": 42
  },
  "callers": [
    {
      "caller": "callerName",
      "file": "/path/to/caller.nim",
      "line": 10,
      "count": 2
    }
  ],
  "callees": [
    {
      "callee": "calleeName",
      "count": 1
    }
  ]
}
```

## 🔧 Build Commands

```bash
# Install dependencies
nimble install

# Build debug version
nim c src/spiderweb.nim

# Build release version (optimized)
nim c -d:release --opt:speed src/spiderweb.nim

# Build static binary
nim c -d:release --opt:speed --passL:-static src/spiderweb.nim

# Build snap package
snapcraft

# Run tests
nim c -r test.nim
./spiderweb test.nim:greet --show=callers
```

## 📏 Constraints

- Pure Nim implementation
- Standard library + cligen only
- Static analysis (no AST, no execution)
- Single binary output
- Cross-platform compatible
- Binary size < 5MB

## 🤝 Contributing

Contributions welcome! Please ensure:
- MIT license headers on all files
- No external dependencies beyond stdlib + cligen
- Production-grade error handling
- Deterministic output
- Tests pass

## 📄 License

MIT License

Copyright (c) 2026 Yabloko Labs Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 🔗 Links

- **GitHub**: https://github.com/yablokolabs/spiderweb
- **Issues**: https://github.com/yablokolabs/spiderweb/issues
- **Yabloko Labs**: https://yablokolabs.com

## ☕ Support

If you find Spiderweb useful, consider supporting its development:

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/yablokolabs)

<div align="center">
  <img src="bmc_qr.png" alt="QR Code for Buy Me A Coffee" width="200">
</div>

**Sponsor Link**: https://buymeacoffee.com/yablokolabs

---

Made with ❤️ by Yabloko Labs Ltd, London, UK
