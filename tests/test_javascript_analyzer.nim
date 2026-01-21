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

  test "handles unbalanced braces without hanging":
    # This tests that extractCalls completes even with malformed code
    # (unbalanced braces that would cause the brace-counting loop to never terminate)
    var code = """
function broken() {
    console.log("start");
    obj.method({
        nested: {
            more: {
"""
    # Add many lines with unbalanced braces to simulate malformed file
    for i in 0..1000:
      code.add("    line" & $i & "();\n")

    # No closing braces - brace counter will never reach 0

    let analyzer = createJavaScriptAnalyzer()

    # This should complete (possibly with empty results) rather than hanging
    let calls = analyzer.extractCalls(code, "broken")

    # We don't care about the exact result, just that it completes
    # The function should return whatever it found before hitting the limit
    check true # If we get here, the test passed (didn't hang)

  test "handles template literals with braces":
    let code = """
function render() {
    const template = `Hello ${name} and ${other}`;
    doSomething();
}
"""

    let analyzer = createJavaScriptAnalyzer()
    let calls = analyzer.extractCalls(code, "render")

    # Should find doSomething even with template literal braces
    check calls.len >= 1
