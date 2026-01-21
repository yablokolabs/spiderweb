# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_javascript_analyzer.nim - Tests for JavaScript/TypeScript language analyzer

import unittest
import ../src/language_analyzer
import ../src/analyzers/javascript_analyzer

suite "JavaScript Analyzer":
  test "extracts JavaScript function definitions":
    let code = """
function hello() {
    console.log("Hello");
}

const greet = (name) => {
    return `Hi ${name}`;
};

async function fetchData() {
    await something();
}
"""

    let analyzer = createJavaScriptAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.js")

    check functions.len == 3
    check functions[0].name == "hello"
    check functions[1].name == "greet"
    check functions[2].name == "fetchData"

  test "extracts JavaScript function calls":
    let code = """
function process() {
    validateInput();
    transformData();
    saveToFile();
    saveToFile();
}
"""

    let analyzer = createJavaScriptAnalyzer()
    let calls = analyzer.extractCalls(code, "process")

    check calls.len == 3

  test "handles method calls":
    let code = """
function test() {
    obj.method();
    result.transform();
}
"""

    let analyzer = createJavaScriptAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 2

  test "filters JavaScript keywords":
    let code = """
function test() {
    if (true) {
        for (let i = 0; i < 10; i++) {
            while (i > 0) {
                break;
            }
        }
    }
}
"""

    let analyzer = createJavaScriptAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    # Should not find 'if', 'for', 'while' as function calls
    check calls.len == 0
