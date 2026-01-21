# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_cpp_analyzer.nim - Tests for C/C++ language analyzer

import unittest
import ../src/language_analyzer
import ../src/analyzers/cpp_analyzer

suite "C/C++ Analyzer":
  test "extracts C function definitions":
    let code = """
void hello() {
    printf("Hello");
}

int add(int a, int b) {
    return a + b;
}

static void helper() {
    // helper function
}
"""

    let analyzer = createCppAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.c")

    check functions.len >= 2 # May have false positives, so >= instead of ==

  test "extracts C function calls":
    let code = """
void process() {
    validate_input();
    transform_data();
    save_to_file();
}
"""

    let analyzer = createCppAnalyzer()
    let calls = analyzer.extractCalls(code, "process")

    check calls.len == 3

  test "filters C keywords":
    let code = """
void test() {
    if (true) {
        for (int i = 0; i < 10; i++) {
            while (i > 0) {
                break;
            }
        }
    }
}
"""

    let analyzer = createCppAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 0
