# MIT License
# Copyright (c) 2026 Yabloko Labs Ltd
#
# test_rust_analyzer.nim - Tests for Rust language analyzer

import unittest
import ../src/language_analyzer
import ../src/analyzers/rust_analyzer

suite "Rust Analyzer":
  test "extracts Rust function definitions":
    let code = """
fn hello() {
    println!("Hello");
}

pub fn greet(name: &str) -> String {
    format!("Hi {}", name)
}

async fn fetch_data() {
    something().await;
}
"""

    let analyzer = createRustAnalyzer()
    let functions = analyzer.extractFunctions(code, "test.rs")

    check functions.len == 3
    check functions[0].name == "hello"
    check functions[1].name == "greet"
    check functions[2].name == "fetch_data"

  test "extracts Rust function calls":
    let code = """
fn process() {
    validate_input();
    transform_data();
    save_to_file();
}
"""

    let analyzer = createRustAnalyzer()
    let calls = analyzer.extractCalls(code, "process")

    check calls.len == 3

  test "handles Rust macros":
    let code = """
fn test() {
    println!("test");
    vec![1, 2, 3];
}
"""

    let analyzer = createRustAnalyzer()
    let calls = analyzer.extractCalls(code, "test")

    check calls.len == 2
